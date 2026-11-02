# WCM テキスト内容検索の共通処理（内部用）

function Get-WCMSearchPattern {
    <#
    .SYNOPSIS
        キーワードファイルを読み込み、検索パターンの一覧を返す（内部用）
    .DESCRIPTION
        各行が1パターンです（行どうしは OR 条件）。
        行内のカンマで区切られたキーワードは AND 条件です。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeywordFile,

        [Parameter(Mandatory = $true)]
        [string]$Encoding
    )

    foreach ($line in (Get-Content -LiteralPath $KeywordFile -Encoding $Encoding)) {
        $pattern = $line.Trim()
        $keywords = @($pattern -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($keywords.Count -gt 0) {
            [PSCustomObject]@{
                Pattern  = $pattern
                Keywords = $keywords
            }
        }
    }
}

function Format-WCMSearchPattern {
    <#
    .SYNOPSIS
        検索パターンの一覧を表示用の文字列にする（内部用）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Patterns
    )

    $details = foreach ($p in $Patterns) {
        if ($p.Keywords.Count -gt 1) {
            "  - AND検索 ($($p.Keywords.Count)個): $($p.Keywords -join ' & ')"
        } else {
            "  - 単一検索: '$($p.Pattern)'"
        }
    }
    $details -join "`n"
}

function Get-WCMLineMatch {
    <#
    .SYNOPSIS
        フォルダ内の *.txt を再帰的に読み、各行に合致した検索パターンを返す（内部用）
    .DESCRIPTION
        有効な要素がある行ごとに File / LineNumber / Line / MatchedPattern を返します。
        どのパターンにも合致しない行の MatchedPattern は $null です。
        キーワードは要素との完全一致（大文字小文字を区別）で比較します。
    .PARAMETER Stats
        処理したファイル数（Files）と行数（Lines）を加算するハッシュテーブル
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchFolder,

        [Parameter(Mandatory = $true)]
        [object[]]$Patterns,

        [Parameter(Mandatory = $true)]
        [string]$Encoding,

        [Parameter(Mandatory = $true)]
        [string]$Delimiter,

        [hashtable]$Stats = @{}
    )

    $delimiterRegex = [regex]::Escape($Delimiter)

    foreach ($file in (Get-ChildItem -LiteralPath $SearchFolder -Filter '*.txt' -Recurse -File)) {
        $Stats.Files = [int]$Stats.Files + 1

        $lineNumber = 0
        foreach ($line in (Get-Content -LiteralPath $file.FullName -Encoding $Encoding)) {
            $lineNumber++
            $Stats.Lines = [int]$Stats.Lines + 1

            $elements = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
            foreach ($element in ($line -split $delimiterRegex)) {
                if (-not [string]::IsNullOrWhiteSpace($element)) {
                    [void]$elements.Add($element.Trim())
                }
            }

            # 有効な要素がない行は検索対象にしない
            if ($elements.Count -eq 0) { continue }

            # 最初に合致したパターンを採用（OR条件）
            $matchedPattern = $null
            foreach ($p in $Patterns) {
                # パターン内のキーワードがすべて含まれていれば合致（AND条件）
                $allPresent = $true
                foreach ($keyword in $p.Keywords) {
                    if (-not $elements.Contains($keyword)) {
                        $allPresent = $false
                        break
                    }
                }
                if ($allPresent) {
                    $matchedPattern = $p.Pattern
                    break
                }
            }

            [PSCustomObject]@{
                File           = $file
                LineNumber     = $lineNumber
                Line           = $line
                MatchedPattern = $matchedPattern
            }
        }
    }
}

function ConvertTo-WCMCsvField {
    <#
    .SYNOPSIS
        値をダブルクォートで囲んだ CSV フィールドにする（内部用）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    '"' + ($Value -replace '"', '""') + '"'
}

function Write-WCMSearchResult {
    <#
    .SYNOPSIS
        検索結果を CSV に出力する（内部用）
    .DESCRIPTION
        結果が0件のときは、前回の結果を今回の結果と誤認しないよう既存のファイルを削除します。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [string]$Header,

        [AllowEmptyCollection()]
        [string[]]$Lines = @(),

        [Parameter(Mandatory = $true)]
        [string]$Encoding
    )

    if ($Lines.Count -eq 0) {
        if (Test-Path -LiteralPath $OutputFile) {
            Remove-Item -LiteralPath $OutputFile -Force
        }
        return
    }

    New-WCMParentDirectory -Path $OutputFile
    @($Header) + $Lines | Out-File -FilePath $OutputFile -Encoding $Encoding
}
