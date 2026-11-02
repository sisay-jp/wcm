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
    $delimiter = $script:WCMConfig.DefaultDelimiter

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

    # キーワード一覧（パターン）の読み込み
    $SearchPatterns = @(Get-WCMSearchPattern -KeywordFile $KeywordFile -Encoding $enc)

    # パターンが無いまま続行すると、前回の複製が後続処理に渡るためエラーにします
    if ($SearchPatterns.Count -eq 0) {
        Write-Error "キーワードファイルに有効な検索パターンが含まれていません: $KeywordFile"
        return
    }

    Write-Host "読み込んだ検索パターン数: $($SearchPatterns.Count)"
    Write-Host "以下の検索パターン（OR条件）でファイルを検索します:"
    Format-WCMSearchPattern -Patterns $SearchPatterns | Write-Host
    Write-Host ""

    # フォルダの再帰的な読み込みとパターン検索
    Write-Host "検索を開始します..."

    $Stats = @{ Files = 0; Lines = 0 }
    $SearchResults = [System.Collections.Generic.List[string]]::new()

    # 一致したファイルのフルパスを保持するためのHashSetを初期化します。（重複防止のため）
    $MatchedFilesSet = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($Result in (Get-WCMLineMatch -SearchFolder $SearchFolder -Patterns $SearchPatterns -Encoding $enc -Delimiter $delimiter -Stats $Stats)) {
        # いずれかのパターンに合致した場合、結果を出力一覧に保持
        if ($null -ne $Result.MatchedPattern) {
            [void]$MatchedFilesSet.Add($Result.File.FullName)

            # 出力フォーマット: MatchedPattern(OR/AND),LineNumber,FilePath,Content
            $SearchResults.Add(((ConvertTo-WCMCsvField $Result.MatchedPattern), $Result.LineNumber, (ConvertTo-WCMCsvField $Result.File.FullName), (ConvertTo-WCMCsvField $Result.Line)) -join ',')
        }
    }

    # 検索結果の出力
    Write-Host ""
    Write-Host "検索が完了しました。"
    Write-Host "  処理ファイル数: $($Stats.Files)"
    Write-Host "  処理行数: $($Stats.Lines)"
    Write-Host "  一致行数: $($SearchResults.Count)"
    Write-Host "  一致ファイル数: $($MatchedFilesSet.Count)"
    Write-Host ""

    Write-WCMSearchResult -OutputFile $OutputFile -Header 'MatchedPattern(OR/AND),LineNumber,FilePath,Content' -Lines $SearchResults -Encoding $enc

    if ($SearchResults.Count -gt 0) {
        Write-Host "検索結果は以下のファイルに出力されました: $OutputFile"
    } else {
        Write-Host "いずれのパターンにも一致する結果は見つかりませんでした。"
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
