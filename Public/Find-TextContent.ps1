# テキストファイル内容検索関数 / Text File Content Search Function
function Find-TextContent {
    <#
    .SYNOPSIS
        テキストファイル内の内容をキーワードで検索する
    .DESCRIPTION
        指定フォルダ内のテキストファイルを再帰的に検索し、キーワードパターン（OR/AND条件）で内容を検索します。
        一致が0件のときは、既存の検索結果ファイルを削除します。
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
        Write-Error "検索フォルダが見つかりません: $SearchFolder"
        return
    }
    if (-not (Test-Path $KeywordFile)) {
        Write-Error "キーワードファイルが見つかりません: $KeywordFile"
        return
    }

    # キーワード一覧（パターン）の読み込み
    $SearchPatterns = @(Get-WCMSearchPattern -KeywordFile $KeywordFile -Encoding $enc)

    if ($SearchPatterns.Count -eq 0) {
        Write-Error "キーワードファイルに有効な検索パターンが含まれていません: $KeywordFile"
        return
    }

    Write-WCMLog -Level INFO -Message "読み込んだ検索パターン数: $($SearchPatterns.Count)" -Data @{ KeywordFile = $KeywordFile }
    Write-Verbose (Format-WCMSearchPattern -Patterns $SearchPatterns)

    # フォルダの再帰的な読み込みとパターン検索
    Write-WCMLog -Level INFO -Message '検索を開始します...' -Data @{ SearchFolder = $SearchFolder }

    $SearchResults = [System.Collections.Generic.List[string]]::new()
    foreach ($Result in (Get-WCMLineMatch -SearchFolder $SearchFolder -Patterns $SearchPatterns -Encoding $enc -Delimiter $delimiter)) {
        # いずれかのパターンに合致した場合、結果を出力一覧に保持
        if ($null -ne $Result.MatchedPattern) {
            # 出力フォーマット: MatchedPattern,LineNumber,FilePath,Content
            $SearchResults.Add(((ConvertTo-WCMCsvField $Result.MatchedPattern), $Result.LineNumber, (ConvertTo-WCMCsvField $Result.File.FullName), (ConvertTo-WCMCsvField $Result.Line)) -join ',')
        }
    }

    # 検索結果の出力
    Write-WCMLog -Level INFO -Message '検索が完了しました。結果を出力します...' -Data @{ OutputFile = $OutputFile; Count = $SearchResults.Count }
    Write-WCMSearchResult -OutputFile $OutputFile -Header 'MatchedPattern(OR/AND),LineNumber,FilePath,Content' -Lines $SearchResults -Encoding $enc

    if ($SearchResults.Count -gt 0) {
        Write-Host "検索結果 $($SearchResults.Count) 件を以下のファイルに出力しました: $OutputFile"
    } else {
        Write-Host "いずれのパターンにも一致する結果は見つかりませんでした。"
    }
}
