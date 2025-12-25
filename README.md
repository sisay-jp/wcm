# WCM (Windows CSV Manager)

PowerShell で CSV ファイルを中心に text を編集操作する

---

## 概要 / Overview

**日本語:**
WCM (Windows CSV Manager) は、PowerShell で CSV ファイルのテキスト編集操作を簡単に行うためのモジュールです。検索、置換、列操作、行フィルタリングなど、CSV データの編集に必要な機能を提供します。

**English:**
WCM (Windows CSV Manager) is a PowerShell module for easy text editing operations on CSV files. It provides essential features for CSV data editing including search, replace, column manipulation, and row filtering.

## プロジェクト構造 / Project Structure

```
WCM/
├── WCM.psm1              # メインのモジュールファイル
├── WCM.psd1              # モジュールマニフェスト
├── Public/               # パブリック関数
│   ├── Import-CsvFile.ps1
│   ├── Export-CsvFile.ps1
│   ├── Find-CsvText.ps1
│   ├── Update-CsvText.ps1
│   ├── Add-CsvColumn.ps1
│   ├── Remove-CsvColumn.ps1
│   ├── Rename-CsvColumn.ps1
│   ├── Select-CsvRows.ps1
│   ├── Get-WCMConfig.ps1
│   ├── Set-WCMConfig.ps1
│   ├── Process-CsvAdvanced.ps1
│   ├── Process-TextFile.ps1
│   ├── Merge-TextFiles.ps1
│   ├── Find-UnusedSearchTerms.ps1
│   └── Get-UniqueKeywords.ps1
├── Private/              # プライベート関数（将来の拡張用）
├── examples/             # 使用例とサンプルデータ
└── Demo-WCM.ps1          # デモンストレーションスクリプト
```

## 機能 / Features

- ✅ CSV ファイルの読み込み・保存 / CSV file import/export
- ✅ テキスト検索 (全列または特定列) / Text search (all columns or specific column)
- ✅ テキスト内容検索 (OR/AND条件) / Text content search (OR/AND conditions)
- ✅ テキスト内容不一致検索 (OR/AND条件) / Text content mismatch search (OR/AND conditions)
- ✅ テキスト内容検索とファイル複製 (OR/AND条件) / Text content search with file copy (OR/AND conditions)
- ✅ テキスト置換 (大文字小文字の区別対応) / Text replace (case-sensitive support)
- ✅ 列の追加・削除・名前変更 / Add, remove, rename columns
- ✅ 行のフィルタリング (様々な条件) / Row filtering (various conditions)
- ✅ 高度な処理 (条件付き置換、除外、重複削除) / Advanced processing (conditional replacement, exclusion, deduplication)
- ✅ 高度な処理（更新版） / Advanced processing (updated version)
- ✅ テキストファイル処理 (除外、重複削除、ファイル分割) / Text file processing (exclusion, deduplication, file splitting)
- ✅ テキストファイル処理（更新版） / Text file processing (updated version)
- ✅ テキストファイル処理（シンプル版） / Text file processing (simple version)
- ✅ テキストファイル集約 (複数ファイルの統合) / Text file merging (combining multiple files)
- ✅ 検索用語分析 (未使用用語の検出) / Search term analysis (detecting unused terms)
- ✅ キーワード抽出 (ユニークキーワードの収集) / Keyword extraction (collecting unique keywords)
- ✅ 設定管理 (エンコーディング、バックアップなど) / Configuration management (encoding, backup, etc.)
- ✅ 日本語対応 / Japanese language support
- ✅ UTF8 エンコーディング対応 / UTF8 encoding support

## インストール / Installation

```powershell
# リポジトリをクローン / Clone the repository
git clone https://github.com/sisay-jp/wcm.git
cd wcm

# モジュールをインポート / Import the module
Import-Module ./WCM.psd1
```

## クイックスタート / Quick Start

```powershell
# モジュールをインポート
Import-Module ./WCM.psd1

# CSV ファイルを読み込む
$data = Import-CsvFile -Path "examples/sample_data.csv"
$data | Format-Table

# テキストを検索
Find-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo"

# テキストを置換
Update-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath "output.csv"

# 列を追加
Add-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Status" -DefaultValue "Active" -OutputPath "output.csv"

# 行をフィルタ
Select-CsvRows -Path "examples/sample_data.csv" -Column "City" -Value "Tokyo" -Operator "Equals" -OutputPath "tokyo_only.csv"
```

## 利用可能な関数 / Available Functions

### データ入出力 / Data I/O

- **`Import-CsvFile`** - CSV ファイルを読み込む / Read CSV file
- **`Export-CsvFile`** - CSV ファイルに保存する / Save to CSV file

### テキスト操作 / Text Operations

- **`Find-CsvText`** - テキストを検索する / Search for text
- **`Find-TextContent`** - テキストファイルの内容をキーワードで検索する / Search text file content by keywords
- **`Find-TextContent-Mismatch`** - テキストファイルの内容をキーワードで不一致検索する / Search text file content for mismatches by keywords
- **`Find-TextContent-WithCopy`** - テキストファイルの内容をキーワードで検索し、一致ファイルを複製する / Search text file content by keywords and copy matched files
- **`Update-CsvText`** - テキストを置換する / Replace text

### 列操作 / Column Operations

