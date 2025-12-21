#Requires -Version 5.1

<#
.SYNOPSIS
    WCM モジュールの使用例デモンストレーション
.DESCRIPTION
    このスクリプトは WCM モジュールの主要な機能を実演します
#>

# モジュールをインポート
Write-Host "=== WCM (Windows CSV Manager) デモンストレーション ===" -ForegroundColor Green
Write-Host ""

Import-Module ./WCM.psd1 -Force

# デモ用ディレクトリを作成
$demoDir = Join-Path $PSScriptRoot "demo_output"
if (Test-Path $demoDir) {
    Remove-Item $demoDir -Recurse -Force
}
New-Item -ItemType Directory -Path $demoDir | Out-Null

Write-Host "1. サンプルCSVファイルの内容を表示" -ForegroundColor Cyan
Write-Host "   (Display sample CSV file content)" -ForegroundColor Gray
$data = Import-CsvFile -Path "examples/sample_data.csv"
$data | Format-Table
Write-Host ""

Write-Host "2. 'Tokyo' を検索" -ForegroundColor Cyan
Write-Host "   (Search for 'Tokyo')" -ForegroundColor Gray
$results = Find-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo"
$results | Format-Table
Write-Host ""

Write-Host "3. 'Tokyo' を '東京' に置換" -ForegroundColor Cyan
Write-Host "   (Replace 'Tokyo' with '東京')" -ForegroundColor Gray
$outputPath = Join-Path $demoDir "replaced.csv"
Update-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath $outputPath
$replaced = Import-CsvFile -Path $outputPath
$replaced | Format-Table
Write-Host ""

Write-Host "4. 'Status' 列を追加 (デフォルト値: Active)" -ForegroundColor Cyan
Write-Host "   (Add 'Status' column with default value 'Active')" -ForegroundColor Gray
$outputPath = Join-Path $demoDir "with_status.csv"
Add-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Status" -DefaultValue "Active" -OutputPath $outputPath
$withStatus = Import-CsvFile -Path $outputPath
$withStatus | Format-Table
Write-Host ""

Write-Host "5. 'City' 列名を '都市' に変更" -ForegroundColor Cyan
Write-Host "   (Rename 'City' column to '都市')" -ForegroundColor Gray
$outputPath = Join-Path $demoDir "renamed.csv"
Rename-CsvColumn -Path "examples/sample_data.csv" -OldName "City" -NewName "都市" -OutputPath $outputPath
$renamed = Import-CsvFile -Path $outputPath
$renamed | Format-Table
Write-Host ""

Write-Host "6. Tokyo の従業員のみを抽出" -ForegroundColor Cyan
Write-Host "   (Extract only Tokyo employees)" -ForegroundColor Gray
$outputPath = Join-Path $demoDir "tokyo_only.csv"
Select-CsvRows -Path "examples/sample_data.csv" -Column "City" -Value "Tokyo" -Operator "Equals" -OutputPath $outputPath
$tokyo = Import-CsvFile -Path $outputPath
$tokyo | Format-Table
Write-Host ""

Write-Host "7. 30歳以上の従業員を抽出" -ForegroundColor Cyan
Write-Host "   (Extract employees aged 30 or older)" -ForegroundColor Gray
$outputPath = Join-Path $demoDir "age_30_plus.csv"
Select-CsvRows -Path "examples/sample_data.csv" -Column "Age" -Value "30" -Operator "GreaterThan" -OutputPath $outputPath
$age30plus = Import-CsvFile -Path $outputPath
$age30plus | Format-Table
Write-Host ""

Write-Host "7. 設定の確認と変更" -ForegroundColor Cyan
Write-Host "   (Check and modify configuration)" -ForegroundColor Gray
Write-Host "現在の設定 / Current configuration:" -ForegroundColor Yellow
Get-WCMConfig | Format-Table
Write-Host ""

Write-Host "設定を変更 / Modify configuration:" -ForegroundColor Yellow
Set-WCMConfig -Config @{DefaultEncoding = "Shift-JIS"; CaseSensitive = $true}
Write-Host "設定変更後 / After configuration change:" -ForegroundColor Yellow
Get-WCMConfig | Format-Table
Write-Host ""

