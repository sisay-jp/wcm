# テキストファイル処理関数（更新版） / Text File Processing Function (Updated)
function Process-TextFile-Updated {
    <#
    .SYNOPSIS
        テキストファイルを処理して除外と重複削除を行う（更新版）
    .DESCRIPTION
        ファイルAの除外ワードリストに基づいてファイルBを処理し、重複を排除してファイルCに出力します
    .PARAMETER InputFileA
        除外するワードが記載されたファイルのパス（カンマ区切り）
    .PARAMETER InputFileB
        処理対象のテキストファイルのパス
    .PARAMETER OutputFile
        処理結果の出力ファイルパス
    .EXAMPLE
        Process-TextFile-Updated -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputFileA,

        [Parameter(Mandatory=$true)]
        [string]$InputFileB,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile
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

    # ファイルAの内容を読み込み、削除するワードのリストを作成します
    $remove_words = (Get-Content $InputFileA -Raw) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    # カウンタを初期化します
    $word_count = @{}
    foreach ($word in $remove_words) {
        $word_count[$word] = 0
    }

    # ファイルBの内容を1行ずつ読み込み、処理します
    $lines = Get-Content $InputFileB -Encoding $enc
    $filtered_lines = @()
    $unique_lines = New-Object System.Collections.ArrayList

    foreach ($line in $lines) {
        # 各行の内容をカンマで分割し、削除するワードをカウントしながら取り除きます
        $filtered_items = $line -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Where-Object {
            if ($remove_words -contains $_) {
                if ($_ -notmatch '^\<') { $word_count[$_] += 1 }
                return $false
            }
            return $true
        }

        # アイテムをソートし、標準化された形式に変換します
        $sorted_items = $filtered_items | Sort-Object
        $standardized_line = $sorted_items -join ','

        # 重複を排除し、ユニークな行を保存しますが、出力はソート前の形式を維持します
        if (-not $unique_lines.Contains($standardized_line)) {
            [void]$unique_lines.Add($standardized_line)
            $filtered_lines += ($filtered_items -join ',' -replace ',+', ',' -replace '^,|,$','')
        }
    }

    # 重複を排除した結果を出力します
    $filtered_lines

    # 重複を排除した結果をファイルに出力します
    $filtered_lines | Out-File -FilePath $OutputFile -Encoding $enc

    # カウンタを表示します（カウント数の降順、ワード文字列の昇順でソート）
    Write-Host ""
    Write-Host "除外カウント結果:" -ForegroundColor Yellow
    $word_count.GetEnumerator() | Sort-Object -Property @{ Expression = { $_.Value }; Descending = $true }, @{ Expression = { $_.Key }; Descending = $false } | ForEach-Object {
        "$($_.Key): $($_.Value)"
    }

    Write-Host "処理が完了しました。処理後の行数: $($filtered_lines.Count)"
}