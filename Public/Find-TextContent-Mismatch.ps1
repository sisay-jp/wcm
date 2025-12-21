# テキストファイル内容不一致検索関数 / Text File Content Mismatch Search Function
function Find-TextContent-Mismatch {
    <#
    .SYNOPSIS
        テキストファイル内の内容をキーワードで検索し、不一致の行を検出する
    .DESCRIPTION
        指定フォルダ内のテキストファイルを再帰的に検索し、キーワードパターン（OR/AND条件）に合致しない行を検出します
    .PARAMETER SearchFolder
        検索対象のルートフォルダパス
    .PARAMETER KeywordFile
        キーワードを**行区切り**で記述したファイルパス（各行が検索パターン）
    .PARAMETER OutputFile
        検索結果を出力するファイルパス
    .EXAMPLE
        Find-TextContent-Mismatch -SearchFolder "C:\Data" -KeywordFile "keywords.txt" -OutputFile "mismatches.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchFolder,

        [Parameter(Mandatory=$true)]
        [string]$KeywordFile,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile
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

    # 検索結果を保持するための配列を初期化します。
    $SearchResults = @()

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
    Write-Host "以下の検索パターン（OR条件）で不一致を検索します:"
    $PatternDetails = @()
    foreach ($Pattern in $SearchPatterns) {
        # 判定ロジックをメッセージ表示に利用
        $KeywordsInPattern = @($Pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($KeywordsInPattern.Count -gt 1) {
            $PatternDetails += "  - AND検索 ($($KeywordsInPattern.Count)個): $($KeywordsInPattern -join ' & ')"
        } else {
            $PatternDetails += "  - 単一検索: '$Pattern'"
        }
    }
    $PatternDetails -join "`n" | Write-Host
    Write-Host "----------------------------------------------------------------"
    Write-Host "🌟 いずれのパターンにも合致しない行を出力します。"
    Write-Host ""

    # フォルダの再帰的な読み込みとパターン検索
    Write-Host "検索を開始します..."

    $fileCount = 0
    $lineCount = 0

    Get-ChildItem -Path $SearchFolder -Filter "*.txt" -Recurse | ForEach-Object {
        $File = $_
        $fileCount++

        # ファイルサイズが0バイトの場合はスキップ
        if ($File.Length -eq 0) {
            Write-Warning "スキップしました：ファイルが空です -> $($File.FullName)"
            return
        }

        $Content = Get-Content $File.FullName -Encoding $enc
        $LineNumber = 0

        foreach ($Line in $Content) {
            $LineNumber++
            $lineCount++

            # 行をカンマで分割し、各要素をトリム、空要素を除外
            $Elements = @($Line -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

            # 行から有効な要素が取得できなかった場合はスキップ
            if ($Elements.Count -eq 0) { continue }

            $MatchedPattern = $null

            # すべての検索パターンについてチェック (大元の OR 条件)
            foreach ($Pattern in $SearchPatterns) {
                # パターンをキーワードに分割
                $Keywords = @($Pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

                if ($Keywords.Count -eq 0) { continue }

                # パターン全体が合致したかのフラグ
                $PatternMatchResult = $true

                # ----------------------------------------------------------------
                # すべてのキーワードが$Elementsに含まれているかチェック (AND条件)
                # ----------------------------------------------------------------
                foreach ($Keyword in $Keywords) {
                    $IsKeywordPresent = $false

                    # $Elements のいずれかの要素に $Keyword が含まれているかチェック
                    foreach ($Element in $Elements) {
                        # 完全一致で比較（大文字小文字を区別）
                        if ($Element -ceq $Keyword) {
                            $IsKeywordPresent = $true
                            break
                        }
                    }

                    # キーワードが一つでも見つからなかった場合、AND条件は不成立
                    if (-not $IsKeywordPresent) {
                        $PatternMatchResult = $false
                        break
                    }
                }

                # パターンに合致した場合 (大元の OR 条件成立)
                if ($PatternMatchResult -eq $true) {
                    $MatchedPattern = $Pattern
                    break
                }
            }

            # どのパターンにも合致しなかった場合のみ、結果を出力一覧に保持
            if ($MatchedPattern -eq $null) {
                # CSVエスケープ処理（ダブルクォートを二重化）
                $FilePathEscaped = $File.FullName -replace '"', '""'
                $LineEscaped = $Line -replace '"', '""'

                $SearchResultLine = "`"$FilePathEscaped`",$LineNumber,`"$LineEscaped`",`"NONE OF PATTERNS MATCHED`""
                $SearchResults += $SearchResultLine
            }
        }
    }

    # 検索結果の出力
    Write-Host ""
    Write-Host "検索が完了しました。"
    Write-Host "  処理ファイル数: $fileCount"
    Write-Host "  処理行数: $lineCount"
    Write-Host "  不一致行数: $($SearchResults.Count)"
    Write-Host ""

    if ($SearchResults.Count -gt 0) {
        $Header = "FilePath,LineNumber,Content,Status"
        $Header | Out-File $OutputFile -Encoding $enc

        $SearchResults | Out-File $OutputFile -Append -Encoding $enc
        Write-Host "不一致の結果は以下のファイルに出力されました: $OutputFile"
    } else {
        Write-Host "全ての行が、いずれかのキーワードパターンに合致しました。（不一致行なし）"
    }
}