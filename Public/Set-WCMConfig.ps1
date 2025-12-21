# 設定更新関数 / Update configuration function
function Set-WCMConfig {
    <#
    .SYNOPSIS
        WCMモジュールの設定を更新する
    .DESCRIPTION
        WCMモジュールの設定を更新します。
        -Config のハッシュテーブル指定に加え、-Path でファイル（.psd1 / .json）の読み込みも可能です。
    .PARAMETER Config
        更新する設定のハッシュテーブル
    .PARAMETER Path
        設定ファイルのパス（.psd1 / .json）
        例: @{ DefaultEncoding = 'Shift-JIS'; CaseSensitive = $true }
    .PARAMETER Strict
        未知キーを警告ではなく例外にする
    .PARAMETER Reset
        デフォルト設定に戻してから適用する
    .EXAMPLE
        Set-WCMConfig -Config @{DefaultEncoding = "Shift-JIS"; BackupFiles = $false}
    .EXAMPLE
        Set-WCMConfig -Path './wcm.config.psd1'
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByHashtable')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByHashtable')]
        [hashtable]$Config,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$Path,

        [switch]$Strict,
        [switch]$Reset
    )

    if (Get-Command -Name Initialize-WCMConfig -ErrorAction SilentlyContinue) {
        Initialize-WCMConfig
    }

    if ($Reset) {
        $script:WCMConfig = Get-WCMDefaultConfig
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        if (-not (Test-Path $Path)) {
            throw "設定ファイルが見つかりません: $Path"
        }

        $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
        switch ($ext) {
            '.psd1' {
                $Config = Import-PowerShellDataFile -Path $Path
            }
            '.json' {
                $Config = (Get-Content -Path $Path -Raw) | ConvertFrom-Json -AsHashtable
            }
            default {
                throw "未対応の設定ファイル形式です: $ext（.psd1 / .json を指定してください）"
            }
        }
    }

    if (-not $Config -or $Config.Count -eq 0) {
        return
    }

    # 設定ファイル側で ModuleConfig という入れ子を使う運用にも対応
    if ($Config.ContainsKey('ModuleConfig') -and ($Config['ModuleConfig'] -is [hashtable])) {
        $Config = $Config['ModuleConfig']
    }

    if (Get-Command -Name Set-WCMConfigInternal -ErrorAction SilentlyContinue) {
        Set-WCMConfigInternal -Config $Config -Strict:$Strict

        # ログ設定が変わった可能性があるので再初期化
        if (Get-Command -Name Initialize-WCMLogger -ErrorAction SilentlyContinue) {
            Initialize-WCMLogger
        }

        Write-WCMLog -Level INFO -Message 'WCM config updated' -Data $Config
        return
    }

    # フォールバック（万一 Private が読み込まれていない場合）
    foreach ($key in $Config.Keys) {
        if ($script:WCMConfig.ContainsKey($key)) {
            $script:WCMConfig[$key] = $Config[$key]
            Write-Verbose "設定を更新しました: $key = $($Config[$key])"
        } else {
            $msg = "不明な設定キー: $key"
            if ($Strict) { throw $msg }
            Write-Warning $msg
        }
    }
}
