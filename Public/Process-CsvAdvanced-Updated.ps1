# 高度なCSV処理関数（更新版） / Advanced CSV Processing Function (Updated)
function Process-CsvAdvanced-Updated {
    <#
    .SYNOPSIS
        高度なCSV処理を実行する（シンプル置換、除外、重複削除）
    .DESCRIPTION
        CSVファイルをシンプルな置換、除外処理、重複削除などの高度な処理を行います
    .PARAMETER InputFile
        入力CSVファイルのパス
    .PARAMETER ReplaceFile
        置換ルール定義ファイルのパス（CSV形式、Old,Newヘッダー、オプション）
    .PARAMETER ExcludeFile
        除外ワード定義ファイルのパス（テキスト、1行1ワード、オプション）
    .PARAMETER OutputFile
        出力ファイルのパス
    .EXAMPLE
        Process-CsvAdvanced-Updated -InputFile "data.csv" -ReplaceFile "rules.csv" -ExcludeFile "exclude.txt" -OutputFile "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputFile,

        [Parameter(Mandatory=$false)]
        [string]$ReplaceFile,

        [Parameter(Mandatory=$false)]
        [string]$ExcludeFile,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )

    $enc = $script:WCMConfig.DefaultEncoding
    $delimiter = $script:WCMConfig.DefaultDelimiter

    # ファイル存在チェック
    if (-not (Test-Path $InputFile)) {
        Write-WCMLog -Level ERROR -Message "入力ファイルが見つかりません: $InputFile" -Data @{ Path = $InputFile }
        return
    }

    # 置換リストをハッシュテーブルに読み込む
    $replaceMap = @{}
    if ($ReplaceFile -and (Test-Path $ReplaceFile)) {
        Import-Csv -Path $ReplaceFile -Header "Old", "New" -Encoding $enc | ForEach-Object {
            $replaceMap[$_.Old.Trim()] = $_.New.Trim()
        }
        Write-WCMLog -Level INFO -Message "置換ルール数: $($replaceMap.Count)" -Data @{ ReplaceFile = $ReplaceFile }
    } elseif ($ReplaceFile) {
        Write-WCMLog -Level WARN -Message "置換ファイルが見つかりません: $ReplaceFile" -Data @{ ReplaceFile = $ReplaceFile }
    }

    # 除外ワードリストを読み込む
    $excludeWords = @()
    if ($ExcludeFile -and (Test-Path $ExcludeFile)) {
        $excludeWords = Get-Content -Path $ExcludeFile -Encoding $enc | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        Write-WCMLog -Level INFO -Message "除外ワード数: $($excludeWords.Count)" -Data @{ ExcludeFile = $ExcludeFile }
    } elseif ($ExcludeFile) {
        Write-WCMLog -Level WARN -Message "除外ファイルが見つかりません: $ExcludeFile" -Data @{ ExcludeFile = $ExcludeFile }
    }

    # 入力ファイルを読み込む
    $inputLines = Get-Content -Path $InputFile -Encoding $enc
    Write-WCMLog -Level INFO -Message "処理対象行数: $($inputLines.Count)" -Data @{ InputFile = $InputFile }

    # メイン処理
    $processedLines = [System.Collections.Generic.List[string]]::new()
    $uniqueCheck = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in $inputLines) {
        # 1. 行をカンマで分割し、前後の空白を除去
        $items = $line -split [regex]::Escape($delimiter) | ForEach-Object { $_.Trim() } | Where-Object { $_ }

        # 2. 単語を置換
        $replacedItems = $items | ForEach-Object {
            if ($replaceMap.ContainsKey($_)) {
                $replaceMap[$_]
            } else {
                $_
            }
        }

        # 3. 単語を除外
        $filteredItems = $replacedItems | Where-Object {
            $_ -notin $excludeWords
        }

        # 4. 行内の重複する単語を削除（最初に出現したものを優先）
        $uniqueFilteredItems = $filteredItems | Select-Object -Unique

        # 項目が残っている場合のみ処理を続行
        if ($uniqueFilteredItems.Count -gt 0) {
            # 5. 重複チェックのためだけに、行内の単語を「ソートした」文字列を生成
            $standardizedLine = ($uniqueFilteredItems | Sort-Object) -join $delimiter

            # 6. 「ソートした文字列」を使って行全体の重複をチェック
            if ($uniqueCheck.Add($standardizedLine)) {
                # 7. 結果リストには「ソートしていない元の順序の」文字列を追加
                $originalOrderLine = $uniqueFilteredItems -join $delimiter
                $processedLines.Add($originalOrderLine)
            }
        }
    }

    # 結果の出力
    $processedLines | Out-File -FilePath $OutputFile -Encoding $enc

    Write-WCMLog -Level INFO -Message "処理が完了しました: $OutputFile" -Data @{ OutputFile = $OutputFile; Lines = $processedLines.Count }
}