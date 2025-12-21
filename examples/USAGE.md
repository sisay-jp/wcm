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

### 0. 設定ファイルでまとめて実行 / Run with config file

```powershell
# 実行設定ファイル（例: examples/wcm.run.psd1）に処理内容をまとめて、メイン関数を呼び出す
Invoke-WCM -ConfigPath "examples/wcm.run.psd1"

# Name を付けている場合は、特定タスクだけ実行も可能
Invoke-WCM -ConfigPath "examples/wcm.run.psd1" -TaskName "csv_advanced"
```

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

### 2.5. テキスト内容検索 / Text Content Search

```powershell
# テキストファイルの内容をキーワードで検索 / Search text file content by keywords
Find-TextContent -SearchFolder "examples" -KeywordFile "search_keywords.txt" -OutputFile "search_results.csv"

# キーワードファイル (search_keywords.txt) の例 / Example of keyword file:
# Tokyo
# Osaka,Kyoto

# 出力結果 (search_results.csv) の例 / Example of output:
# MatchedPattern(OR/AND),LineNumber,FilePath,Content
# "Tokyo",2,"C:\path\to\file.txt","Name,Age,City"
```

### 特徴 / Features

- OR/AND条件のキーワード検索 / OR/AND conditional keyword search
- フォルダ内再帰検索 / Recursive folder search
- 行内要素完全一致 / Exact match within line elements
- CSV形式出力 / CSV format output
- UTF8エンコーディング対応 / UTF8 encoding support

### 2.6. テキスト内容不一致検索 / Text Content Mismatch Search

```powershell
# テキストファイルの内容をキーワードで不一致検索 / Search text file content for mismatches by keywords
Find-TextContent-Mismatch -SearchFolder "examples" -KeywordFile "search_keywords.txt" -OutputFile "mismatch_results.csv"

# キーワードファイル (search_keywords.txt) の例 / Example of keyword file:
# Tokyo
# Osaka,Kyoto

# 出力結果 (mismatch_results.csv) の例 / Example of output:
# FilePath,LineNumber,Content,Status
# "C:\path\to\file.txt",3,"Name,Age,City","NONE OF PATTERNS MATCHED"
```

### 特徴 / Features

- OR/AND条件のキーワード不一致検索 / OR/AND conditional keyword mismatch search
- フォルダ内再帰検索 / Recursive folder search
- 行内要素完全一致 / Exact match within line elements
- CSV形式出力 / CSV format output
- UTF8エンコーディング対応 / UTF8 encoding support

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

## 高度なCSV処理 / Advanced CSV Processing

### 条件付き置換と除外処理 / Conditional replacement and exclusion

```powershell
# 高度な処理を実行 / Perform advanced processing
Process-CsvAdvanced -InputFile "examples/sample_data.csv" -ReplaceFile "rules.csv" -ExcludeFile "exclude.txt" -OutputFile "processed.csv"

# ルールファイル (rules.csv) の例 / Example of rules file:
# Condition,ReplacePair
# Tokyo,Osaka->東京,大阪
# Sales,Marketing->営業,マーケティング

# 除外ファイル (exclude.txt) の例 / Example of exclude file:
# 不要ワード1,不要ワード2,不要ワード3
```

### コンソール出力 / Console output

```powershell
# 結果をコンソールに出力 / Output results to console
$result = Process-CsvAdvanced -InputFile "examples/sample_data.csv" -ReplaceFile "rules.csv"
$result | Format-Table
```

## 高度なCSV処理（更新版） / Advanced CSV Processing (Updated)

### シンプル置換と除外処理 / Simple replacement and exclusion

```powershell
# シンプルな高度な処理を実行 / Perform simple advanced processing
Process-CsvAdvanced-Updated -InputFile "examples/sample_data.csv" -ReplaceFile "rules_simple.csv" -ExcludeFile "exclude.txt" -OutputFile "processed_simple.csv"

# 置換ファイル (rules_simple.csv) の例 / Example of simple rules file:
# Old,New
# Tokyo,東京
# Osaka,大阪
# Sales,営業

# 除外ファイル (exclude.txt) の例 / Example of exclude file:
# 不要ワード1
# 不要ワード2
# 不要ワード3
```

