# 高度なCSV処理関数（更新版） / Advanced CSV Processing Function (Updated)
function Process-CsvAdvanced-Updated {
    <#
    .SYNOPSIS
        高度なCSV処理を実行する（条件付き置換、除外、重複削除）
    .DESCRIPTION
        入力（1行=区切り文字で並んだ語）に対して
        1) 条件付き置換（ReplaceFile: "Condition","ReplacePair" 2列CSV / 両方ダブルクオート）
        2) 置換後の展開（new に区切り文字が含まれる場合、要素に分割）
        3) 除外
        4) 行内重複削除（順序維持）
        5) 行全体重複削除（順序非依存：ソート文字列で判定）
        を行います。

        ReplaceFile（ヘッダなし/2列CSV）例:
          "who,i am","who->"
          "who","who->"
          "i am","i am->he is"
          "i am","i am->he is friend"
          "a,b","c->d"
          "e,f","f->g,h,"

    .PARAMETER InputFile
        入力ファイルのパス
    .PARAMETER ReplaceFile
        条件付き置換ルール定義ファイル（CSV 2列: Condition, ReplacePair / ヘッダなし / ダブルクオート）。
        ※ ヘッダ行を含めないでください。ファイルの先頭行はヘッダではなくデータ行として処理されます（ヘッダを記載すると、その行も置換ルールとして読み込まれます）。
    .PARAMETER ExcludeFile
        除外ワード定義ファイル（テキスト: カンマ区切り）
    .PARAMETER OutputFile
        出力ファイルのパス
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceFile,

        [Parameter(Mandatory = $false)]
        [string]$ExcludeFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    $enc       = $script:WCMConfig.DefaultEncoding
    $delimiter = $script:WCMConfig.DefaultDelimiter

    # CaseSensitive を比較ロジックに統一的に反映
    $caseSensitive = [bool]$script:WCMConfig.CaseSensitive

    # -------------------------
    # existence checks
    # -------------------------
    if (-not (Test-Path -LiteralPath $InputFile)) {
        Write-WCMLog -Level ERROR -Message "入力ファイルが見つかりません: $InputFile" -Data @{ Path = $InputFile }
        return
    }

    # -------------------------
    # normalize helper
    # - 比較/重複判定/除外判定に使う文字列はこれで統一
    # - newWord 自体は「意味」を壊さないため、展開後にのみ normalize を通す
    # -------------------------
    $normalize = {
        param([string]$s)
        if ($null -eq $s) { return '' }
        ($s.Trim() -replace '\s+', ' ')
    }

    # -------------------------
    # load replace rules
    # complexReplaceMap:
    #   key: "cond1,cond2"（normalize 済み）
    #   val: hashtable old=>new（old は normalize 済み / new は Trim のみ）
    # -------------------------
    $complexReplaceMap = @{}

    if ($ReplaceFile) {
        if (Test-Path -LiteralPath $ReplaceFile) {
            Import-Csv -Path $ReplaceFile -Header "Condition", "ReplacePair" -Encoding $enc | ForEach-Object {
                $row = $_
                if ($null -eq $row) { return }

                $condRaw = [string]$row.Condition
                $pairRaw = [string]$row.ReplacePair

                if ([string]::IsNullOrWhiteSpace($condRaw)) { return }
                if ([string]::IsNullOrWhiteSpace($pairRaw)) { return }

                # Condition はセル内の "A,B" を分割
                $conditions = $condRaw.Split(',') | ForEach-Object { & $normalize $_ } | Where-Object { $_ }
                if ($conditions.Count -eq 0) { return }

                # ReplacePair は最初の -> でのみ分割（new は空でもOK）
                if ($pairRaw -notlike '*->*') { return }
                $parts = $pairRaw -split '->', 2

                $oldWord = & $normalize $parts[0]
                $newWord = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "" }

                if ([string]::IsNullOrWhiteSpace($oldWord)) { return }

                $key = $conditions -join ','
                if (-not $complexReplaceMap.ContainsKey($key)) {
                    $complexReplaceMap[$key] = @{}
                }
                $complexReplaceMap[$key][$oldWord] = $newWord
            }

            Write-WCMLog -Level INFO -Message "置換ルール条件キー数: $($complexReplaceMap.Count)" -Data @{ ReplaceFile = $ReplaceFile }
        } else {
            Write-WCMLog -Level WARN -Message "置換ファイルが見つかりません: $ReplaceFile" -Data @{ ReplaceFile = $ReplaceFile }
        }
    }

    # -------------------------
    # load exclude words (カンマ区切り)
    # ※ exclude は比較対象なので normalize 済みで保持
    # -------------------------
    $excludeWords = @()
    if ($ExcludeFile) {
        if (Test-Path -LiteralPath $ExcludeFile) {
            $fileContent = Get-Content -Path $ExcludeFile -Encoding $enc -Raw
            $excludeWords = $fileContent -split ',' | ForEach-Object { & $normalize $_ } | Where-Object { $_ }
            Write-WCMLog -Level INFO -Message "除外ワード数: $($excludeWords.Count)" -Data @{ ExcludeFile = $ExcludeFile }
        } else {
            Write-WCMLog -Level WARN -Message "除外ファイルが見つかりません: $ExcludeFile" -Data @{ ExcludeFile = $ExcludeFile }
        }
    }

    # -------------------------
    # read input
    # -------------------------
    $inputLines = Get-Content -Path $InputFile -Encoding $enc
    Write-WCMLog -Level INFO -Message "処理対象行数: $($inputLines.Count)" -Data @{ InputFile = $InputFile }

    # -------------------------
    # main
    # -------------------------
    $processedLines = [System.Collections.Generic.List[string]]::new()
    if ($caseSensitive) {
        $uniqueCheck = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    } else {
        $uniqueCheck = [System.Collections.Generic.HashSet[string]]::new()
    }

    foreach ($line in $inputLines) {
        # 1) split line into items（normalize して保持）
        $currentItems = [System.Collections.Generic.List[string]]::new()
        $line.Split($delimiter) | ForEach-Object {
            $t = & $normalize $_
            if ($t) { $currentItems.Add($t) }
        }

        # 2) condition-based replace
        foreach ($entry in $complexReplaceMap.GetEnumerator()) {
            $conditions = $entry.Key.Split(',') | ForEach-Object { & $normalize $_ } | Where-Object { $_ }
            $replacementPairs = $entry.Value  # hashtable old=>new

            # 条件判定（CaseSensitive に統一）
            $allConditionsMet = $true
            foreach ($c in $conditions) {
                if ($caseSensitive) {
                    if ($currentItems -cnotcontains $c) { $allConditionsMet = $false; break }
                } else {
                    if ($currentItems -notcontains $c) { $allConditionsMet = $false; break }
                }
            }

            if ($allConditionsMet) {
                foreach ($pair in $replacementPairs.GetEnumerator()) {
                    $oldW = $pair.Key
                    $newW = $pair.Value

                    for ($i = 0; $i -lt $currentItems.Count; $i++) {
                        if ($caseSensitive) {
                            if ($currentItems[$i] -ceq $oldW) { $currentItems[$i] = $newW }
                        } else {
                            if ($currentItems[$i] -ieq $oldW) { $currentItems[$i] = $newW }
                        }
                    }
                }
            }
        }

        # 2.5) expand items
        # - newW に delimiter を含む場合は分割
        # - 分割後は normalize して空要素は捨てる（例: "g,h," の末尾空を捨てる）
        $expandedItems = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $currentItems) {
            if ($item -like "*$delimiter*") {
                $item.Split($delimiter) | ForEach-Object {
                    $t = & $normalize $_
                    if ($t) { $expandedItems.Add($t) }
                }
            } else {
                $t = & $normalize $item
                if ($t) { $expandedItems.Add($t) }
            }
        }
        $currentItems = $expandedItems

        # 3) exclude（空白含みも normalize された値で比較）
        $filteredItems = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $currentItems) {
            $shouldExclude = $false
            foreach ($ex in $excludeWords) {
                # CaseSensitive 設定に合わせて比較方法を切り替える
                if ($caseSensitive) {
                    if ($item -ceq $ex) { $shouldExclude = $true; break }
                } else {
                    if ($item -ieq $ex) { $shouldExclude = $true; break }
                }
            }
            if (-not $shouldExclude) { $filteredItems.Add($item) }
        }

        # 4) de-dup within line (keep order)
        $finalItemsInLine = [System.Collections.Generic.List[string]]::new()
        if ($caseSensitive) {
            $seenInLine = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        } else {
            $seenInLine = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }
        foreach ($item in $filteredItems) {
            if ($seenInLine.Add($item)) { $finalItemsInLine.Add($item) }
        }

        # 5-7) de-dup whole line (order-insensitive via sorted string)
        if ($finalItemsInLine.Count -gt 0) {
            $standardizedLine = ($finalItemsInLine | Sort-Object) -join $delimiter
            if ($uniqueCheck.Add($standardizedLine)) {
                $processedLines.Add(($finalItemsInLine -join $delimiter))
            }
        }
    }

    # -------------------------
    # output
    # -------------------------
    $processedLines | Out-File -FilePath $OutputFile -Encoding $enc
    Write-WCMLog -Level INFO -Message "処理が完了しました: $OutputFile" -Data @{ OutputFile = $OutputFile; Lines = $processedLines.Count }
}