Write-Host "8. 高度なCSV処理 (条件付き置換、除外、重複削除)" -ForegroundColor Cyan
Write-Host "   (Advanced CSV processing with conditional replacement, exclusion, and deduplication)" -ForegroundColor Gray
$outputPath = Join-Path $demoDir "advanced_processed.csv"
Process-CsvAdvanced -InputFile "examples/sample_data.csv" -ReplaceFile "examples/rules.csv" -ExcludeFile "examples/exclude.txt" -OutputFile $outputPath
$advancedResult = Import-CsvFile -Path $outputPath
$advancedResult | Format-Table
Write-Host ""

Write-Host "9. テキストファイル処理 (除外、重複削除、ファイル分割)" -ForegroundColor Cyan
Write-Host "   (Text file processing with exclusion, deduplication, and file splitting)" -ForegroundColor Gray
$textOutputDir = Join-Path $demoDir "text_modify"
$textListFile = Join-Path $demoDir "text_file_list.txt"
Process-TextFile -InputFileA "examples/exclude_sample.txt" -InputFileB "examples/data_sample.txt" -OutputFile (Join-Path $demoDir "text_result.txt") -OutputDir $textOutputDir -ListFile $textListFile
Write-Host "処理結果 / Processing results:" -ForegroundColor Yellow
Get-Content (Join-Path $demoDir "text_result.txt")
Write-Host ""
Write-Host "生成された分割ファイル / Generated split files:" -ForegroundColor Yellow
Get-ChildItem $textOutputDir | Select-Object Name
Write-Host ""
Write-Host "ファイルリスト / File list:" -ForegroundColor Yellow
Get-Content $textListFile
Write-Host ""

Write-Host "10. テキストファイル処理 (アイテムソート、除外カウント)" -ForegroundColor Cyan
Write-Host "   (Text file processing with item sorting and exclusion counting)" -ForegroundColor Gray
Process-TextFile -InputFileA "examples/exclude_sample.txt" -InputFileB "examples/data_sample.txt" -SortItems -CountExclusions -OutputFile (Join-Path $demoDir "text_sorted_counted.txt")
Write-Host "ソート・カウント処理結果 / Sorted and counted results:" -ForegroundColor Yellow
Get-Content (Join-Path $demoDir "text_sorted_counted.txt")
Write-Host ""

Write-Host "11. テキストファイル集約 (複数ファイルの統合)" -ForegroundColor Cyan
Write-Host "   (Text file merging - combining multiple files into one)" -ForegroundColor Gray
$mergeOutputFile = Join-Path $demoDir "merged_all.txt"
Merge-TextFiles -SourcePath "examples/modify" -OutputPath $mergeOutputFile -FileFilter "*.txt"
Write-Host "集約結果 / Merged result:" -ForegroundColor Yellow
Get-Content $mergeOutputFile
Write-Host ""

Write-Host "12. 検索用語分析 (未使用用語の検出)" -ForegroundColor Cyan
Write-Host "   (Search term analysis - detecting unused terms)" -ForegroundColor Gray
$analysisOutputFile = Join-Path $demoDir "unused_terms.txt"
$result = Find-UnusedSearchTerms -SearchTermsFile "examples/sample_search_terms.txt" -TargetDirectory "examples" -OutputFile $analysisOutputFile -IncludePatterns "*.txt", "*.csv"
Write-Host "分析結果 / Analysis results:" -ForegroundColor Yellow
Write-Host "総用語数: $($result.TotalTerms)" -ForegroundColor Cyan
Write-Host "未使用用語数: $($result.UnusedCount)" -ForegroundColor Cyan
Write-Host "処理ファイル数: $($result.ProcessedFiles)" -ForegroundColor Cyan
if ($result.UnusedTerms.Count -gt 0) {
    Write-Host "未使用用語 / Unused terms:" -ForegroundColor Yellow
    $result.UnusedTerms | ForEach-Object { Write-Host "  - $_" }
}
Write-Host ""

Write-Host "13. キーワード抽出 (ユニークキーワードの収集)" -ForegroundColor Cyan
Write-Host "   (Keyword extraction - collecting unique keywords)" -ForegroundColor Gray
$keywordOutputFile = Join-Path $demoDir "unique_keywords.txt"
$result = Get-UniqueKeywords -TargetFolder "examples" -OutputFile $keywordOutputFile
Write-Host "抽出結果 / Extraction results:" -ForegroundColor Yellow
Write-Host "キーワード数: $($result.Count)" -ForegroundColor Cyan
Write-Host "上位10個のキーワード / Top 10 keywords:" -ForegroundColor Yellow
$result.Keywords | Select-Object -First 10 | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

