# 行フィルタ関数 (Filter Rows Function)
function Select-CsvRows {
    <#
    .SYNOPSIS
        CSVファイルの行をフィルタする
    .DESCRIPTION
        指定された条件でCSVファイルの行をフィルタします
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER Column
        フィルタ対象の列名
    .PARAMETER Value
        比較する値
    .PARAMETER Operator
        比較演算子 (Equals, NotEquals, GreaterThan, LessThan, Contains, NotContains)
    .PARAMETER OutputPath
        出力先のパス (指定しない場合はコンソールに出力)
    .EXAMPLE
        Select-CsvRows -Path "data.csv" -Column "Age" -Value "30" -Operator "GreaterThan" -OutputPath "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Column,

        [Parameter(Mandatory=$true)]
        [string]$Value,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Equals", "NotEquals", "GreaterThan", "LessThan", "Contains", "NotContains")]
        [string]$Operator = "Equals",

        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )

    $data = Import-CsvFile -Path $Path

    $filteredData = switch ($Operator) {
        "Equals" { $data | Where-Object { $_.$Column -eq $Value } }
        "NotEquals" { $data | Where-Object { $_.$Column -ne $Value } }
        "GreaterThan" { $data | Where-Object { [int]$_.$Column -gt [int]$Value } }
        "LessThan" { $data | Where-Object { [int]$_.$Column -lt [int]$Value } }
        "Contains" { $data | Where-Object { $_.$Column -like "*$Value*" } }
        "NotContains" { $data | Where-Object { $_.$Column -notlike "*$Value*" } }
    }

    if ($OutputPath) {
        $filteredData | Export-CsvFile -Path $OutputPath
    } else {
        $filteredData
    }
}