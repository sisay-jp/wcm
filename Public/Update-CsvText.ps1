# テキスト置換関数 (Text Replace Function)
function Update-CsvText {
    <#
    .SYNOPSIS
        CSV内のテキストを置換する
    .DESCRIPTION
        CSVファイル内の指定されたテキストを置換し、新しいファイルに保存します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER SearchText
        検索するテキスト
    .PARAMETER ReplaceText
        置換後のテキスト
    .PARAMETER Column
        置換対象の列名 (指定しない場合は全列を置換)
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .PARAMETER CaseSensitive
        大文字小文字を区別する
    .EXAMPLE
        Update-CsvText -Path "data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$SearchText,

        [Parameter(Mandatory=$true)]
        [string]$ReplaceText,

        [Parameter(Mandatory=$false)]
        [string]$Column,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [switch]$CaseSensitive
    )

    # CaseSensitiveが明示的に指定されていない場合はコンフィグを使用
    if (-not $PSBoundParameters.ContainsKey('CaseSensitive')) {
        $CaseSensitive = $script:WCMConfig.CaseSensitive
    }

    $data = Import-CsvFile -Path $Path

    if ($Column) {
        # 特定の列を置換
        foreach ($row in $data) {
            if ($CaseSensitive) {
                $row.$Column = $row.$Column -creplace [regex]::Escape($SearchText), $ReplaceText
            } else {
                $row.$Column = $row.$Column -replace [regex]::Escape($SearchText), $ReplaceText
            }
        }
    } else {
        # 全列を置換
        foreach ($row in $data) {
            foreach ($prop in $row.PSObject.Properties) {
                if ($CaseSensitive) {
                    $prop.Value = $prop.Value -creplace [regex]::Escape($SearchText), $ReplaceText
                } else {
                    $prop.Value = $prop.Value -replace [regex]::Escape($SearchText), $ReplaceText
                }
            }
        }
    }

    # 出力
    if ($OutputPath) {
        $data | Export-CsvFile -Path $OutputPath
    } else {
        $data | Export-CsvFile -Path $Path
    }
}