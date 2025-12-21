# 列追加関数 (Add Column Function)
function Add-CsvColumn {
    <#
    .SYNOPSIS
        CSVファイルに列を追加する
    .DESCRIPTION
        CSVファイルに新しい列を追加します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER ColumnName
        追加する列名
    .PARAMETER DefaultValue
        デフォルト値
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .EXAMPLE
        Add-CsvColumn -Path "data.csv" -ColumnName "Status" -DefaultValue "Active" -OutputPath "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$ColumnName,

        [Parameter(Mandatory=$false)]
        [string]$DefaultValue = "",

        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )

    $data = Import-CsvFile -Path $Path

    foreach ($row in $data) {
        $row | Add-Member -MemberType NoteProperty -Name $ColumnName -Value $DefaultValue
    }

    if ($OutputPath) {
        $data | Export-CsvFile -Path $OutputPath
    } else {
        $data | Export-CsvFile -Path $Path
    }
}