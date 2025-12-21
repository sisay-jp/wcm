function Invoke-WCM {
    <#
    .SYNOPSIS
        設定ファイルを参照して WCM のメイン処理を実行する
    .DESCRIPTION
        「引数で全部渡す」のではなく、設定ファイル（.psd1 / .json）にまとめて
        そこから各メイン関数（Process-CsvAdvanced-Updated 等）を呼び出します。
    .PARAMETER ConfigPath
        実行設定ファイルのパス（.psd1 / .json）
    .PARAMETER TaskName
        Tasks に Name を付けている場合、その Name のみ実行する
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [string]$TaskName
    )

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "ConfigPath が見つかりません: $ConfigPath"
    }

    # ConfigPath をフルパス化（親ディレクトリ無し相対パス対策）
    $configFullPath = $ConfigPath
    try {
        $configFullPath = (Resolve-Path -LiteralPath $ConfigPath).Path
    } catch {
        Write-Warning ("ConfigPath のフルパス解決に失敗したため、指定されたパスをそのまま使用します。ConfigPath: '{0}' 詳細: {1}" -f $ConfigPath, $_.Exception.Message)
        $configFullPath = $ConfigPath
    }

    # Config の基準ディレクトリ（親が空なら CurrentDir）
    $baseDir = Split-Path -Path $configFullPath -Parent
    if ([string]::IsNullOrWhiteSpace($baseDir)) {
        $baseDir = (Get-Location).Path
    }

    $ext = [System.IO.Path]::GetExtension($configFullPath).ToLowerInvariant()
    switch ($ext) {
        '.psd1' { $cfg = Import-PowerShellDataFile -Path $configFullPath }
        '.json' { $cfg = (Get-Content -Path $configFullPath -Raw) | ConvertFrom-Json -AsHashtable }
        default { throw "未対応の設定ファイル形式です: $ext（.psd1 / .json を指定してください）" }
    }

    if (-not ($cfg -is [hashtable])) {
        throw "設定ファイルの読み込みに失敗しました: $configFullPath"
    }

    # 1) モジュール設定の反映（任意）
    if ($cfg.ContainsKey('ModuleConfig') -and ($cfg.ModuleConfig -is [hashtable])) {
        Set-WCMConfig -Config $cfg.ModuleConfig
    }

    # Invoke-WCM 実行コンテキストをログ（設定反映後に出す）
    try {
        Write-WCMLog -Level INFO -Message "Invoke-WCM start | CurrentDir=$((Get-Location).Path) | ConfigPath=$configFullPath | BaseDir=$baseDir"
    } catch {}

    # 2) Tasks の実行
    $tasks = @()
    if ($cfg.ContainsKey('Tasks')) {
        $tasks = @($cfg.Tasks)
    }
    if (-not $tasks -or $tasks.Count -eq 0) {
        throw "Tasks が定義されていません。Config に Tasks = @(...) を追加してください。"
    }

    if ($TaskName) {
        $tasks = $tasks | Where-Object { $_.Name -eq $TaskName }
        if (-not $tasks -or $tasks.Count -eq 0) {
            throw "TaskName '$TaskName' に一致するタスクが見つかりません。"
        }
    }

    foreach ($t in $tasks) {
        if (-not ($t -is [hashtable])) {
            throw "Tasks の各要素は hashtable である必要があります。"
        }

        $action = $t.Action
        if (-not $action) {
            throw "Task に Action がありません（例: @{ Action = 'Process-CsvAdvanced-Updated'; Params = @{...} }）"
        }

        $params = @{}
        if ($t.ContainsKey('Params') -and ($t.Params -is [hashtable])) {
            $params = $t.Params.Clone()
        }

        # 相対パスを config の場所基準に解決（string のみ対象）
        foreach ($k in @($params.Keys)) {
            $v = $params[$k]
            if ($v -isnot [string]) { continue }
            if ([string]::IsNullOrWhiteSpace($v)) { continue }

            # 絶対パスっぽいものはそのまま（Windows/UNC/Unix）
            if ($v -match '^[a-zA-Z]:\\' -or $v.StartsWith('\\') -or $v.StartsWith('/')) { continue }

            # ファイル/ディレクトリっぽいものだけ（雑だが安全側）
            if ($v -match '\\|/' -or $v -match '\.\w+$') {
                if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
                    $params[$k] = Join-Path -Path $baseDir -ChildPath $v
                }
            }
        }

        $displayName = if ($t.Name) { $t.Name } else { $action }

        if ($PSCmdlet.ShouldProcess($displayName, $action)) {
            if (-not (Get-Command -Name $action -ErrorAction SilentlyContinue)) {
                throw "Action '$action' が見つかりません（モジュールの Public 関数名を指定してください）"
            }

            try {
                Write-WCMLog -Level INFO -Message "Start task: $displayName | Action=$action"
            } catch {}

            try {
                if ($params.Count -eq 0) {
                    Write-WCMLog -Level DEBUG -Message "Task params: (none)"
                } else {
                    $pairs = foreach ($k in ($params.Keys | Sort-Object)) {
                        $raw = $params[$k]

                        # ログ汚染防止：改行を潰して短縮
                        $s = if ($null -eq $raw) { '<null>' } else { [string]$raw }
                        $s = $s -replace "(\r\n|\r|\n)", ' '
                        if ($s.Length -gt 240) { $s = $s.Substring(0, 240) + '...' }

                        "{0}={1}" -f $k, $s
                    }
                    Write-WCMLog -Level DEBUG -Message ("Task params: " + ($pairs -join " | "))
                }
            } catch {}

            & $action @params

            try {
                Write-WCMLog -Level INFO -Message "Finish task: $displayName"
            } catch {}
        }
    }
}
