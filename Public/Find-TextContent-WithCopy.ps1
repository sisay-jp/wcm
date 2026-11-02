# テキストファイル内容検索とファイル複製関数 / Text File Content Search and File Copy Function
function Find-TextContent-WithCopy {
    <#
    .SYNOPSIS
        テキストファイルの内容をキーワードで検索し、一致したファイルを複製する
    .DESCRIPTION
        指定フォルダ内のテキストファイルを再帰的に検索し、キーワードパターン（OR/AND条件）に合致する行を検出します。
        一致したファイルは検索フォルダからの相対パスを保って指定フォルダに複製され、検索結果はCSV形式で出力されます。
        複製先フォルダの中身と検索結果ファイルは実行ごとに作り直します（一致が0件なら空になります）。
    .PARAMETER SearchFolder
        検索対象のルートフォルダパス
    .PARAMETER KeywordFile
        キーワードを**行区切り**で記述したファイルパス（各行が検索パターン）
    .PARAMETER OutputFile
        検索結果を出力するファイルパス
    .PARAMETER DuplicateFolder
        一致したファイルを複製するフォルダパス（実行のたびに中身を全削除します）
    .EXAMPLE
        Find-TextContent-WithCopy -SearchFolder "C:\Data" -KeywordFile "keywords.txt" -OutputFile "search_results.csv" -DuplicateFolder "C:\MatchedFiles"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchFolder,

        [Parameter(Mandatory=$true)]
        [string]$KeywordFile,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile,

        [Parameter(Mandatory=$true)]
        [string]$DuplicateFolder
    )

    $enc = $script:WCMConfig.DefaultEncoding

    # ファイル存在チェック
    if (-not (Test-Path $SearchFolder)) {
        Write-Error "検索フォルダが見つかりません: $SearchFolder"
        return
    }
    if (-not (Test-Path $KeywordFile)) {
        Write-Error "キーワードファイルが見つかりません: $KeywordFile"
        return
    }

    # 複製先は毎回空にするため、検索元などを巻き込む指定は削除前に拒否します
    $searchRoot = (Resolve-Path -LiteralPath $SearchFolder).Path.TrimEnd('\', '/')
    $duplicateRoot = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DuplicateFolder)
    $protectedPaths = @(
        $searchRoot
        (Resolve-Path -LiteralPath $KeywordFile).Path
        $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    )
    $isDriveRoot = [System.IO.Path]::GetPathRoot($duplicateRoot).TrimEnd('\', '/') -eq $duplicateRoot.TrimEnd('\', '/')
    if ($isDriveRoot -or (Test-WCMPathWithin -Path $duplicateRoot -Directory $searchRoot)) {
        Write-Error "複製先フォルダに指定できないパスです（ドライブ直下または検索フォルダ配下）: $DuplicateFolder"
        return
    }
    foreach ($protectedPath in $protectedPaths) {
        if (Test-WCMPathWithin -Path $protectedPath -Directory $duplicateRoot) {
            Write-Error "複製先フォルダは実行時に全削除されるため、次のパスを含めることはできません: $protectedPath"
            return
        }
    }

    # 検索結果を保持するための配列を初期化します。
    $SearchResults = @()

    # 一致したファイルのフルパスを保持するためのHashSetを初期化します。（重複防止のため）
    $MatchedFilesSet = [System.Collections.Generic.HashSet[string]]::new()

    # キーワード一覧（パターン）の読み込み
    $SearchPatterns = @(
        Get-Content $KeywordFile -Encoding $enc |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($SearchPatterns.Count -eq 0) {
        Write-Warning "キーワードファイルに有効な検索パターンが含まれていません。"
        return
    }

    Write-Host "読み込んだ検索パターン数: $($SearchPatterns.Count)"
    Write-Host "以下の検索パターン（OR条件）でファイルを検索します:"
    $PatternDetails = @()
    foreach ($Pattern in $SearchPatterns) {
        if ($Pattern -like '*,*') {
            $KeywordsInPattern = $Pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $PatternDetails += "  - AND検索 ($($KeywordsInPattern.Count)個): $($KeywordsInPattern -join ' & ')"
        } else {
            $PatternDetails += "  - 単一検索: '$Pattern'"
        }
    }
    $PatternDetails -join "`n" | Write-Host
    Write-Host ""

    # フォルダの再帰的な読み込みとパターン検索
    Write-Host "検索を開始します..."

    $fileCount = 0
    $lineCount = 0
    $matchCount = 0

    # 指定したフォルダ以下にある全ての .txt ファイルを再帰的に取得します。
    Get-ChildItem -Path $SearchFolder -Filter "*.txt" -Recurse | ForEach-Object {
        $File = $_
        $fileCount++

        # ファイルの内容を行ごとに読み込みます。
        $Content = Get-Content $File.FullName -Encoding $enc
        $LineNumber = 0

        foreach ($Line in $Content) {
            $LineNumber++
            $lineCount++

            # カンマ区切りの文字列から個々の要素に分割します。前後の空白を削除。
            $Elements = @($Line -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

            # 有効な要素がない場合はスキップ
            if ($Elements.Count -eq 0) { continue }

            # この行で最初に合致したパターンを保持
            $MatchedPattern = $null

            # すべての検索パターン（$SearchPatterns）についてチェックします（OR条件）
            foreach ($Pattern in $SearchPatterns) {
                $Keywords = @($Pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                $PatternMatchResult = $true # このパターンが合致したかどうかのフラグ

                # キーワードが一つでも空になった場合はパターンをスキップ
                if ($Keywords.Count -eq 0) { continue }

                # ----------------------------------------------------------------
                # パターン内のキーワードすべてが$Elementsに含まれるかチェック (AND条件)
                # ----------------------------------------------------------------
                foreach ($Keyword in $Keywords) {
                    $IsKeywordPresent = $false

                    # $Elements のいずれかの要素に $Keyword が含まれているかチェック
                    foreach ($Element in $Elements) {
                        # 完全一致（大文字小文字を区別）
                        if ($Element -ceq $Keyword) {
                            $IsKeywordPresent = $true
                            break
                        }
                    }

                    # パターン内のキーワードが一つでも見つからなかった場合、AND条件は不成立
                    if (-not $IsKeywordPresent) {
                        $PatternMatchResult = $false
                        break
                    }
                }

                # ----------------------------------------------------------------
                # パターンに合致した場合 (OR条件成立)
                # ----------------------------------------------------------------
                if ($PatternMatchResult -eq $true) {
                    # このパターンが合致したため、この行のチェックは終了
                    $MatchedPattern = $Pattern
                    break
                }
            }

            # いずれかのパターンに合致した場合、結果を出力一覧に保持
            if ($MatchedPattern -ne $null) {
                $matchCount++

                # 一致したファイルのフルパスを記録
                [void]$MatchedFilesSet.Add($File.FullName)

                # CSVエスケープ処理（ダブルクォートを二重化）
                $FilePathEscaped = $File.FullName -replace '"', '""'
                $LineEscaped = $Line -replace '"', '""'
                $PatternEscaped = $MatchedPattern -replace '"', '""'

                # 出力フォーマット: MatchedPattern(OR/AND),LineNumber,FilePath,Content
                $SearchResultLine = "`"$PatternEscaped`",$LineNumber,`"$FilePathEscaped`",`"$LineEscaped`""
                $SearchResults += $SearchResultLine
            }
        }
    }

    # 検索結果の出力
    Write-Host ""
    Write-Host "検索が完了しました。"
    Write-Host "  処理ファイル数: $fileCount"
    Write-Host "  処理行数: $lineCount"
    Write-Host "  一致行数: $matchCount"
    Write-Host "  一致ファイル数: $($MatchedFilesSet.Count)"
    Write-Host ""

    if ($SearchResults.Count -gt 0) {
        # ヘッダー行を出力
        $Header = "MatchedPattern(OR/AND),LineNumber,FilePath,Content"
        New-WCMParentDirectory -Path $OutputFile
        $Header | Out-File $OutputFile -Encoding $enc

        # 結果を出力
        $SearchResults | Out-File $OutputFile -Append -Encoding $enc
        Write-Host "検索結果は以下のファイルに出力されました: $OutputFile"
    } else {
        Write-Host "いずれのパターンにも一致する結果は見つかりませんでした。"
        # 前回の検索結果を今回の結果と誤認しないよう削除します
        if (Test-Path -LiteralPath $OutputFile) {
            Remove-Item -LiteralPath $OutputFile -Force
        }
    }

    # 複製先フォルダを空にします（一致が0件でも前回の複製を残しません）
    if (-not (Test-Path -LiteralPath $duplicateRoot)) {
        New-Item -Path $duplicateRoot -ItemType Directory | Out-Null
        Write-Host "複製先フォルダを作成しました: $DuplicateFolder"
    } else {
        Write-Host "複製先フォルダ内の既存ファイルを削除します..."
        Get-ChildItem -LiteralPath $duplicateRoot -Force | Remove-Item -Recurse -Force
    }

    # 一致したファイルの複製
    if ($MatchedFilesSet.Count -gt 0) {
        Write-Host ""
        Write-Host "一致したファイルを複製します..."

        # 記録されたファイルパスをループ処理
        $copyCount = 0
        foreach ($FilePath in $MatchedFilesSet) {
            try {
                # 同名ファイルが衝突しないよう、検索フォルダからの相対パスを保って複製します
                $RelativePath = $FilePath.Substring($searchRoot.Length).TrimStart('\', '/')
                $Destination = Join-Path -Path $duplicateRoot -ChildPath $RelativePath
                $DestinationDir = Split-Path -Path $Destination -Parent
                if (-not (Test-Path -LiteralPath $DestinationDir)) {
                    New-Item -Path $DestinationDir -ItemType Directory -ErrorAction Stop | Out-Null
                }
                Copy-Item -LiteralPath $FilePath -Destination $Destination -Force -ErrorAction Stop
                $copyCount++
            }
            catch {
                Write-Warning "ファイルの複製中にエラーが発生しました: $FilePath"
                Write-Warning "  エラー詳細: $($_.Exception.Message)"
            }
        }
        Write-Host "一致した $copyCount 個のファイルが $DuplicateFolder に複製されました。🎉"
        if ($copyCount -ne $MatchedFilesSet.Count) {
            Write-Error "複製できなかったファイルがあります: $($MatchedFilesSet.Count - $copyCount) 件"
        }
    } else {
        Write-Host "複製対象のファイルはありませんでした。"
    }

    # スクリプト終了
    Write-Host ""
    Write-Host "処理が完了しました。"
}