# テキストファイル処理関数 / Text File Processing Function
function Process-TextFile {
    <#
    .SYNOPSIS
        テキストファイルを高度な処理で変換する
    .DESCRIPTION
        テキストファイルの除外、重複削除、ファイル分割などの高度な処理を行います
    .PARAMETER InputFileA
        除外する値が記載されたファイルのパス
    .PARAMETER InputFileB
        処理対象のテキストファイルのパス
    .PARAMETER OutputFile
        処理結果の出力ファイルパス（オプション）
    .PARAMETER OutputDir
        分割ファイルの出力ディレクトリ（オプション）
    .PARAMETER ListFile
        ファイルリストの出力ファイルパス（オプション）
    .PARAMETER SortItems
        行内のアイテムをソートするかどうか（オプション、デフォルト: $false）
    .PARAMETER CountExclusions
        除外されたワードのカウントを表示するかどうか（オプション、デフォルト: $false）
    .PARAMETER ExcludePrefix
        カウントから除外するプレフィックス（オプション、デフォルト: '<'）
    .EXAMPLE
        Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt" -OutputDir "modify" -ListFile "file_list.txt"
    .EXAMPLE
        Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -SortItems -CountExclusions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputFileA,

        [Parameter(Mandatory=$true)]
        [string]$InputFileB,

        [Parameter(Mandatory=$false)]
        [string]$OutputFile,

        [Parameter(Mandatory=$false)]
        [string]$OutputDir,

        [Parameter(Mandatory=$false)]
        [string]$ListFile,

        [Parameter(Mandatory=$false)]
        [switch]$SortItems,

        [Parameter(Mandatory=$false)]
        [switch]$CountExclusions,

        [Parameter(Mandatory=$false)]
        [string]$ExcludePrefix = '<'
    )

    $enc = $script:WCMConfig.DefaultEncoding

    # ファイル存在チェック
    if (-not (Test-Path $InputFileA)) {
        Write-Error "Input file A not found: $InputFileA"
        return
    }
    if (-not (Test-Path $InputFileB)) {
        Write-Error "Input file B not found: $InputFileB"
        return
    }

    # テキストAを読み込み、配列に変換
    $textA = Get-Content -Path $InputFileA -Encoding $enc -Raw
    $values = Convert-ToArray -text $textA

    # テキストBを読み込み、行ごとに分割
    $textBRaw = Get-Content -Path $InputFileB -Encoding $enc -Raw
    $textB = $textBRaw -split "`r?`n" | Where-Object { -not [string]::IsNullOrEmpty($_) }

    Write-Host "除外ワード数: $($values.Count)"
    Write-Host "処理対象行数: $($textB.Count)"

    # 除外処理を実行
    $result = Remove-Values -lines $textB -values $values -SortItems:$SortItems -CountExclusions:$CountExclusions -ExcludePrefix $ExcludePrefix
    $modifiedLines = $result.Lines

    # カウント結果を表示
    if ($CountExclusions -and $result.WordCount) {
        Write-Host ""
        Write-Host "除外カウント結果:" -ForegroundColor Yellow
        $result.WordCount.GetEnumerator() | 
            Sort-Object -Property @{ Expression = { $_.Value }; Descending = $true }, @{ Expression = { $_.Key }; Descending = $false } | 
            ForEach-Object {
                "$($_.Key): $($_.Value)"
            }
    }

    # 出力ファイルが指定されている場合
    if ($OutputFile) {
        Set-Content -Path $OutputFile -Value $modifiedLines -Encoding $enc
        Write-Host "テキストBの処理が完了しました。処理後の行数: $($modifiedLines.Count)"
    }

    # 出力ディレクトリが指定されている場合
    if ($OutputDir) {
        Save-LinesToFiles -lines $modifiedLines -outputDir $OutputDir
        Write-Host "ファイルを分割して保存しました。"
    }

    # リストファイルが指定されている場合
    if ($ListFile -and $OutputDir) {
        Create-FileList -directory $OutputDir -outputFilePath $ListFile
        Write-Host "ファイルリストを保存しました。"
    }

    # 結果を返す
    $modifiedLines
}

