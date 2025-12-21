# テキストファイル内容検索関数 / Text File Content Search Function
function Find-TextContent {
    <#
    .SYNOPSIS
        テキストファイル内の内容をキーワードで検索する
    .DESCRIPTION
        指定フォルダ内のテキストファイルを再帰的に検索し、キーワードパターン（OR/AND条件）で内容を検索します
    .PARAMETER SearchFolder
        検索対象のルートフォルダパス
    .PARAMETER KeywordFile
        キーワードを**行区切り**で記述したファイルパス（各行が検索パターン）
    .PARAMETER OutputFile
        検索結果を出力するファイルパス
    .EXAMPLE
        Find-TextContent -SearchFolder "C:\Data" -KeywordFile "keywords.txt" -OutputFile "results.csv"
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
    $delimiter = $script:WCMConfig.DefaultDelimiter

    # ファイル存在チェック
    if (-not (Test-Path $SearchFolder)) {
        Write-WCMLog -Level ERROR -Message "検索フォルダが見つかりません: $SearchFolder" -Data @{ Path = $SearchFolder }
        return
    }
    if (-not (Test-Path $KeywordFile)) {
        Write-WCMLog -Level ERROR -Message "キーワードファイルが見つかりません: $KeywordFile" -Data @{ Path = $KeywordFile }
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
        Write-WCMLog -Level WARN -Message 'キーワードファイルに有効な検索パターンが含まれていません。' -Data @{ Path = $KeywordFile }
        return
    }

    Write-WCMLog -Level INFO -Message "読み込んだ検索パターン数: $($SearchPatterns.Count)" -Data @{ KeywordFile = $KeywordFile }
    Write-WCMLog -Level INFO -Message "以下の検索パターン（OR条件）でファイルを検索します" -Data @{ Delimiter = $delimiter }
    $PatternDetails = @()
    foreach ($Pattern in $SearchPatterns) {
        if ($Pattern -like '*,*') {
            $KeywordsInPattern = $Pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $PatternDetails += "  - AND検索: $($KeywordsInPattern -join ' & ')"
        } else {
            $PatternDetails += "  - OR検索: '$Pattern' (単一キーワード)"
        }
    }
    $PatternDetails -join "`n" | Write-Verbose

    # フォルダの再帰的な読み込みとパターン検索
    Write-WCMLog -Level INFO -Message '検索を開始します...' -Data @{ SearchFolder = $SearchFolder }

    # 指定したフォルダ以下にある全ての .txt ファイルを再帰的に取得します。
    Get-ChildItem -Path $SearchFolder -Filter "*.txt" -Recurse | ForEach-Object {
        $File = $_

        # ファイルの内容を行ごとに読み込みます。
        $Content = Get-Content $File.FullName -Encoding $enc
        $LineNumber = 0

        foreach ($Line in $Content) {
            $LineNumber++

            # カンマ区切りの文字列から個々の要素に分割します。前後の空白を削除。
            $Elements = $Line -split [regex]::Escape($delimiter) | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            # この行で最初に合致したパターンを保持
            $MatchedPattern = $null

            # すべての検索パターン（$SearchPatterns）についてチェックします（OR条件）
            foreach ($Pattern in $SearchPatterns) {
                $Keywords = $Pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                $PatternMatchResult = $true # このパターンが合致したかどうかのフラグ

                # キーワードが一つでも空になった場合はパターンをスキップ
                if ($Keywords.Count -eq 0) { continue }

                # パターン内のキーワードすべてが$Elementsに含まれるかチェック (AND条件)
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

                # パターンに合致した場合 (OR条件成立)
                if ($PatternMatchResult -eq $true) {
                    # このパターンが合致したため、この行のチェックは終了
                    $MatchedPattern = $Pattern
                    break
                }
            }

            # いずれかのパターンに合致した場合、結果を出力一覧に保持
            if ($MatchedPattern -ne $null) {
                # 出力用に引用符で囲む処理（CSVエスケープ）
                # ダブルクォートが含まれる場合はエスケープ
                $FilePathEscaped = $File.FullName -replace '"', '""'
                $LineEscaped = $Line -replace '"', '""'
                $PatternEscaped = $MatchedPattern -replace '"', '""'

                # 出力フォーマット: MatchedPattern,LineNumber,FilePath,Content
                $SearchResultLine = "`"$PatternEscaped`",$LineNumber,`"$FilePathEscaped`",`"$LineEscaped`""
                $SearchResults += $SearchResultLine
            }
        }
    }

    # 検索結果の出力
    Write-WCMLog -Level INFO -Message '検索が完了しました。結果を出力します...' -Data @{ OutputFile = $OutputFile; Count = $SearchResults.Count }

    if ($SearchResults.Count -gt 0) {
        # ヘッダー行を出力
        $Header = "MatchedPattern(OR/AND),LineNumber,FilePath,Content"
        $Header | Out-File $OutputFile -Encoding $enc

        # 結果を出力
        $SearchResults | Out-File $OutputFile -Append -Encoding $enc
        Write-Host "検索結果 $($SearchResults.Count) 件を以下のファイルに出力しました: $OutputFile"
    } else {
        Write-Host "いずれのパターンにも一致する結果は見つかりませんでした。"
    }
}