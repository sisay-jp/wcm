# CSV読み込み関数 (CSV Read Function)
function Import-CsvFile {
    <#
    .SYNOPSIS
        CSVファイルを読み込む
    .DESCRIPTION
        指定されたCSVファイルを読み込み、オブジェクトとして返します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER Encoding
        ファイルのエンコーディング (デフォルト: UTF8)
    .EXAMPLE
        Import-CsvFile -Path "data.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string]$Encoding = $script:WCMConfig.DefaultEncoding,

        [Parameter(Mandatory=$false)]
        [string]$Delimiter = $script:WCMConfig.DefaultDelimiter,

        [Parameter(Mandatory=$false)]
        [bool]$HasHeader = $script:WCMConfig.HasHeader
    )

    process {
        if (-not (Test-Path $Path)) {
            Write-WCMLog -Level ERROR -Message "ファイルが見つかりません: $Path" -Data @{ Path = $Path }
            return
        }

        try {
            if ($HasHeader) {
                Write-WCMLog -Level DEBUG -Message 'Import-CsvFile' -Data @{ Path=$Path; Encoding=$Encoding; Delimiter=$Delimiter; HasHeader=$HasHeader }
                Import-Csv -Path $Path -Encoding $Encoding -Delimiter $Delimiter
                return
            }

            # ヘッダーが無い場合は列数を推定し、擬似ヘッダーを付与して読み込む
            $firstLine = Get-Content -Path $Path -Encoding $Encoding -TotalCount 1
            $colCount  = ($firstLine -split [regex]::Escape($Delimiter)).Count
            if ($colCount -lt 1) { $colCount = 1 }
            $headers = 1..$colCount | ForEach-Object { "col$($_)" }
            Write-WCMLog -Level DEBUG -Message 'Import-CsvFile(no header)' -Data @{ Path=$Path; Encoding=$Encoding; Delimiter=$Delimiter; Columns=$colCount }
            Import-Csv -Path $Path -Encoding $Encoding -Delimiter $Delimiter -Header $headers
        }
        catch {
            Write-WCMLog -Level ERROR -Message "CSVファイルの読み込みに失敗しました: $Path" -Data @{ Error = "$_" }
            return
        }
    }
}