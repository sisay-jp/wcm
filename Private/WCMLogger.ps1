# WCM ログ機能（内部用）

function Initialize-WCMLogger {
    <#
    .SYNOPSIS
        ログ出力先などを初期化する（内部用）
    #>
    [CmdletBinding()]
    param()

    if (-not $script:WCMConfig) {
        if (Get-Command -Name Initialize-WCMConfig -ErrorAction SilentlyContinue) {
            Initialize-WCMConfig
        }
    }

    # 既定のログパス
    $logPath = $script:WCMConfig.LogPath
    if ([string]::IsNullOrWhiteSpace($logPath)) {
        $base = [System.IO.Path]::GetTempPath()
        $logPath = Join-Path $base 'WCM.log'
    }

    # ディレクトリ作成
    try {
        $dir = Split-Path -Path $logPath -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    } catch {
        # ログ初期化は落とさない
        Write-Verbose "[WCM] Logger init failed: $_"
    }

    $script:WCMLogPath = $logPath
}

function Get-WCMLogLevelOrder {
    [CmdletBinding()]
    param()
    @{
        'DEBUG' = 10
        'INFO'  = 20
        'WARN'  = 30
        'ERROR' = 40
    }
}

function Write-WCMLog {
    <#
    .SYNOPSIS
        WCM のログを一元的に出力する（内部用）
    .PARAMETER Level
        DEBUG / INFO / WARN / ERROR
    .PARAMETER Message
        ログ本文
    .PARAMETER Data
        追加情報（任意）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [hashtable]$Data
    )

    if (-not $script:WCMConfig) {
        if (Get-Command -Name Initialize-WCMConfig -ErrorAction SilentlyContinue) {
            Initialize-WCMConfig
        }
    }

    if (-not $script:WCMConfig.LogEnabled) { return }

    if (-not $script:WCMLogPath) {
        Initialize-WCMLogger
    }

    $order = Get-WCMLogLevelOrder
    $minLevel = $script:WCMConfig.LogLevel
    if (-not $order.ContainsKey($minLevel)) { $minLevel = 'INFO' }

    if ($order[$Level] -lt $order[$minLevel]) {
        return
    }

    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = "[$ts][$Level] $Message"
    if ($Data -and $Data.Count -gt 0) {
        try {
            $json = ($Data | ConvertTo-Json -Depth 6 -Compress)
            $line = "$line | $json"
        } catch {
            # JSON化に失敗しても本文は出す
        }
    }

    # file
    try {
        Add-Content -Path $script:WCMLogPath -Value $line -Encoding UTF8
    } catch {
        # ここで落とすのは本末転倒なので握りつぶす
        Write-Verbose "[WCM] Failed to write log file: $_"
    }

    # console streams（Verbose / Warning / Error）
    if ($script:WCMConfig.LogToConsole) {
        switch ($Level) {
            'ERROR' { Write-Error $Message }
            'WARN'  { Write-Warning $Message }
            default { Write-Verbose "[$Level] $Message" }
        }
    }
}
