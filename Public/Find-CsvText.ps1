# テキスト検索関数 (Text Search Function)
function Find-CsvText {
    <#
    .SYNOPSIS
        CSV内のテキストを検索する
    .DESCRIPTION
        CSVファイル内の指定されたテキストを検索し、該当する行を返します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER SearchText
        検索するテキスト
    .PARAMETER Column
        検索対象の列名 (指定しない場合は全列を検索)
    .PARAMETER CaseSensitive
        大文字小文字を区別する
    .EXAMPLE
        Find-CsvText -Path "data.csv" -SearchText "Tokyo"
    .EXAMPLE
        Find-CsvText -Path "data.csv" -SearchText "Tokyo" -Column "City"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$SearchText,

        [Parameter(Mandatory=$false)]
        [string]$Column,

        [Parameter(Mandatory=$false)]
        [switch]$CaseSensitive
    )

    # CaseSensitiveが明示的に指定されていない場合はコンフィグを使用
    if (-not $PSBoundParameters.ContainsKey('CaseSensitive')) {
        $CaseSensitive = $script:WCMConfig.CaseSensitive
    }

    $data = Import-CsvFile -Path $Path

    if ($Column) {
        # 特定の列を検索
        if ($CaseSensitive) {
            $data | Where-Object { $_.$Column -clike "*$SearchText*" }
        }
        else {
            $data | Where-Object { $_.$Column -like "*$SearchText*" }
        }
    }
    else {
        # 全列を検索
        $data | Where-Object {
            $row = $_
            $found = $false
            foreach ($prop in $row.PSObject.Properties) {
                if ($CaseSensitive) {
                    if ($prop.Value -clike "*$SearchText*") {
                        $found = $true
                        break
                    }
                }
                else {
                    if ($prop.Value -like "*$SearchText*") {
                        $found = $true
                        break
                    }
                }
            }
            $found
        }
    }
}