Write-Host "14. テキストファイル処理（更新版）" -ForegroundColor Cyan
Write-Host "   (Text file processing - updated version)" -ForegroundColor Gray
$updatedOutputFile = Join-Path $demoDir "text_updated_result.txt"
Process-TextFile-Updated -InputFileA "examples/exclude_sample.txt" -InputFileB "examples/data_sample.txt" -OutputFile $updatedOutputFile
Write-Host "更新版処理結果 / Updated processing results:" -ForegroundColor Yellow
Get-Content $updatedOutputFile
Write-Host ""

Write-Host "15. 高度なCSV処理（更新版）" -ForegroundColor Cyan
Write-Host "   (Advanced CSV processing - updated version)" -ForegroundColor Gray
$csvUpdatedOutputFile = Join-Path $demoDir "csv_updated_result.csv"
Process-CsvAdvanced-Updated -InputFile "examples/sample_data.csv" -ReplaceFile "examples/rules.csv" -ExcludeFile "examples/exclude.txt" -OutputFile $csvUpdatedOutputFile
Write-Host "更新版CSV処理結果 / Updated CSV processing results:" -ForegroundColor Yellow
Get-Content $csvUpdatedOutputFile
Write-Host ""
Write-Host "16. テキストファイル処理（シンプル版）" -ForegroundColor Cyan
Write-Host "   (Text file processing - simple version)" -ForegroundColor Gray
$simpleOutputFile = Join-Path $demoDir "text_simple_result.txt"
$simpleOutputDir = Join-Path $demoDir "text_simple_modify"
$simpleListFile = Join-Path $demoDir "text_simple_file_list.txt"
Process-TextFile-Simple -InputFileA "examples/exclude_sample.txt" -InputFileB "examples/data_sample.txt" -OutputFile $simpleOutputFile -OutputDir $simpleOutputDir -ListFile $simpleListFile
Write-Host "シンプル版処理結果 / Simple processing results:" -ForegroundColor Yellow
Get-Content $simpleOutputFile
Write-Host ""
Write-Host "生成された分割ファイル / Generated split files:" -ForegroundColor Yellow
Get-ChildItem $simpleOutputDir | Select-Object Name
Write-Host ""
Write-Host "ファイルリスト / File list:" -ForegroundColor Yellow
Get-Content $simpleListFile
Write-Host ""

Write-Host "17. テキスト内容検索 (OR/AND条件)" -ForegroundColor Cyan
Write-Host "   (Text content search with OR/AND conditions)" -ForegroundColor Gray
$contentSearchOutputFile = Join-Path $demoDir "content_search_results.csv"
Find-TextContent -SearchFolder "examples" -KeywordFile "examples/search_keywords.txt" -OutputFile $contentSearchOutputFile
Write-Host "検索結果 / Search results:" -ForegroundColor Yellow
if (Test-Path $contentSearchOutputFile) {
    Get-Content $contentSearchOutputFile | Select-Object -First 5
    $resultCount = (Get-Content $contentSearchOutputFile | Measure-Object).Count - 1  # ヘッダー除く
    Write-Host "総結果数: $resultCount 件" -ForegroundColor Cyan
} else {
    Write-Host "検索結果が見つかりませんでした。" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "18. テキスト内容不一致検索 (OR/AND条件)" -ForegroundColor Cyan
Write-Host "   (Text content mismatch search with OR/AND conditions)" -ForegroundColor Gray
$contentMismatchOutputFile = Join-Path $demoDir "content_mismatch_results.csv"
Find-TextContent-Mismatch -SearchFolder "examples" -KeywordFile "examples/search_keywords.txt" -OutputFile $contentMismatchOutputFile
Write-Host "不一致検索結果 / Mismatch search results:" -ForegroundColor Yellow
if (Test-Path $contentMismatchOutputFile) {
    Get-Content $contentMismatchOutputFile | Select-Object -First 5
    $resultCount = (Get-Content $contentMismatchOutputFile | Measure-Object).Count - 1  # ヘッダー除く
    Write-Host "総結果数: $resultCount 件" -ForegroundColor Cyan
} else {
    Write-Host "不一致検索結果が見つかりませんでした。" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== デモ完了 ===" -ForegroundColor Green
Write-Host "生成されたファイル: $demoDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "詳細な使用方法は examples/USAGE.md を参照してください" -ForegroundColor Yellow
Write-Host "For detailed usage, see examples/USAGE.md" -ForegroundColor Gray
