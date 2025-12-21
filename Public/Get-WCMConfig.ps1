# 設定取得関数 / Get configuration function
function Get-WCMConfig {
    <#
    .SYNOPSIS
        WCMモジュールの設定を取得する
    .DESCRIPTION
        現在のWCMモジュールの設定を返します
    .EXAMPLE
        Get-WCMConfig
    #>
    [CmdletBinding()]
    param()

    return $script:WCMConfig.Clone()
}