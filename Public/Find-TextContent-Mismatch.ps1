# テキストファイル内容不一致検索関数 / Text File Content Mismatch Search Function
function Find-TextContent-Mismatch {
    <#
    .SYNOPSIS
        テキストファイル内の内容をキーワードで検索し、不一致の行を検出する
    .DESCRIPTION
        指定フォルダ内のテキストファイルを再帰的に検索し、キーワードパターン（OR/AND条件）に合致しない行を検出します。
        不一致が0件のときは、既存の検索結果ファイルを削除します。
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

    Write-Host "読み込んだ検索パターン数: $($SearchPatterns.Count)"
    Write-Host "以下の検索パターン（OR条件）で不一致を検索します:"
    Format-WCMSearchPattern -Patterns $SearchPatterns | Write-Host
    Write-Host "----------------------------------------------------------------"
    Write-Host "🌟 いずれのパターンにも合致しない行を出力します。"
    Write-Host ""

    # フォルダの再帰的な読み込みとパターン検索
    Write-Host "検索を開始します..."

    $Stats = @{ Files = 0; Lines = 0 }
    $SearchResults = [System.Collections.Generic.List[string]]::new()
    foreach ($Result in (Get-WCMLineMatch -SearchFolder $SearchFolder -Patterns $SearchPatterns -Encoding $enc -Delimiter $delimiter -Stats $Stats)) {
        # どのパターンにも合致しなかった場合のみ、結果を出力一覧に保持
        if ($null -eq $Result.MatchedPattern) {
            $SearchResults.Add(((ConvertTo-WCMCsvField $Result.File.FullName), $Result.LineNumber, (ConvertTo-WCMCsvField $Result.Line), '"NONE OF PATTERNS MATCHED"') -join ',')
        }
    }

    # 検索結果の出力
    Write-Host ""
    Write-Host "検索が完了しました。"
    Write-Host "  処理ファイル数: $($Stats.Files)"
    Write-Host "  処理行数: $($Stats.Lines)"
    Write-Host "  不一致行数: $($SearchResults.Count)"
    Write-Host ""

    Write-WCMSearchResult -OutputFile $OutputFile -Header 'FilePath,LineNumber,Content,Status' -Lines $SearchResults -Encoding $enc

    if ($SearchResults.Count -gt 0) {
        Write-Host "不一致の結果は以下のファイルに出力されました: $OutputFile"
    } else {
        Write-Host "全ての行が、いずれかのキーワードパターンに合致しました。（不一致行なし）"
    }
}