### 特徴 / Features

- シンプルな置換ルール（Old->New） / Simple replacement rules (Old->New)
- 除外ワードリスト / Exclusion word list
- 行内重複削除（順序維持） / Deduplication within lines (order preserved)
- 行間重複削除（ソート形式で比較） / Deduplication between lines (compared in sorted form)
- 出力はソート前の順序を維持 / Output maintains pre-sort order
- UTF8エンコーディング対応 / UTF8 encoding support

## テキストファイル処理 / Text File Processing

### 除外と重複削除 / Exclusion and deduplication

```powershell
# テキストファイルの処理を実行 / Perform text file processing
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt" -OutputDir "modify" -ListFile "file_list.txt"

# 除外ファイル (exclude.txt) の例 / Example of exclude file:
# 不要ワード1,不要ワード2,不要ワード3

# 処理対象ファイル (data.txt) の例 / Example of data file:
# 項目1,項目2,項目3
# 項目4,項目5,項目6
# 項目1,項目7,項目8
```

### 部分的な処理 / Partial processing

```powershell
# 出力ファイルのみ生成 / Generate output file only
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt"

# ファイル分割のみ実行 / Perform file splitting only
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputDir "modify"

# ファイルリストのみ生成 / Generate file list only
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputDir "modify" -ListFile "file_list.txt"

# アイテムをソートして処理 / Process with item sorting
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -SortItems

# 除外カウントを表示 / Display exclusion counts
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -CountExclusions

# ソートとカウントを組み合わせ / Combine sorting and counting
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -SortItems -CountExclusions -ExcludePrefix "<"
```

### コンソール出力 / Console output

```powershell
# 結果をコンソールに出力 / Output results to console
$result = Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt"
$result | Format-Table
```

## テキストファイル処理（更新版） / Text File Processing (Updated)

### 基本的な処理 / Basic processing

```powershell
# テキストファイルを処理して除外と重複削除を行う / Process text file for exclusion and deduplication
Process-TextFile-Updated -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt"

# 除外ファイル (exclude.txt) の例 / Example of exclude file:
# 不要ワード1,不要ワード2,不要ワード3

# 処理対象ファイル (data.txt) の例 / Example of data file:
# 項目1,項目2,項目3
# 項目4,項目5,項目6
# 項目1,項目7,項目8
```

### 特徴 / Features

- 除外ワードリストに基づくフィルタリング / Filtering based on exclusion word list
- 重複行の排除（ソート形式で比較） / Deduplication of rows (compared in sorted form)
- 出力はソート前の形式を維持 / Output maintains pre-sort format
- 除外カウントの表示（<で始まるものは除外） / Display exclusion counts (excluding those starting with <)
- UTF8エンコーディング対応 / UTF8 encoding support

## テキストファイル処理（シンプル版） / Text File Processing (Simple)

### 基本的な処理 / Basic processing

```powershell
# テキストファイルをシンプルに処理 / Perform simple text file processing
Process-TextFile-Simple -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt" -OutputDir "modify" -ListFile "file_list.txt"

# 除外ファイル (exclude.txt) の例 / Example of exclude file:
# 不要ワード1,不要ワード2,不要ワード3

# 処理対象ファイル (data.txt) の例 / Example of data file:
# 項目1,項目2,項目3
# 項目4,項目5,項目6
# 項目1,項目7,項目8
```

### 部分的な処理 / Partial processing

```powershell
# 出力ファイルのみ生成 / Generate output file only
Process-TextFile-Simple -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt"

# ファイル分割のみ実行 / Perform file splitting only
Process-TextFile-Simple -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputDir "modify"

# ファイルリストのみ生成 / Generate file list only
Process-TextFile-Simple -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputDir "modify" -ListFile "file_list.txt"
```

### 特徴 / Features

- 除外と重複削除 / Exclusion and deduplication
- ファイル分割保存 / File splitting and saving
- ファイルリスト生成 / File list generation
- UTF8エンコーディング対応 / UTF8 encoding support

## テキストファイル集約 / Text File Merging

### 基本的な集約 / Basic merging

