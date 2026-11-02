# テキストファイル処理関数（更新版） / Text File Processing Function (Updated)
function Process-TextFile-Updated {
    <#
    .SYNOPSIS
        テキストファイルを処理して除外と重複削除を行う（更新版）
    .DESCRIPTION
        互換性のために残している関数です。
        Process-TextFile に -DedupeIgnoreOrder と -CountExclusions を付けて委譲します。
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

    Process-TextFile @PSBoundParameters -DedupeIgnoreOrder -CountExclusions
}
