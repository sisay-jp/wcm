# CSV保存関数 (CSV Save Function)
function Export-CsvFile {
    <#
    .SYNOPSIS
        CSVファイルに保存する
    .DESCRIPTION
        オブジェクトをCSVファイルに保存します
    .PARAMETER Data
        保存するデータ
    .PARAMETER Path
        保存先のパス
    .PARAMETER Encoding
        ファイルのエンコーディング (デフォルト: UTF8)
    .EXAMPLE
        $data | Export-CsvFile -Path "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [object[]]$Data,

        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string]$Encoding = $script:WCMConfig.DefaultEncoding,

        [Parameter(Mandatory=$false)]
        [string]$Delimiter = $script:WCMConfig.DefaultDelimiter,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeHeader = $script:WCMConfig.HasHeader,

        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    begin {
        $allData = [System.Collections.ArrayList]::new()
    }

    process {
        [void]$allData.AddRange($Data)
    }

    end {
        try {
            if ($IncludeHeader) {
                $allData | Export-Csv -Path $Path -Encoding $Encoding -NoTypeInformation -Delimiter $Delimiter -NoClobber:$NoClobber
            } else {
                # Export-Csv は常にヘッダー出力するため ConvertTo-Csv で制御
                $lines = $allData | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter
                $lines = $lines | Select-Object -Skip 1
                if ($NoClobber -and (Test-Path $Path)) {
                    throw "既にファイルが存在します（NoClobber）: $Path"
                }
                Set-Content -Path $Path -Value $lines -Encoding $Encoding
            }
            Write-WCMLog -Level INFO -Message "CSVファイルを保存しました: $Path" -Data @{ Path=$Path; Encoding=$Encoding; Delimiter=$Delimiter; IncludeHeader=$IncludeHeader }
        }
        catch {
            Write-WCMLog -Level ERROR -Message "CSVファイルの保存に失敗しました: $Path" -Data @{ Error = "$_" }
        }
    }
}