# 高度なCSV処理関数 / Advanced CSV Processing Function
function Process-CsvAdvanced {
    <#
    .SYNOPSIS
        高度なCSV処理を実行する（条件付き置換、除外、重複削除）
    .DESCRIPTION
        CSVファイルを条件付き置換、除外処理、重複削除などの高度な処理を行います
    .PARAMETER InputFile
        入力CSVファイルのパス
    .PARAMETER ReplaceFile
        置換ルール定義ファイルのパス（オプション）
    .PARAMETER ExcludeFile
        除外ワード定義ファイルのパス（オプション）
    .PARAMETER OutputFile
        出力ファイルのパス（指定しない場合はコンソールに出力）
    .EXAMPLE
        Process-CsvAdvanced -InputFile "data.csv" -ReplaceFile "rules.csv" -ExcludeFile "exclude.txt" -OutputFile "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputFile,

        [Parameter(Mandatory=$false)]
        [string]$ReplaceFile,

        [Parameter(Mandatory=$false)]
        [string]$ExcludeFile,

        [Parameter(Mandatory=$false)]
        [string]$OutputFile
    )

    $enc = $script:WCMConfig.DefaultEncoding
    $delimiter = $script:WCMConfig.DefaultDelimiter

    # ファイル存在チェック
    if (-not (Test-Path $InputFile)) {
        Write-WCMLog -Level ERROR -Message "Input file not found: $InputFile" -Data @{ Path = $InputFile }
        return
    }

    # 置換マップの読み込み
    $complexReplaceMap = @{}
    if ($ReplaceFile -and (Test-Path $ReplaceFile)) {
        Import-Csv -Path $ReplaceFile -Header "Condition", "ReplacePair" | ForEach-Object {
            $row = $_
            if ($row -ne $null -and -not [string]::IsNullOrEmpty($row.Condition) -and -not [string]::IsNullOrEmpty($row.ReplacePair)) {
                $conditions = $row.Condition.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }

                # 置換後のカンマを守るため、最初の "->" で分割
                $replacementPairs = @{}
                $pair = $row.ReplacePair.Trim()
                if ($pair -like '*->*') {
                    $parts = $pair -split '->', 2
                    $oldWord = $parts[0].Trim()
                    $newWord = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "" }
                    if ($oldWord) {
                        $replacementPairs[$oldWord] = $newWord
                    }
                }

                if ($conditions.Count -gt 0 -and $replacementPairs.Count -gt 0) {
                    $complexReplaceMap[$conditions -join ','] = $replacementPairs
                }
            }
        }
        Write-Verbose "Loaded $($complexReplaceMap.Count) replacement rules"
    }

    # 除外ワードリストの読み込み
    $excludeWords = @()
    if ($ExcludeFile -and (Test-Path $ExcludeFile)) {
        $fileContent = Get-Content -Path $ExcludeFile -Raw -Encoding $enc
        $excludeWords = $fileContent -split [regex]::Escape($delimiter) | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        Write-Verbose "Loaded $($excludeWords.Count) exclusion words"
    } elseif ($ExcludeFile) {
        Write-Warning "Exclude file not found: $ExcludeFile"
    }

    # 入力ファイルの読み込み
    $inputLines = Get-Content -Path $InputFile -Encoding $enc

    # メイン処理
    $processedLines = [System.Collections.Generic.List[string]]::new()
    $uniqueCheck = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in $inputLines) {
        # 1. 行をカンマで分割
        $currentItems = [System.Collections.Generic.List[string]]::new()
        $line.Split($delimiter) | ForEach-Object {
            $t = $_.Trim(); if ($t) { $currentItems.Add($t) }
        }

        # 2. 単語を条件付きで置換
        $complexReplaceMap.GetEnumerator() | ForEach-Object {
            $conditions = $_.Key.Split(',')
            $replacementPairs = $_.Value

            $allConditionsMet = $true
            foreach ($c in $conditions) {
                if ($currentItems -notcontains $c.Trim()) { $allConditionsMet = $false; break }
            }

            if ($allConditionsMet) {
                $replacementPairs.GetEnumerator() | ForEach-Object {
                    $oldW = $_.Key
                    $newW = $_.Value
                    for ($i = 0; $i -lt $currentItems.Count; $i++) {
                        if ($currentItems[$i] -ceq $oldW) {
                            $currentItems[$i] = $newW
                        }
                    }
                }
            }
        }

        # 2.5 置換後の展開処理 (カンマ区切りを個別の要素にバラす)
        $expandedItems = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $currentItems) {
            if ($item -like "*$delimiter*") {
                $item.Split($delimiter) | ForEach-Object {
                    $t = $_.Trim(); if ($t) { $expandedItems.Add($t) }
                }
            } elseif (-not [string]::IsNullOrEmpty($item)) {
                $expandedItems.Add($item)
            }
        }
        $currentItems = $expandedItems

        # 3. 単語を除外
        $filteredItems = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $currentItems) {
            $shouldExclude = $false
            foreach ($ex in $excludeWords) {
                $normItem = $item -replace '\s+', ' '
                $normEx = $ex -replace '\s+', ' '
                if ($normItem -eq $normEx) { $shouldExclude = $true; break }
            }
            if (-not $shouldExclude) { $filteredItems.Add($item) }
        }

        # 4. 行内の重複削除（元の順序を保持）
        $finalItemsInLine = [System.Collections.Generic.List[string]]::new()
        $seenInLine = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($item in $filteredItems) {
            if ($seenInLine.Add($item)) { $finalItemsInLine.Add($item) }
        }

        # 5-7. 行全体の重複チェックと保存
        if ($finalItemsInLine.Count -gt 0) {
            $standardizedLine = ($finalItemsInLine | Sort-Object) -join $delimiter
            if ($uniqueCheck.Add($standardizedLine)) {
                $processedLines.Add(($finalItemsInLine -join $delimiter))
            }
        }
    }

    # 結果の出力
    if ($OutputFile) {
        $processedLines | Out-File -FilePath $OutputFile -Encoding $enc
        Write-WCMLog -Level INFO -Message "Processing completed. Results saved to $OutputFile." -Data @{ OutputFile = $OutputFile; Lines = $processedLines.Count }
    } else {
        # コンソールに出力
        $processedLines
    }
}