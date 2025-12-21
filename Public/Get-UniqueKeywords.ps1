# ユニークキーワード抽出関数 / Unique Keyword Extraction Function
function Get-UniqueKeywords {
    <#
    .SYNOPSIS
        指定フォルダ内のテキストファイルからユニークなキーワードを抽出する
    .DESCRIPTION
        指定されたフォルダ内の全テキストファイルを再帰的に検索し、カンマ区切りのキーワードを抽出し、
        重複を除去してソートしたリストを返します
    .PARAMETER TargetFolder
        検索対象のフォルダパス
    .PARAMETER OutputFile
        結果の出力ファイルパス（オプション）
    .PARAMETER FileFilter
        検索対象とするファイルパターン（デフォルト: *.txt）
    .EXAMPLE
        Get-UniqueKeywords -TargetFolder "C:\Data" -OutputFile "keywords.txt"
    .EXAMPLE
        Get-UniqueKeywords -TargetFolder "C:\Project" -FileFilter "*.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetFolder,

        [Parameter(Mandatory=$false)]
        [string]$OutputFile,

        [Parameter(Mandatory=$false)]
        [string]$FileFilter = "*.txt"
    )

    $enc = $script:WCMConfig.DefaultEncoding

    # フォルダ存在チェック
    if (-not (Test-Path $TargetFolder)) {
        Write-Error "Target folder not found: $TargetFolder"
        return
    }

    Write-Host "キーワードの抽出を開始します..." -ForegroundColor Cyan
    Write-Host "対象フォルダ: $TargetFolder" -ForegroundColor Cyan

    try {
        # キーワードを抽出して、重複を除外・並べ替え
        $uniqueKeywords = Get-ChildItem -Path $TargetFolder -Recurse -Filter $FileFilter -File |
            Get-Content |
            ForEach-Object { $_.Split(',') } |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique

        # 結果の出力
        if ($uniqueKeywords) {
            Write-Host "----------------------------------------" -ForegroundColor Yellow
            Write-Host "出現したキーワード一覧:" -ForegroundColor Yellow
            Write-Host "----------------------------------------" -ForegroundColor Yellow

            # 画面に出力
            $uniqueKeywords | Write-Output

            # ファイルに出力（$OutputFileが指定されている場合）
            if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
                $uniqueKeywords | Out-File -FilePath $OutputFile -Encoding $enc
                Write-Host ""
                Write-Host "----------------------------------------" -ForegroundColor Yellow
                Write-Host "キーワード一覧を下記ファイルに出力しました。" -ForegroundColor Yellow
                Write-Host "$OutputFile" -ForegroundColor Green
                Write-Host "----------------------------------------" -ForegroundColor Yellow
            }

        } else {
            Write-Warning "キーワードが見つかりませんでした。対象フォルダにテキストファイルが存在するか、内容がカンマ区切りか確認してください。"
        }

    } catch {
        Write-Error "エラーが発生しました: $($_.Exception.Message)"
    }

    Write-Host "処理が完了しました。" -ForegroundColor Green

    # 結果を返す
    [PSCustomObject]@{
        Keywords = $uniqueKeywords
        Count = $uniqueKeywords.Count
        OutputFile = $OutputFile
    }
}