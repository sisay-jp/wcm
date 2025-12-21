@{
    # モジュールマニフェストファイル
    RootModule = 'WCM.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'
    Author = 'WCM Contributors'
    CompanyName = 'Unknown'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Windows CSV Manager - PowerShell module for CSV file text editing operations (CSVファイルのテキスト編集操作用PowerShellモジュール)'
    PowerShellVersion = '5.1'
    
    # このモジュールからエクスポートされる関数
    FunctionsToExport = @(
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
    
    # このモジュールからエクスポートされるコマンドレット
    CmdletsToExport = @()
    
    # このモジュールからエクスポートされる変数
    VariablesToExport = @()
    
    # このモジュールからエクスポートされるエイリアス
    AliasesToExport = @()
    
    # プライベートデータ
    PrivateData = @{
        PSData = @{
            Tags = @('CSV', 'Text', 'Editing', 'Data', 'PowerShell', 'Japanese')
            LicenseUri = ''
            ProjectUri = 'https://github.com/sisay-jp/wcm'
            ReleaseNotes = 'Initial release with core CSV text editing functions'
        }
    }
}
