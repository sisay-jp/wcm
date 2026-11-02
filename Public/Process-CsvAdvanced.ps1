# 高度なCSV処理関数 / Advanced CSV Processing Function
function Process-CsvAdvanced {
    <#
    .SYNOPSIS
        高度なCSV処理を実行する（条件付き置換、除外、重複削除）
    .DESCRIPTION
        互換性のために残している関数です。処理は Process-CsvAdvanced-Updated に委譲します。
    .PARAMETER InputFile
        入力CSVファイルのパス
    .PARAMETER ReplaceFile
        置換ルール定義ファイルのパス（オプション）
    .PARAMETER ExcludeFile
        除外ワード定義ファイルのパス（オプション）
    .PARAMETER OutputFile
        出力ファイルのパス（指定しない場合はコンソールに出力）
    .EXAMPLE
        Process-CsvAdvanced -InputFile "data.csv" -ReplaceFile "rules.csv" -ExcludeFile "exclude.txt" -OutputFile "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputFile,

        [Parameter(Mandatory=$false)]
        [string]$ReplaceFile,

        [Parameter(Mandatory=$false)]
        [string]$ExcludeFile,

        [Parameter(Mandatory=$false)]
        [string]$OutputFile
    )

    Process-CsvAdvanced-Updated @PSBoundParameters
}
