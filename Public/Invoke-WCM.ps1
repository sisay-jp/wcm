function Invoke-WCM {
    <#
    .SYNOPSIS
        設定ファイルを参照して WCM のメイン処理を実行する
    .DESCRIPTION
        「引数で全部渡す」のではなく、設定ファイル（.psd1 / .json）にまとめて
        そこから各メイン関数（Process-CsvAdvanced-Updated 等）を呼び出します。

        設定例（psd1）:
        @{
          ModuleConfig = @{ DefaultEncoding = 'UTF8'; CaseSensitive = $false }
          Tasks = @(
            @{ Action = 'Process-CsvAdvanced-Updated'; Params = @{ InputFile = 'examples/sample_data.csv'; ReplaceFile = 'examples/rules.csv'; ExcludeFile = 'examples/exclude.txt'; OutputFile = 'demo_output/out.csv' } }
          )
        }
    .PARAMETER ConfigPath
        実行設定ファイルのパス（.psd1 / .json）
    .PARAMETER TaskName
        Tasks に Name を付けている場合、その Name のみ実行する
    .PARAMETER WhatIf
        呼び出しだけ行い、実際の処理を実行しない（呼び出し先が -WhatIf に対応している場合のみ有効）
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [string]$TaskName
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "ConfigPath が見つかりません: $ConfigPath"
    }

    $baseDir = Split-Path -Path $ConfigPath -Parent
    $ext = [System.IO.Path]::GetExtension($ConfigPath).ToLowerInvariant()
    switch ($ext) {
        '.psd1' { $cfg = Import-PowerShellDataFile -Path $ConfigPath }
        '.json' { $cfg = (Get-Content -Path $ConfigPath -Raw) | ConvertFrom-Json -AsHashtable }
        default { throw "未対応の設定ファイル形式です: $ext（.psd1 / .json を指定してください）" }
    }

    if (-not ($cfg -is [hashtable])) {
        throw "設定ファイルの読み込みに失敗しました: $ConfigPath"
    }

    # 1) モジュール設定の反映（任意）
    if ($cfg.ContainsKey('ModuleConfig') -and ($cfg.ModuleConfig -is [hashtable])) {
        Set-WCMConfig -Config $cfg.ModuleConfig
    }

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
            if ($v -match '^[a-zA-Z]:\\' -or $v.StartsWith('\\') -or $v.StartsWith('/')) { continue }

            # ファイル/ディレクトリっぽいものだけ（雑だが安全側）
            if ($v -match '\\|/' -or $v -match '\.\w+$') {
                $params[$k] = Join-Path $baseDir $v
            }
        }

        $displayName = if ($t.Name) { $t.Name } else { $action }
        if ($PSCmdlet.ShouldProcess($displayName, $action)) {
            if (-not (Get-Command -Name $action -ErrorAction SilentlyContinue)) {
                throw "Action '$action' が見つかりません（モジュールの Public 関数名を指定してください）"
            }

            & $action @params
        }
    }
}
