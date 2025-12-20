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

Write-Host "=== デモ完了 ===" -ForegroundColor Green
Write-Host "生成されたファイル: $demoDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "詳細な使用方法は examples/USAGE.md を参照してください" -ForegroundColor Yellow
Write-Host "For detailed usage, see examples/USAGE.md" -ForegroundColor Gray
