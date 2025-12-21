# WCM 設定（デフォルト値・スキーマ・更新ロジック）

function Get-WCMDefaultConfig {
    <#
    .SYNOPSIS
        WCM のデフォルト設定を返す（内部用）
    #>
    [CmdletBinding()]
    param()

    @{
        # デフォルトエンコーディング / Default encoding
        DefaultEncoding   = 'UTF8'

        # デフォルトデリミタ / Default delimiter
        DefaultDelimiter  = ','

        # ヘッダー行の有無 / Whether CSV has header row
        HasHeader         = $true

        # 変更前にバックアップを作成 / Create backup before modifications
        BackupFiles       = $true

        # バックアップファイルの拡張子 / Backup file extension
        BackupExtension   = '.backup'

        # 大文字小文字を区別 / Case sensitive search/replace
        CaseSensitive     = $false

        # 検索時の正規表現使用 / Use regex in search operations
        UseRegex          = $false

        # ログ設定 / Logging
        LogEnabled        = $true
        # 空なら「ユーザーの Temp 配下」に自動作成
        LogPath           = ''
        # DEBUG / INFO / WARN / ERROR
        LogLevel          = 'INFO'
        # 既存の Write-Verbose/Write-Warning/Write-Error にも出す
        LogToConsole      = $true
    }
}

function Get-WCMConfigSchema {
    <#
    .SYNOPSIS
        設定キーの定義（型・許容値）を返す（内部用）
    #>
    [CmdletBinding()]
    param()

    @{
        DefaultEncoding  = @{ Type = 'string';  Allowed = @('UTF8', 'UTF7', 'UTF32', 'Unicode', 'BigEndianUnicode', 'ASCII', 'Default', 'OEM', 'Shift-JIS') }
        DefaultDelimiter = @{ Type = 'string';  Allowed = @(',', ';', "\t", '|') }
        HasHeader        = @{ Type = 'bool' }
        BackupFiles      = @{ Type = 'bool' }
        BackupExtension  = @{ Type = 'string' }
        CaseSensitive    = @{ Type = 'bool' }
        UseRegex         = @{ Type = 'bool' }

        LogEnabled       = @{ Type = 'bool' }
        LogPath          = @{ Type = 'string' }
        LogLevel         = @{ Type = 'string'; Allowed = @('DEBUG', 'INFO', 'WARN', 'ERROR') }
        LogToConsole     = @{ Type = 'bool' }
    }
}

function Initialize-WCMConfig {
    <#
    .SYNOPSIS
        WCMConfig を初期化する（モジュールロード時に呼ばれる）
    #>
    [CmdletBinding()]
    param()

    if (-not $script:WCMConfig) {
        $script:WCMConfig = Get-WCMDefaultConfig
    }

    if (-not $script:WCMConfigSchema) {
        $script:WCMConfigSchema = Get-WCMConfigSchema
    }
}

function ConvertTo-WCMBool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($Value -is [bool]) { return $Value }

    $s = ($Value | Out-String).Trim()
    switch -Regex ($s) {
        '^(1|true|t|yes|y|on)$'  { return $true }
        '^(0|false|f|no|n|off)$' { return $false }
        default { throw "boolean に変換できません: $Value" }
    }
}

function Set-WCMConfigInternal {
    <#
    .SYNOPSIS
        設定を更新する（内部用：Set-WCMConfig の実体）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [switch]$Strict
    )

    Initialize-WCMConfig

    foreach ($key in $Config.Keys) {
        if (-not $script:WCMConfigSchema.ContainsKey($key)) {
            $msg = "不明な設定キー: $key"
            if ($Strict) { throw $msg }
            Write-Warning $msg
            continue
        }

        $schema = $script:WCMConfigSchema[$key]
        $val    = $Config[$key]

        # 型変換
        switch ($schema.Type) {
            'bool'   { $val = ConvertTo-WCMBool -Value $val }
            'string' { $val = [string]$val }
            default  { }
        }

        # Allowed チェック
        if ($schema.ContainsKey('Allowed') -and $schema.Allowed) {
            if ($schema.Allowed -notcontains $val) {
                $allowed = ($schema.Allowed -join ', ')
                throw "設定 '$key' の値 '$val' は許可されていません。許可: $allowed"
            }
        }

        # 値チェック（簡易）
        if ($key -eq 'BackupExtension') {
            if (-not $val.StartsWith('.')) {
                throw "BackupExtension は '.' で始めてください: $val"
            }
        }

        $script:WCMConfig[$key] = $val
        Write-Verbose "設定を更新しました: $key = $val"
    }
}