```powershell
# 指定ディレクトリ内の全テキストファイルを1つに集約 / Merge all text files in a directory
Merge-TextFiles -SourcePath "C:\Data\Logs" -OutputPath "C:\Merged\all_logs.txt"

# ログファイルのみを集約 / Merge only log files
Merge-TextFiles -SourcePath "C:\Data" -OutputPath "C:\Merged\all_logs.txt" -FileFilter "*.log"

# Shift-JISエンコーディングで集約 / Merge with Shift-JIS encoding
Merge-TextFiles -SourcePath "C:\Data" -OutputPath "C:\Merged\all_data.txt" -Encoding "Shift-JIS"
```

### 再帰的な検索 / Recursive search

```powershell
# サブフォルダを含むすべてのテキストファイルを集約 / Merge all text files including subfolders
Merge-TextFiles -SourcePath "C:\Project\Source" -OutputPath "C:\Merged\all_source.txt" -FileFilter "*.txt"
```

## 検索用語分析 / Search Term Analysis

### 基本的な分析 / Basic analysis

```powershell
# 指定フォルダ内で使用されていない検索用語を検出 / Detect search terms not used in specified folder
Find-UnusedSearchTerms -SearchTermsFile "search_terms.txt" -TargetDirectory "C:\Project" -OutputFile "unused_terms.txt"

# 検索用語ファイル (search_terms.txt) の例 / Example of search terms file:
# term1
# term2
# term3
```

### フィルタリング付き分析 / Analysis with filtering

```powershell
# 特定のファイルタイプのみを対象 / Analyze only specific file types
Find-UnusedSearchTerms -SearchTermsFile "terms.txt" -TargetDirectory "C:\Data" -IncludePatterns "*.txt", "*.md" -OutputFile "unused.txt"

# 特定のファイルタイプを除外 / Exclude specific file types
Find-UnusedSearchTerms -SearchTermsFile "terms.txt" -TargetDirectory "C:\Data" -ExcludePatterns "*.log", "*.tmp" -OutputFile "unused.txt"
```

### コンソール出力 / Console output

```powershell
# 結果をコンソールに出力 / Output results to console
$result = Find-UnusedSearchTerms -SearchTermsFile "terms.txt" -TargetDirectory "C:\Project"
$result.UnusedTerms
Write-Host "未使用用語数: $($result.UnusedCount) / $($result.TotalTerms)"
```

## キーワード抽出 / Keyword Extraction

### 基本的な抽出 / Basic extraction

```powershell
# 指定フォルダ内のテキストファイルからユニークなキーワードを抽出 / Extract unique keywords from text files in specified folder
Get-UniqueKeywords -TargetFolder "C:\Data" -OutputFile "unique_keywords.txt"

# CSVファイルからキーワードを抽出 / Extract keywords from CSV files
Get-UniqueKeywords -TargetFolder "C:\Project" -FileFilter "*.csv" -OutputFile "csv_keywords.txt"
```

### コンソール出力 / Console output

```powershell
# 結果をコンソールに出力 / Output results to console
$result = Get-UniqueKeywords -TargetFolder "C:\Data"
$result.Keywords
Write-Host "抽出キーワード数: $($result.Count)"
```

## 設定管理 / Configuration Management

### 現在の設定を確認 / Check current configuration

```powershell
# 現在の設定を表示 / Display current configuration
Get-WCMConfig
```

### 設定を変更 / Change configuration

```powershell
# エンコーディングをShift-JISに変更 / Change encoding to Shift-JIS
Set-WCMConfig -Config @{DefaultEncoding = "Shift-JIS"}

# バックアップを無効化 / Disable backup
Set-WCMConfig -Config @{BackupFiles = $false}

# 大文字小文字を区別する検索に変更 / Enable case-sensitive search
Set-WCMConfig -Config @{CaseSensitive = $true}

# 複数の設定を一度に変更 / Change multiple settings at once
Set-WCMConfig -Config @{
    DefaultEncoding = "UTF8"
    BackupFiles = $true
    CaseSensitive = $false
}
```

## 注意事項 / Notes

- デフォルトのエンコーディングはUTF8です / Default encoding is UTF8
- 元のファイルを上書きする場合は注意してください / Be careful when overwriting original files
- バックアップを取ることをお勧めします / It's recommended to make backups
