#Requires -Version 5.1

<#
.SYNOPSIS
    Windows CSV Manager (WCM) - PowerShell module for CSV file text editing operations
.DESCRIPTION
    This module provides functions to edit text in CSV files including search, replace, 
    column manipulation, and row filtering.
#>

# CSV読み込み関数 (CSV Read Function)
function Import-CsvFile {
    <#
    .SYNOPSIS
        CSVファイルを読み込む
    .DESCRIPTION
        指定されたCSVファイルを読み込み、オブジェクトとして返します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER Encoding
        ファイルのエンコーディング (デフォルト: UTF8)
    .EXAMPLE
        Import-CsvFile -Path "data.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Encoding = "UTF8"
    )
    
    process {
        if (-not (Test-Path $Path)) {
            Write-Error "ファイルが見つかりません: $Path"
            return
        }
        
        try {
            Import-Csv -Path $Path -Encoding $Encoding
        }
        catch {
            Write-Error "CSVファイルの読み込みに失敗しました: $_"
        }
    }
}

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
        [string]$Encoding = "UTF8",
        
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
            $allData | Export-Csv -Path $Path -Encoding $Encoding -NoTypeInformation -NoClobber:$NoClobber
            Write-Verbose "CSVファイルを保存しました: $Path"
        }
        catch {
            Write-Error "CSVファイルの保存に失敗しました: $_"
        }
    }
}

# テキスト検索関数 (Text Search Function)
function Find-CsvText {
    <#
    .SYNOPSIS
        CSV内のテキストを検索する
    .DESCRIPTION
        CSVファイル内の指定されたテキストを検索し、該当する行を返します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER SearchText
        検索するテキスト
    .PARAMETER Column
        検索対象の列名 (指定しない場合は全列を検索)
    .PARAMETER CaseSensitive
        大文字小文字を区別する
    .EXAMPLE
        Find-CsvText -Path "data.csv" -SearchText "Tokyo"
    .EXAMPLE
        Find-CsvText -Path "data.csv" -SearchText "Tokyo" -Column "City"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$SearchText,
        
        [Parameter(Mandatory=$false)]
        [string]$Column,
        
        [Parameter(Mandatory=$false)]
        [switch]$CaseSensitive
    )
    
    $data = Import-CsvFile -Path $Path
    
    if ($Column) {
        # 特定の列を検索
        if ($CaseSensitive) {
            $data | Where-Object { $_.$Column -clike "*$SearchText*" }
        }
        else {
            $data | Where-Object { $_.$Column -like "*$SearchText*" }
        }
    }
    else {
        # 全列を検索
        $data | Where-Object {
            $row = $_
            $found = $false
            foreach ($prop in $row.PSObject.Properties) {
                if ($CaseSensitive) {
                    if ($prop.Value -clike "*$SearchText*") {
                        $found = $true
                        break
                    }
                }
                else {
                    if ($prop.Value -like "*$SearchText*") {
                        $found = $true
                        break
                    }
                }
            }
            $found
        }
    }
}

# テキスト置換関数 (Text Replace Function)
function Update-CsvText {
    <#
    .SYNOPSIS
        CSV内のテキストを置換する
    .DESCRIPTION
        CSVファイル内の指定されたテキストを置換し、新しいファイルに保存します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER SearchText
        検索するテキスト
    .PARAMETER ReplaceText
        置換後のテキスト
    .PARAMETER Column
        置換対象の列名 (指定しない場合は全列を置換)
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .PARAMETER CaseSensitive
        大文字小文字を区別する
    .EXAMPLE
        Update-CsvText -Path "data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath "output.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$SearchText,
        
        [Parameter(Mandatory=$true)]
        [string]$ReplaceText,
        
        [Parameter(Mandatory=$false)]
        [string]$Column,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$CaseSensitive
    )
    
    $data = Import-CsvFile -Path $Path
    
    if (-not $OutputPath) {
        $OutputPath = $Path
    }
    
    $updatedData = $data | ForEach-Object {
        $row = $_
        if ($Column) {
            # 特定の列のみ置換
            if ($CaseSensitive) {
                $row.$Column = $row.$Column -creplace [regex]::Escape($SearchText), $ReplaceText
            }
            else {
                $row.$Column = $row.$Column -replace [regex]::Escape($SearchText), $ReplaceText
            }
        }
        else {
            # 全列を置換
            foreach ($prop in $row.PSObject.Properties) {
                $propName = $prop.Name
                if ($CaseSensitive) {
                    $row.$propName = $row.$propName -creplace [regex]::Escape($SearchText), $ReplaceText
                }
                else {
                    $row.$propName = $row.$propName -replace [regex]::Escape($SearchText), $ReplaceText
                }
            }
        }
        $row
    }
    
    $updatedData | Export-CsvFile -Path $OutputPath
}

# 列追加関数 (Add Column Function)
function Add-CsvColumn {
    <#
    .SYNOPSIS
        CSVに列を追加する
    .DESCRIPTION
        CSVファイルに新しい列を追加します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER ColumnName
        追加する列名
    .PARAMETER DefaultValue
        デフォルト値
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .EXAMPLE
        Add-CsvColumn -Path "data.csv" -ColumnName "Status" -DefaultValue "Active"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$ColumnName,
        
        [Parameter(Mandatory=$false)]
        [string]$DefaultValue = "",
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )
    
    $data = Import-CsvFile -Path $Path
    
    if (-not $OutputPath) {
        $OutputPath = $Path
    }
    
    $updatedData = $data | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name $ColumnName -Value $DefaultValue -Force
        $_
    }
    
    $updatedData | Export-CsvFile -Path $OutputPath
}

