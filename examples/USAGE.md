# WCM (Windows CSV Manager) - 使用例 / Usage Examples

## 概要 / Overview

**日本語:**
WCMは、PowerShellでCSVファイルのテキスト編集操作を簡単に行うためのモジュールです。

**English:**
WCM is a PowerShell module for easy text editing operations on CSV files.

## インストール / Installation

```powershell
# モジュールをインポート / Import the module
Import-Module ./WCM.psd1
```

## 使用例 / Usage Examples

### 1. CSVファイルの読み込み / Reading CSV Files

```powershell
# 基本的な読み込み / Basic read
$data = Import-CsvFile -Path "examples/sample_data.csv"
$data

# 結果を表示 / Display results
$data | Format-Table
```

### 2. テキスト検索 / Text Search

```powershell
# 全列から"Tokyo"を検索 / Search for "Tokyo" in all columns
Find-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo"

# 特定の列で検索 / Search in specific column
Find-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -Column "City"

# 大文字小文字を区別して検索 / Case-sensitive search
Find-CsvText -Path "examples/sample_data.csv" -SearchText "TOKYO" -CaseSensitive
```

### 3. テキスト置換 / Text Replace

```powershell
# "Tokyo"を"東京"に置換 / Replace "Tokyo" with "東京"
Update-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath "examples/output.csv"

# 特定の列のみ置換 / Replace in specific column only
Update-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -ReplaceText "東京" -Column "City" -OutputPath "examples/output.csv"

# 元のファイルを上書き / Overwrite original file
Update-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -ReplaceText "東京"
```

### 4. 列の追加 / Add Column

```powershell
# 新しい列を追加 / Add a new column
Add-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Status" -DefaultValue "Active" -OutputPath "examples/output.csv"

# 空の列を追加 / Add an empty column
Add-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Notes" -OutputPath "examples/output.csv"
```

### 5. 列の削除 / Remove Column

```powershell
# 列を削除 / Remove a column
Remove-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Age" -OutputPath "examples/output.csv"

# 複数の列を削除 / Remove multiple columns
Remove-CsvColumn -Path "examples/sample_data.csv" -ColumnName @("Age", "Department") -OutputPath "examples/output.csv"
```

### 6. 列名の変更 / Rename Column

```powershell
# 列名を変更 / Rename a column
Rename-CsvColumn -Path "examples/sample_data.csv" -OldName "City" -NewName "都市" -OutputPath "examples/output.csv"
```

### 7. 行のフィルタリング / Filter Rows

```powershell
# 特定の値と一致する行を抽出 / Extract rows matching a value
Select-CsvRows -Path "examples/sample_data.csv" -Column "City" -Value "Tokyo" -Operator "Equals" -OutputPath "examples/tokyo_only.csv"

# 年齢が30以上の行を抽出 / Extract rows where age is 30 or more
Select-CsvRows -Path "examples/sample_data.csv" -Column "Age" -Value "30" -Operator "GreaterThan" -OutputPath "examples/age_over_30.csv"

# テキストを含む行を抽出 / Extract rows containing text
Select-CsvRows -Path "examples/sample_data.csv" -Column "Department" -Value "Sales" -Operator "Contains" -OutputPath "examples/sales_dept.csv"
```

### 8. パイプラインでの組み合わせ / Combining with Pipeline

```powershell
# 複数の操作を組み合わせ / Combine multiple operations
$data = Import-CsvFile -Path "examples/sample_data.csv"
$data | Where-Object { $_.City -eq "Tokyo" } | Export-CsvFile -Path "examples/tokyo_employees.csv"
```

### 9. 高度な使用例 / Advanced Examples

```powershell
# データの集計 / Data aggregation
$data = Import-CsvFile -Path "examples/sample_data.csv"
$data | Group-Object City | Select-Object Name, Count

# データの並べ替え / Sort data
$data = Import-CsvFile -Path "examples/sample_data.csv"
$data | Sort-Object Age -Descending | Export-CsvFile -Path "examples/sorted.csv"

# 条件に基づいた複雑なフィルタリング / Complex filtering based on conditions
$data = Import-CsvFile -Path "examples/sample_data.csv"
$filtered = $data | Where-Object { 
    $_.City -eq "Tokyo" -and [int]$_.Age -gt 30 
}
$filtered | Export-CsvFile -Path "examples/filtered.csv"
```

## 利用可能な関数一覧 / Available Functions

| 関数名 / Function | 説明 / Description |
|------------------|-------------------|
| `Import-CsvFile` | CSVファイルを読み込む / Read CSV file |
| `Export-CsvFile` | CSVファイルに保存する / Save to CSV file |
| `Find-CsvText` | テキストを検索する / Search for text |
| `Update-CsvText` | テキストを置換する / Replace text |
| `Add-CsvColumn` | 列を追加する / Add column |
| `Remove-CsvColumn` | 列を削除する / Remove column |
| `Rename-CsvColumn` | 列名を変更する / Rename column |
| `Select-CsvRows` | 行をフィルタする / Filter rows |

## ヘルプの表示 / Getting Help

```powershell
# 関数のヘルプを表示 / Display function help
Get-Help Import-CsvFile -Full
Get-Help Find-CsvText -Examples
Get-Help Update-CsvText -Detailed
```

## 注意事項 / Notes

- デフォルトのエンコーディングはUTF8です / Default encoding is UTF8
- 元のファイルを上書きする場合は注意してください / Be careful when overwriting original files
- バックアップを取ることをお勧めします / It's recommended to make backups
