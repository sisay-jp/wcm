# テキストファイル処理関数（シンプル版） / Text File Processing Function (Simple)
function Process-TextFile-Simple {
    <#
    .SYNOPSIS
        テキストファイルをシンプルに処理する（除外、重複削除、ファイル分割）
    .DESCRIPTION
        互換性のために残している関数です。処理は Process-TextFile に委譲します。
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
    .EXAMPLE
        Process-TextFile-Simple -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt" -OutputDir "modify" -ListFile "file_list.txt"
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
        [string]$ListFile
    )

    Process-TextFile @PSBoundParameters
}