- **`Add-CsvColumn`** - 列を追加する / Add column
- **`Remove-CsvColumn`** - 列を削除する / Remove column
- **`Rename-CsvColumn`** - 列名を変更する / Rename column

### 行操作 / Row Operations

- **`Select-CsvRows`** - 行をフィルタする / Filter rows

### 高度な処理 / Advanced Processing

- **`Process-CsvAdvanced`** - 条件付き置換、除外、重複削除を実行 / Perform conditional replacement, exclusion, and deduplication
- **`Process-CsvAdvanced-Updated`** - シンプル置換、除外、重複削除を実行 / Perform simple replacement, exclusion, and deduplication
- **`Process-TextFile`** - テキストファイルの除外、重複削除、ファイル分割を実行 / Perform text file exclusion, deduplication, and file splitting
- **`Process-TextFile-Updated`** - テキストファイルを処理して除外と重複削除を行う（更新版） / Process text files for exclusion and deduplication (updated version)
- **`Process-TextFile-Simple`** - テキストファイルをシンプルに処理する（除外、重複削除、ファイル分割） / Perform simple text file processing (exclusion, deduplication, file splitting)
- **`Merge-TextFiles`** - 指定ディレクトリ内のテキストファイルを1つに集約 / Merge multiple text files from a directory into one
- **`Find-UnusedSearchTerms`** - 指定フォルダ内で使用されていない検索用語を検出 / Detect search terms not used in specified folder
- **`Get-UniqueKeywords`** - 指定フォルダ内のテキストファイルからユニークなキーワードを抽出 / Extract unique keywords from text files in specified folder

### 設定管理 / Configuration

- **`Get-WCMConfig`** - 現在の設定を取得する / Get current configuration
- **`Set-WCMConfig`** - 設定を変更する / Update configuration

## 使用例 / Usage Examples

詳しい使用例は [examples/USAGE.md](examples/USAGE.md) を参照してください。

For detailed usage examples, see [examples/USAGE.md](examples/USAGE.md).

### 基本的な例 / Basic Examples

#### 1. テキスト検索 / Text Search

```powershell
# 全列から "Tokyo" を検索
Find-CsvText -Path "data.csv" -SearchText "Tokyo"

# 特定の列で検索
Find-CsvText -Path "data.csv" -SearchText "Tokyo" -Column "City"
```

#### 2. テキスト置換 / Text Replace

```powershell
# "Tokyo" を "東京" に置換
Update-CsvText -Path "data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath "output.csv"
```

#### 3. 列の操作 / Column Operations

```powershell
# 列を追加
Add-CsvColumn -Path "data.csv" -ColumnName "Status" -DefaultValue "Active" -OutputPath "output.csv"

# 列を削除
Remove-CsvColumn -Path "data.csv" -ColumnName "Age" -OutputPath "output.csv"

# 列名を変更
Rename-CsvColumn -Path "data.csv" -OldName "City" -NewName "都市" -OutputPath "output.csv"
```

#### 4. 行のフィルタリング / Row Filtering

```powershell
# City が "Tokyo" の行を抽出
Select-CsvRows -Path "data.csv" -Column "City" -Value "Tokyo" -Operator "Equals" -OutputPath "tokyo.csv"

# Age が 30 より大きい行を抽出
Select-CsvRows -Path "data.csv" -Column "Age" -Value "30" -Operator "GreaterThan" -OutputPath "over30.csv"
```

#### 5. 高度な処理 / Advanced Processing

```powershell
# CSV の高度な処理（条件付き置換、除外、重複削除）
Process-CsvAdvanced -Path "data.csv" -OutputPath "processed.csv" -ExcludePatterns @("test", "temp") -RemoveDuplicates

# テキストファイルの処理（除外、重複削除、ファイル分割）
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -OutputFile "result.txt" -OutputDir "modify" -ListFile "file_list.txt"

# テキストファイルの処理（アイテムソート、除外カウント付き）
Process-TextFile -InputFileA "exclude.txt" -InputFileB "data.txt" -SortItems -CountExclusions

# テキストファイルの集約（複数ファイルを1つに統合）
Merge-TextFiles -SourcePath "C:\Data\Logs" -OutputPath "C:\Merged\all_logs.txt" -FileFilter "*.log"

# 検索用語の使用状況分析（未使用用語の検出）
Find-UnusedSearchTerms -SearchTermsFile "terms.txt" -TargetDirectory "C:\Project" -OutputFile "unused_terms.txt"

# キーワード抽出（ユニークキーワードの収集）
Get-UniqueKeywords -TargetFolder "C:\Data" -OutputFile "unique_keywords.txt"
```

## ヘルプの表示 / Getting Help

各関数の詳細なヘルプを表示できます:

```powershell
Get-Help Import-CsvFile -Full
Get-Help Find-CsvText -Examples
Get-Help Update-CsvText -Detailed
```

## 要件 / Requirements

- PowerShell 5.1 以降 / PowerShell 5.1 or later
- Windows, Linux, macOS (PowerShell Core)

## ライセンス / License

このプロジェクトはオープンソースです。

This project is open source.

## 貢献 / Contributing

プルリクエストを歓迎します！

Pull requests are welcome!

## サポート / Support

問題が発生した場合は、GitHub の Issues でお知らせください。

If you encounter any issues, please report them on GitHub Issues."test" 
"test2" 
