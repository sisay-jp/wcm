# 列名変更関数 (Rename Column Function)
function Rename-CsvColumn {
    <#
    .SYNOPSIS
        CSVファイルの列名を変更する
    .DESCRIPTION
        CSVファイルの指定された列名を新しい名前に変更します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER OldName
        変更前の列名
    .PARAMETER NewName
        変更後の列名
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .EXAMPLE
        Rename-CsvColumn -Path "data.csv" -OldName "City" -NewName "都市" -OutputPath "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$OldName,

        [Parameter(Mandatory=$true)]
        [string]$NewName,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )

    $data = Import-CsvFile -Path $Path

    foreach ($row in $data) {
        $value = $row.$OldName
        $row.PSObject.Properties.Remove($OldName)
        $row | Add-Member -MemberType NoteProperty -Name $NewName -Value $value
    }

    if ($OutputPath) {
        $data | Export-CsvFile -Path $OutputPath
    } else {
        $data | Export-CsvFile -Path $Path
    }
}