# 列削除関数 (Remove Column Function)
function Remove-CsvColumn {
    <#
    .SYNOPSIS
        CSVから列を削除する
    .DESCRIPTION
        CSVファイルから指定された列を削除します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER ColumnName
        削除する列名
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .EXAMPLE
        Remove-CsvColumn -Path "data.csv" -ColumnName "OldColumn"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string[]]$ColumnName,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )
    
    $data = Import-CsvFile -Path $Path
    
    if (-not $OutputPath) {
        $OutputPath = $Path
    }
    
    $updatedData = $data | Select-Object -Property * -ExcludeProperty $ColumnName
    
    $updatedData | Export-CsvFile -Path $OutputPath
}

# 列名変更関数 (Rename Column Function)
function Rename-CsvColumn {
    <#
    .SYNOPSIS
        CSVの列名を変更する
    .DESCRIPTION
        CSVファイルの列名を変更します
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER OldName
        現在の列名
    .PARAMETER NewName
        新しい列名
    .PARAMETER OutputPath
        出力先のパス (指定しない場合は元のファイルを上書き)
    .EXAMPLE
        Rename-CsvColumn -Path "data.csv" -OldName "Old" -NewName "New"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$OldName,
        
        [Parameter(Mandatory=$true)]
        [string]$NewName,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )
    
    $data = Import-CsvFile -Path $Path
    
    if (-not $OutputPath) {
        $OutputPath = $Path
    }
    
    # 最初の行で列の存在を確認
    if ($data -and $data.Count -gt 0) {
        $firstRow = $data[0]
        if (-not $firstRow.PSObject.Properties.Name -contains $OldName) {
            Write-Error "列 '$OldName' が見つかりません"
            return
        }
    }
    
    $updatedData = $data | ForEach-Object {
        $value = $_.$OldName
        $_ | Add-Member -MemberType NoteProperty -Name $NewName -Value $value -Force
        $_.PSObject.Properties.Remove($OldName)
        $_
    }
    
    $updatedData | Export-CsvFile -Path $OutputPath
}

# 行フィルタ関数 (Filter Rows Function)
function Select-CsvRows {
    <#
    .SYNOPSIS
        CSVから行をフィルタする
    .DESCRIPTION
        指定された条件に基づいてCSVの行をフィルタします
    .PARAMETER Path
        CSVファイルのパス
    .PARAMETER Column
        フィルタ対象の列名
    .PARAMETER Value
        フィルタ値
    .PARAMETER Operator
        比較演算子 (Equals, NotEquals, Contains, NotContains, GreaterThan, LessThan)
    .PARAMETER OutputPath
        出力先のパス
    .EXAMPLE
        Select-CsvRows -Path "data.csv" -Column "Age" -Value "30" -Operator "GreaterThan" -OutputPath "filtered.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Column,
        
        [Parameter(Mandatory=$true)]
        [string]$Value,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Equals", "NotEquals", "Contains", "NotContains", "GreaterThan", "LessThan")]
        [string]$Operator = "Equals",
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )
    
    $data = Import-CsvFile -Path $Path
    
    $filteredData = switch ($Operator) {
        "Equals" { $data | Where-Object { $_.$Column -eq $Value } }
        "NotEquals" { $data | Where-Object { $_.$Column -ne $Value } }
        "Contains" { $data | Where-Object { $_.$Column -like "*$Value*" } }
        "NotContains" { $data | Where-Object { $_.$Column -notlike "*$Value*" } }
        "GreaterThan" { 
            $data | Where-Object { 
                $numValue = 0
                $numColumn = 0
                if ([double]::TryParse($Value, [ref]$numValue) -and [double]::TryParse($_.$Column, [ref]$numColumn)) {
                    $numColumn -gt $numValue
                }
                else {
                    Write-Warning "数値比較に失敗しました: 行 $($_.Name), 値 '$($_.$Column)'"
                    $false
                }
            }
        }
        "LessThan" { 
            $data | Where-Object { 
                $numValue = 0
                $numColumn = 0
                if ([double]::TryParse($Value, [ref]$numValue) -and [double]::TryParse($_.$Column, [ref]$numColumn)) {
                    $numColumn -lt $numValue
                }
                else {
                    Write-Warning "数値比較に失敗しました: 行 $($_.Name), 値 '$($_.$Column)'"
                    $false
                }
            }
        }
    }
    
    if ($OutputPath) {
        $filteredData | Export-CsvFile -Path $OutputPath
    }
    else {
        return $filteredData
    }
}

# モジュールのエクスポート
Export-ModuleMember -Function @(
    'Import-CsvFile',
    'Export-CsvFile',
    'Find-CsvText',
    'Update-CsvText',
    'Add-CsvColumn',
    'Remove-CsvColumn',
    'Rename-CsvColumn',
    'Select-CsvRows'
)
