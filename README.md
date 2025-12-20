# WCM (Windows CSV Manager)

PowerShell で CSV ファイルを中心に text を編集操作する

---

## 概要 / Overview

**日本語:**
WCM (Windows CSV Manager) は、PowerShell で CSV ファイルのテキスト編集操作を簡単に行うためのモジュールです。検索、置換、列操作、行フィルタリングなど、CSV データの編集に必要な機能を提供します。

**English:**
WCM (Windows CSV Manager) is a PowerShell module for easy text editing operations on CSV files. It provides essential features for CSV data editing including search, replace, column manipulation, and row filtering.

## 機能 / Features

- ✅ CSV ファイルの読み込み・保存 / CSV file import/export
- ✅ テキスト検索 (全列または特定列) / Text search (all columns or specific column)
- ✅ テキスト置換 (大文字小文字の区別対応) / Text replace (case-sensitive support)
- ✅ 列の追加・削除・名前変更 / Add, remove, rename columns
- ✅ 行のフィルタリング (様々な条件) / Row filtering (various conditions)
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
- **`Update-CsvText`** - テキストを置換する / Replace text

### 列操作 / Column Operations

- **`Add-CsvColumn`** - 列を追加する / Add column
- **`Remove-CsvColumn`** - 列を削除する / Remove column
- **`Rename-CsvColumn`** - 列名を変更する / Rename column

### 行操作 / Row Operations

- **`Select-CsvRows`** - 行をフィルタする / Filter rows

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

If you encounter any issues, please report them on GitHub Issues.