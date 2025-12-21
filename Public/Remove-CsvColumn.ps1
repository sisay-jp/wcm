# 列削除関数 (Remove Column Function)
function Remove-CsvColumn {
    <#
    .SYNOPSIS
        CSVファイルから列を削除する
    .DESCRIPTION
        CSVファイルから指定された列を削除します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER ColumnName
        削除する列名
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .EXAMPLE
        Remove-CsvColumn -Path "data.csv" -ColumnName "Status" -OutputPath "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$ColumnName,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )

    $data = Import-CsvFile -Path $Path

    $data = $data | Select-Object * -ExcludeProperty $ColumnName

    if ($OutputPath) {
        $data | Export-CsvFile -Path $OutputPath
    } else {
        $data | Export-CsvFile -Path $Path
    }
}