# ヘルパー関数：テキストを配列に変換
function Convert-ToArray {
    param (
        [string]$text
    )
    # カンマで分割し、各要素をトリム、空要素を除外
    return $text -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
}

# ヘルパー関数：値を除外して重複削除
function Remove-Values {
    param (
        [string[]]$lines,
        [string[]]$values,
        [switch]$SortItems,
        [switch]$CountExclusions,
        [string]$ExcludePrefix = '<'
    )

    # 除外する値をハッシュセットに変換（高速な検索のため）
    $valuesToRemove = [System.Collections.Generic.HashSet[string]]::new(
        $values,
        [System.StringComparer]::Ordinal  # 大文字小文字を区別
    )

    # 除外カウント用のハッシュテーブル
    $wordCount = @{}
    if ($CountExclusions) {
        foreach ($word in $values) {
            $wordCount[$word] = 0
        }
    }

    # 処理後のユニークな行を格納（ソート形式で比較）
    $uniqueResultLines = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )

    # 出力用の行を格納（ソート前の形式を維持）
    $outputLines = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $lines) {
        # 行をカンマで分割、トリム、空要素を除去
        $items = $line -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

        # 各行内の重複を除去（順序維持、大文字小文字区別）
        $uniqueItems = [System.Collections.Generic.List[string]]::new()
        $seenInLine = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )

        foreach ($item in $items) {
            if ($seenInLine.Add($item)) {
                $uniqueItems.Add($item)
            }
        }

        # 除外リストに含まれない要素のみを残す
        $filteredItems = $uniqueItems | Where-Object { 
            if ($valuesToRemove.Contains($_)) {
                if ($CountExclusions -and -not $_.StartsWith($ExcludePrefix)) { 
                    $wordCount[$_] += 1 
                }
                return $false
            }
            return $true
        }

        # 残った要素を処理
        if ($filteredItems.Count -gt 0) {
            # ソートする場合
            if ($SortItems) {
                $sortedItems = $filteredItems | Sort-Object
                $standardizedLine = $sortedItems -join ','
                $outputLine = $filteredItems -join ',' -replace ',+', ',' -replace '^,|,$',''
            } else {
                $standardizedLine = $filteredItems -join ','
                $outputLine = $filteredItems -join ',' -replace ',+', ',' -replace '^,|,$',''
            }

            # 処理後の行の重複を排除して出力（ソート形式で比較）
            if ($uniqueResultLines.Add($standardizedLine)) {
                $outputLines.Add($outputLine)
            }
        }
    }

    # 結果を返す
    [PSCustomObject]@{
        Lines = $outputLines
        WordCount = if ($CountExclusions) { $wordCount } else { $null }
    }
}

# ヘルパー関数：行をファイルに保存
function Save-LinesToFiles {
    param (
        [string[]]$lines,
        [string]$outputDir
    )

    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    $index = 1
    foreach ($line in $lines) {
        $fileName = "{0:D4}.txt" -f $index
        Set-Content -Path (Join-Path -Path $outputDir -ChildPath $fileName) -Value $line -Encoding $enc
        $index++
    }
}

# ヘルパー関数：ファイルリストを作成
function Create-FileList {
    param (
        [string]$directory,
        [string]$outputFilePath
    )
    # 指定されたディレクトリ内のファイルを取得
    $files = Get-ChildItem -Path $directory -Filter '*.txt' | Sort-Object Name

    $fileList = foreach ($file in $files) {
        # ファイル名を必要な形式に整形
        "__my/modify/$($file.BaseName)__"
    }

    # リストを指定されたファイルに保存
    Set-Content -Path $outputFilePath -Value $fileList -Encoding $enc
}