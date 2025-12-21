#Requires -Version 5.1

<#
.SYNOPSIS
    Windows CSV Manager (WCM) - PowerShell module for CSV file text editing operations
.DESCRIPTION
    This module provides functions to edit text in CSV files including search, replace,
    column manipulation, and row filtering.
#>

## モジュール設定 / Module Configuration
##
## NOTE:
##   デフォルト設定は Private\WCMConfig.ps1 に切り出しました。
##   ここでは「初期化だけ」行います。

# Import private functions first (config initializer lives here)
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($function in $PrivateFunctions) {
    . $function.FullName
}

# Initialize config (defined in Private/WCMConfig.ps1)
if (Get-Command -Name Initialize-WCMConfig -ErrorAction SilentlyContinue) {
    Initialize-WCMConfig
}

# Initialize logger (defined in Private/WCMLogger.ps1)
if (Get-Command -Name Initialize-WCMLogger -ErrorAction SilentlyContinue) {
    Initialize-WCMLogger
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($function in $PublicFunctions) {
    . $function.FullName
}

# Module export
Export-ModuleMember -Function @(
    'Import-CsvFile',
    'Export-CsvFile',
    'Find-CsvText',
    'Update-CsvText',
    'Add-CsvColumn',
    'Remove-CsvColumn',
    'Rename-CsvColumn',
    'Select-CsvRows',
    'Get-WCMConfig',
    'Set-WCMConfig',
    'Process-CsvAdvanced',
    'Process-TextFile',
    'Merge-TextFiles',
    'Find-UnusedSearchTerms',
    'Get-UniqueKeywords',
    'Process-TextFile-Updated',
    'Process-CsvAdvanced-Updated',
    'Process-TextFile-Simple',
    'Find-TextContent',
    'Find-TextContent-Mismatch',
    'Find-TextContent-WithCopy',
    'Invoke-WCM'
)
