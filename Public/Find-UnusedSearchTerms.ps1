# 検索用語使用状況分析関数 / Search Term Usage Analysis Function
function Find-UnusedSearchTerms {
    <#
    .SYNOPSIS
        指定フォルダ内のファイルで使用されていない検索用語を検出する
    .DESCRIPTION
        検索文字列一覧ファイルから用語を読み込み、指定フォルダ内の全ファイルを再帰的に検索し、
        使用されていない用語をリストアップします
    .PARAMETER SearchTermsFile
        検索用語が記載されたファイルのパス
    .PARAMETER TargetDirectory
        検索対象のフォルダパス
    .PARAMETER OutputFile
        未使用用語の出力ファイルパス（オプション）
    .PARAMETER IncludePatterns
        検索対象とするファイルパターン（例: *.txt, *.csv）（オプション、デフォルト: 全てのファイル）
    .PARAMETER ExcludePatterns
        検索対象から除外するファイルパターン（例: *.log, *.tmp）（オプション）
    .EXAMPLE
        Find-UnusedSearchTerms -SearchTermsFile "terms.txt" -TargetDirectory "C:\Data" -OutputFile "unused.txt"
    .EXAMPLE
        Find-UnusedSearchTerms -SearchTermsFile "terms.txt" -TargetDirectory "C:\Data" -IncludePatterns "*.txt", "*.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchTermsFile,

        [Parameter(Mandatory=$true)]
        [string]$TargetDirectory,

        [Parameter(Mandatory=$false)]
        [string]$OutputFile,

        [Parameter(Mandatory=$false)]
        [string[]]$IncludePatterns,

        [Parameter(Mandatory=$false)]
        [string[]]$ExcludePatterns
    )

    $enc = $script:WCMConfig.DefaultEncoding

    # ファイル存在チェック
    if (-not (Test-Path $SearchTermsFile)) {
        Write-Error "Search terms file not found: $SearchTermsFile"
        return
    }
    if (-not (Test-Path $TargetDirectory)) {
        Write-Error "Target directory not found: $TargetDirectory"
        return
    }

    # 検索文字列を読み込む
    $SearchTerms = Get-Content -Path $SearchTermsFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    if ($SearchTerms.Count -eq 0) {
        Write-Warning "No search terms found in file: $SearchTermsFile"
        return
    }

    Write-Host "検索用語数: $($SearchTerms.Count)" -ForegroundColor Cyan
    Write-Host "検索対象フォルダ: $TargetDirectory" -ForegroundColor Cyan
    Write-Host "--------------------"

    # 未使用の文字列を保持するハッシュセット
    $UnusedTerms = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($term in $SearchTerms) {
        [void]$UnusedTerms.Add($term)
    }

    # ファイル検索の準備
    $files = Get-ChildItem -Path $TargetDirectory -Recurse -File

    # インクルードパターンの適用
    if ($IncludePatterns) {
        $files = $files | Where-Object {
            $fileName = $_.Name
            $includeMatch = $false
            foreach ($pattern in $IncludePatterns) {
                if ($fileName -like $pattern) {
                    $includeMatch = $true
                    break
                }
            }
            $includeMatch
        }
    }

    # エクスクルードパターンの適用
    if ($ExcludePatterns) {
        $files = $files | Where-Object {
            $fileName = $_.Name
            $excludeMatch = $false
            foreach ($pattern in $ExcludePatterns) {
                if ($fileName -like $pattern) {
                    $excludeMatch = $true
                    break
                }
            }
            -not $excludeMatch
        }
    }

    $processedFiles = 0
    $skippedFiles = 0

    # 各ファイルを処理
    foreach ($file in $files) {
        $FilePath = $file.FullName
        Write-Host "処理中: $FilePath"

        try {
            # ファイル内容を取得
            $FileContent = Get-Content -Path $FilePath -Raw -ErrorAction Stop

            # 検索文字列を1つずつチェック
            foreach ($Term in $SearchTerms) {
                if ($FileContent -match [regex]::Escape($Term)) {
                    # 使用されている場合、UnusedTermsから削除
                    [void]$UnusedTerms.Remove($Term)
                }
            }

            $processedFiles++
        } catch {
            # ファイルが読み取れない場合はスキップ
            Write-Host "Skipped file: $FilePath ($($_.Exception.Message))" -ForegroundColor Yellow
            $skippedFiles++
        }
    }

    Write-Host "--------------------"
    Write-Host "処理完了ファイル数: $processedFiles" -ForegroundColor Green
    if ($skippedFiles -gt 0) {
        Write-Host "スキップファイル数: $skippedFiles" -ForegroundColor Yellow
    }
    Write-Host "未使用用語数: $($UnusedTerms.Count)" -ForegroundColor Cyan

    # 未使用の文字列を配列に変換
    $unusedTermsArray = [string[]]$UnusedTerms

    # 出力ファイルが指定されている場合
    if ($OutputFile) {
        $unusedTermsArray | Set-Content -Path $OutputFile -Encoding $enc
        Write-Host "未使用の文字列は $OutputFile に保存されました。" -ForegroundColor Green
    }

    # 結果を返す
    [PSCustomObject]@{
        TotalTerms = $SearchTerms.Count
        UnusedTerms = $unusedTermsArray
        ProcessedFiles = $processedFiles
        SkippedFiles = $skippedFiles
        UnusedCount = $UnusedTerms.Count
    }
}