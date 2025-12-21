#Requires -Version 5.1

<#
.SYNOPSIS
    WCM モジュールの基本機能をテストするスクリプト
.DESCRIPTION
    このスクリプトは WCM モジュールの主要な機能をテストします
#>

# モジュールをインポート
Import-Module ./WCM.psd1 -Force

Write-Host "=== WCM モジュールテスト開始 ===" -ForegroundColor Green
Write-Host ""

# テスト用の一時ディレクトリを作成
$testDir = Join-Path $PSScriptRoot "test_output"
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir | Out-Null

try {
    # テスト 1: CSV ファイルの読み込み
    Write-Host "テスト 1: CSV ファイルの読み込み" -ForegroundColor Cyan
    $data = Import-CsvFile -Path "examples/sample_data.csv"
    Write-Host "  ✓ 読み込み成功: $($data.Count) 行" -ForegroundColor Green
    $data | Format-Table | Out-String | Write-Host
    
    # テスト 2: テキスト検索 (全列)
    Write-Host "テスト 2: テキスト検索 (全列から 'Tokyo' を検索)" -ForegroundColor Cyan
    $results = Find-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo"
    Write-Host "  ✓ 検索結果: $($results.Count) 件" -ForegroundColor Green
    $results | Format-Table | Out-String | Write-Host
    
    # テスト 3: テキスト検索 (特定列)
    Write-Host "テスト 3: テキスト検索 (City 列から 'Tokyo' を検索)" -ForegroundColor Cyan
    $results = Find-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -Column "City"
    Write-Host "  ✓ 検索結果: $($results.Count) 件" -ForegroundColor Green
    $results | Format-Table | Out-String | Write-Host
    
    # テスト 4: テキスト置換
    Write-Host "テスト 4: テキスト置換 ('Tokyo' → '東京')" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "replaced.csv"
    Update-CsvText -Path "examples/sample_data.csv" -SearchText "Tokyo" -ReplaceText "東京" -OutputPath $outputPath
    $replaced = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ 置換完了: $outputPath" -ForegroundColor Green
    $replaced | Format-Table | Out-String | Write-Host
    
    # テスト 5: 列の追加
    Write-Host "テスト 5: 列の追加 (Status 列を追加)" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "with_status.csv"
    Add-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Status" -DefaultValue "Active" -OutputPath $outputPath
    $withColumn = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ 列追加完了: $outputPath" -ForegroundColor Green
    $withColumn | Format-Table | Out-String | Write-Host
    
    # テスト 6: 列の削除
    Write-Host "テスト 6: 列の削除 (Age 列を削除)" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "without_age.csv"
    Remove-CsvColumn -Path "examples/sample_data.csv" -ColumnName "Age" -OutputPath $outputPath
    $withoutColumn = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ 列削除完了: $outputPath" -ForegroundColor Green
    $withoutColumn | Format-Table | Out-String | Write-Host
    
    # テスト 7: 列名の変更
    Write-Host "テスト 7: 列名の変更 (City → 都市)" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "renamed.csv"
    Rename-CsvColumn -Path "examples/sample_data.csv" -OldName "City" -NewName "都市" -OutputPath $outputPath
    $renamed = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ 列名変更完了: $outputPath" -ForegroundColor Green
    $renamed | Format-Table | Out-String | Write-Host
    
    # テスト 8: 行のフィルタリング (Equals)
    Write-Host "テスト 8: 行のフィルタリング (City = 'Tokyo')" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "tokyo_only.csv"
    Select-CsvRows -Path "examples/sample_data.csv" -Column "City" -Value "Tokyo" -Operator "Equals" -OutputPath $outputPath
    $filtered = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ フィルタリング完了: $($filtered.Count) 行" -ForegroundColor Green
    $filtered | Format-Table | Out-String | Write-Host
    
    # テスト 9: 行のフィルタリング (GreaterThan)
    Write-Host "テスト 9: 行のフィルタリング (Age > 30)" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "age_over_30.csv"
    Select-CsvRows -Path "examples/sample_data.csv" -Column "Age" -Value "30" -Operator "GreaterThan" -OutputPath $outputPath
    $filtered = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ フィルタリング完了: $($filtered.Count) 行" -ForegroundColor Green
    $filtered | Format-Table | Out-String | Write-Host
    
    # テスト 10: 行のフィルタリング (Contains)
    Write-Host "テスト 10: 行のフィルタリング (Department に 'Sales' を含む)" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "sales_dept.csv"
    Select-CsvRows -Path "examples/sample_data.csv" -Column "Department" -Value "Sales" -Operator "Contains" -OutputPath $outputPath
    $filtered = Import-CsvFile -Path $outputPath
    Write-Host "  ✓ フィルタリング完了: $($filtered.Count) 行" -ForegroundColor Green
    $filtered | Format-Table | Out-String | Write-Host

    # テスト 11: テキスト内容不一致検索
    Write-Host "テスト 11: テキスト内容不一致検索 (OR/AND条件)" -ForegroundColor Cyan
    $outputPath = Join-Path $testDir "content_mismatch_results.csv"
    Find-TextContent-Mismatch -SearchFolder "examples" -KeywordFile "examples/search_keywords.txt" -OutputFile $outputPath
    if (Test-Path $outputPath) {
        $resultCount = (Get-Content $outputPath | Measure-Object).Count - 1  # ヘッダー除く
        Write-Host "  ✓ 不一致検索完了: $resultCount 件" -ForegroundColor Green
        Get-Content $outputPath | Select-Object -First 3 | Out-String | Write-Host
    } else {
        Write-Host "  ✓ 不一致検索完了: 結果なし" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== すべてのテストが成功しました！ ===" -ForegroundColor Green
    Write-Host "生成されたファイル: $testDir" -ForegroundColor Yellow
    
} catch {
    Write-Host ""
    Write-Host "=== テスト失敗 ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
