# テキストファイル集約関数 / Text File Merging Function
function Merge-TextFiles {
    <#
    .SYNOPSIS
        指定されたディレクトリ内のテキストファイルを1つのファイルに集約する
    .DESCRIPTION
        指定されたルートディレクトリから再帰的にテキストファイルを検索し、
        すべての内容を1つの出力ファイルに集約します
    .PARAMETER SourcePath
        検索を開始するルートディレクトリのパス
    .PARAMETER OutputPath
        内容を集約して出力するファイルのパス
    .PARAMETER FileFilter
        検索するファイルのパターン（デフォルト: *.txt）
    .PARAMETER Encoding
        出力ファイルのエンコーディング（デフォルト: UTF8）
    .EXAMPLE
        Merge-TextFiles -SourcePath "C:\Data" -OutputPath "C:\Merged\all_data.txt"
    .EXAMPLE
        Merge-TextFiles -SourcePath "C:\Logs" -OutputPath "C:\Merged\all_logs.txt" -FileFilter "*.log" -Encoding "Shift-JIS"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,    # 検索を開始するルートディレクトリのパス

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,    # 内容を集約して出力するファイルのパス

        [string]$FileFilter = '*.txt', # 検索するファイルのパターン

        [string]$Encoding = 'UTF8'      # 出力ファイルのエンコーディング
    )

    Write-Host "検索対象: $SourcePath"
    Write-Host "出力先: $OutputPath"
    Write-Host "--------------------"

    # 出力ファイルが存在する場合は削除（新規作成のため）
    if (Test-Path -Path $OutputPath) {
        Remove-Item -Path $OutputPath -Force
    }

    # Get-ChildItem で再帰的にファイルを取得
    # -Recurse: サブフォルダを含めて再帰的に検索
    # -File: ファイルのみを対象とする
    $files = Get-ChildItem -Path $SourcePath -Filter $FileFilter -Recurse -File

    if ($files.Count -eq 0) {
        Write-Warning "指定されたパス ($SourcePath) 以下に $FileFilter に一致するファイルが見つかりませんでした。"
        return
    }

    $fileCount = 0

    # 各ファイルを読み込み、内容を出力ファイルに追記
    foreach ($file in $files) {
        Write-Host "処理中: $($file.FullName)"

        # Get-Content でファイル内容を読み込み、パイプラインで Add-Content に渡す
        # -Raw を使用すると、ファイル全体を単一の文字列として読み込むため、
        # 行ごとに処理する場合よりもパフォーマンスが良いことが多いです。
        (Get-Content -Path $file.FullName -Raw -Encoding $Encoding) |
            Add-Content -Path $OutputPath -Encoding $Encoding

        # ファイルの内容の間に区切りを入れる場合は、以下の行を有効にしてください
        # (例: 処理したファイル名と --- で区切る)
        # Add-Content -Path $OutputPath -Value "`n--- $($file.FullName) ---`n" -Encoding $Encoding

        $fileCount++
    }

    Write-Host "--------------------"
    Write-Host "処理が完了しました。$fileCount 個のファイルの内容が $OutputPath に集約されました。"
}