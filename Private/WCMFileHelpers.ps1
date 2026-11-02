# WCM ファイル操作ヘルパー（内部用）

function New-WCMParentDirectory {
    <#
    .SYNOPSIS
        出力ファイルの親フォルダが無ければ作成する（内部用）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parent = Split-Path -Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }
}

function Get-WCMStringComparer {
    <#
    .SYNOPSIS
        CaseSensitive 設定に対応する文字列比較子を返す（内部用）
    #>
    [CmdletBinding()]
    param()

    if ($script:WCMConfig.CaseSensitive) {
        return [System.StringComparer]::Ordinal
    }
    return [System.StringComparer]::OrdinalIgnoreCase
}

function Clear-WCMSplitFiles {
    <#
    .SYNOPSIS
        前回の分割出力（0001.txt 形式）を削除する（内部用）
    .DESCRIPTION
        行数が減ったときに古いファイルが残らないようにします。
        連番名以外のファイルは削除しません。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    Get-ChildItem -LiteralPath $Directory -Filter '*.txt' -File |
        Where-Object { $_.BaseName -match '^\d{4,}$' } |
        Remove-Item -Force
}

function Test-WCMPathWithin {
    <#
    .SYNOPSIS
        Path が Directory 自身またはその配下かを判定する（内部用）
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $separators = [char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd($separators)
    $fullDirectory = [System.IO.Path]::GetFullPath($Directory).TrimEnd($separators)

    if ($fullPath.Equals($fullDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $fullPath.StartsWith($fullDirectory + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}
