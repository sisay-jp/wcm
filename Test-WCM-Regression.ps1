#Requires -Version 7.0

<#
.SYNOPSIS
    WCM モジュールの回帰テスト
.DESCRIPTION
    過去に修正した不具合が再発していないかを確認します。
    Temp 配下の作業フォルダだけを使い、終了時に削除します。
    失敗が1件でもあれば終了コード 1 を返します。
#>

$moduleRoot = $PSScriptRoot
$workDir = Join-Path ([System.IO.Path]::GetTempPath()) "wcm-regression-$PID"
New-Item -ItemType Directory -Path $workDir | Out-Null
Push-Location $workDir

$script:passed = 0
$script:failed = 0

function Check {
    param([string]$Name, $Condition, $Detail)
    if ($Condition) {
        $script:passed++
        Write-Host "  ✓ $Name" -ForegroundColor Green
    } else {
        $script:failed++
        Write-Host "  ✗ $Name [$Detail]" -ForegroundColor Red
    }
}

function Test-Throws {
    param([scriptblock]$Script)
    try { & $Script 6>$null | Out-Null; return $false } catch { return $true }
}

function New-Config {
    param([string]$Path, [string]$Body)
    $Body | Set-Content -Path $Path -Encoding UTF8
}

try {
    Import-Module (Join-Path $moduleRoot 'WCM.psd1') -Force -DisableNameChecking -WarningAction SilentlyContinue

    New-Item -ItemType Directory output | Out-Null
    Set-Content ex.txt 'zzz' -Encoding UTF8
    Set-Content in.txt 'a,b' -Encoding UTF8
    Set-Content ba.txt 'b,a' -Encoding UTF8

    Write-Host "=== タスクの失敗 ===" -ForegroundColor Cyan

    Set-Content output\result.txt 'OLD_RESULT' -Encoding UTF8
    New-Config d.psd1 "@{ Tasks = @(
      @{ Name='t1'; Action='Process-CsvAdvanced-Updated'; Params=@{ InputFile='work\nope.txt'; OutputFile='output\result.txt' } },
      @{ Name='t2'; Action='Process-TextFile'; Params=@{ InputFileA='ex.txt'; InputFileB='output\result.txt'; OutputFile='output\result2.txt' } }
    ) }"
    $message = ''
    try { Invoke-WCM -ConfigPath d.psd1 6>$null | Out-Null } catch { $message = "$_" }
    Check '入力がなければ後続タスクを実行しない' (-not (Test-Path output\result2.txt)) 'result2 が作られた'
    Check '失敗メッセージにタスク名が入る' ($message -match 't1') $message

    New-Config d2.psd1 "@{ ModuleConfig=@{ LogEnabled=`$false; LogToConsole=`$false }; Tasks = @(
      @{ Name='t1'; Action='Process-CsvAdvanced-Updated'; Params=@{ InputFile='work\nope.txt'; OutputFile='output\r3.txt' } },
      @{ Name='t2'; Action='Process-TextFile'; Params=@{ InputFileA='ex.txt'; InputFileB='in.txt'; OutputFile='output\r4.txt' } }
    ) }"
    $threw = Test-Throws { Invoke-WCM -ConfigPath d2.psd1 }
    Check 'ログを無効にしても止まる' ($threw -and -not (Test-Path output\r4.txt)) "threw=$threw"
    Set-WCMConfig -Config @{ LogEnabled = $true; LogToConsole = $true }

    New-Config d3.psd1 "@{ Tasks = @(
      @{ Name='a'; Action='Process-TextFile'; Params=@{ InputFileA='nope.txt'; InputFileB='in.txt' } },
      @{ Name='b'; Action='Process-TextFile'; Params=@{ InputFileA='ex.txt'; InputFileB='in.txt'; OutputFile='output\r5.txt' } }
    ) }"
    $threw = Test-Throws { Invoke-WCM -ConfigPath d3.psd1 }
    Check 'Write-Error で失敗するタスクでも止まる' ($threw -and -not (Test-Path output\r5.txt)) "threw=$threw"

    New-Config d4.psd1 "@{ Tasks = @(
      @{ Name='a'; Action='Process-CsvAdvanced-Updated'; Params=@{ InputFile='in.txt'; OutputFile='output\s1.txt' } },
      @{ Name='b'; Action='Process-TextFile'; Params=@{ InputFileA='ex.txt'; InputFileB='output\s1.txt'; OutputFile='output\s2.txt' } }
    ) }"
    Invoke-WCM -ConfigPath d4.psd1 6>$null | Out-Null
    Check '正常なタスクは最後まで実行する' ((Get-Content output\s2.txt) -eq 'a,b') (Get-Content output\s2.txt)

    foreach ($p in @{ ReplaceFile = 'typo.csv' }, @{ ExcludeFile = 'typo.txt' }) {
        Remove-Item output\e.txt -ErrorAction SilentlyContinue
        $threw = Test-Throws { Process-CsvAdvanced-Updated -InputFile in.txt -OutputFile output\e.txt @p }
        Check "$($p.Keys) がなければ例外" ($threw -and -not (Test-Path output\e.txt)) "threw=$threw"
    }
    Process-CsvAdvanced-Updated -InputFile in.txt -OutputFile output\e.txt
    Check '置換・除外ファイルは省略できる' ((Get-Content output\e.txt) -eq 'a,b') (Get-Content output\e.txt)

    Write-Host "=== 置換ルール ===" -ForegroundColor Cyan

    Set-Content rules.csv (1..30 | ForEach-Object { '"w{0}","w{0}->w{1}"' -f $_, ($_ + 1) }) -Encoding UTF8
    Set-Content w.txt 'w1' -Encoding UTF8
    Process-CsvAdvanced-Updated -InputFile w.txt -ReplaceFile rules.csv -OutputFile output\w.txt
    Check '連鎖ルールは記載順に適用する' ((Get-Content output\w.txt) -eq 'w31') (Get-Content output\w.txt)

    Set-Content dup.csv @('"x","x->one"', '"x","x->two"') -Encoding UTF8
    Set-Content x.txt 'x' -Encoding UTF8
    $warnings = Process-CsvAdvanced-Updated -InputFile x.txt -ReplaceFile dup.csv -OutputFile output\x.txt 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
    Check '内容の異なる重複ルールは警告する' (@($warnings).Count -eq 1) "warnings=$(@($warnings).Count)"
    Check '重複ルールは後のものを採用する' ((Get-Content output\x.txt) -eq 'two') (Get-Content output\x.txt)

    Set-Content dup2.csv @('"x","x->one"', '"x","x->one"') -Encoding UTF8
    $warnings = Process-CsvAdvanced-Updated -InputFile x.txt -ReplaceFile dup2.csv -OutputFile output\x.txt 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
    Check '同じ内容の重複ルールは警告しない' (@($warnings).Count -eq 0) "warnings=$(@($warnings).Count)"

    Set-Content cs.csv @('"x","x->lower"', '"x","X->upper"') -Encoding UTF8
    Set-Content cs.txt 'x,X' -Encoding UTF8
    Set-WCMConfig -Config @{ CaseSensitive = $true }
    Process-CsvAdvanced-Updated -InputFile cs.txt -ReplaceFile cs.csv -OutputFile output\cs.txt
    Check 'CaseSensitive なら大文字小文字別のルールを保持する' ((Get-Content output\cs.txt) -eq 'lower,upper') (Get-Content output\cs.txt)
    Set-WCMConfig -Config @{ CaseSensitive = $false }

    Write-Host "=== 互換関数 ===" -ForegroundColor Cyan

    $result = Process-CsvAdvanced -InputFile ba.txt
    Check 'Process-CsvAdvanced は OutputFile なしで結果を返す' ($result -eq 'b,a') $result
    $result = Process-CsvAdvanced-Updated -InputFile ba.txt
    Check 'Process-CsvAdvanced-Updated も OutputFile なしで結果を返す' ($result -eq 'b,a') $result
    Set-Content w2.txt 'w1' -Encoding UTF8
    Process-CsvAdvanced -InputFile w2.txt -ReplaceFile rules.csv -OutputFile output\w2.txt
    Check 'Process-CsvAdvanced も記載順に適用する' ((Get-Content output\w2.txt) -eq 'w31') (Get-Content output\w2.txt)
    Check 'Process-CsvAdvanced も欠けたファイルで例外' (Test-Throws { Process-CsvAdvanced -InputFile in.txt -ReplaceFile typo.csv -OutputFile output\typo.txt }) '例外なし'

    $result = Process-TextFile-Simple -InputFileA ex.txt -InputFileB ba.txt 6>$null
    Check 'Process-TextFile-Simple は結果を返す' ($result -eq 'b,a') $result
    Check 'Process-TextFile-Simple は欠けたファイルでエラー' (Test-Throws { Process-TextFile-Simple -InputFileA nope.txt -InputFileB ba.txt -ErrorAction Stop }) '例外なし'

    Set-Content ab2.txt @('b,a', 'a,b') -Encoding UTF8
    Set-Content ax.txt 'zzz' -Encoding UTF8
    $result = Process-TextFile-Updated -InputFileA ax.txt -InputFileB ab2.txt -OutputFile u.txt 6>$null
    $lines = @(Get-Content u.txt)
    Check 'Process-TextFile-Updated は並び順違いを重複にする' ($lines.Count -eq 1 -and $lines[0] -eq 'b,a') ($lines -join '|')
    Check 'Process-TextFile-Updated は除外数も返す' ("$result" -match 'zzz: 0') "$result"

    Write-Host "=== テキスト処理 ===" -ForegroundColor Cyan

    $result = Process-TextFile -InputFileA ex.txt -InputFileB ba.txt -SortItems 6>$null
    Check 'SortItems は出力も並び替える' ($result -eq 'a,b') $result
    $result = Process-TextFile -InputFileA ex.txt -InputFileB ba.txt 6>$null
    Check 'SortItems なしは元の並び' ($result -eq 'b,a') $result
    $result = @(Process-TextFile -InputFileA ex.txt -InputFileB ab2.txt -SortItems 6>$null)
    Check 'SortItems は並び順違いを重複にする' ($result.Count -eq 1 -and $result[0] -eq 'a,b') ($result -join '|')
    $result = @(Process-TextFile -InputFileA ex.txt -InputFileB ab2.txt -DedupeIgnoreOrder 6>$null)
    Check 'DedupeIgnoreOrder は元の並びで重複を除く' ($result.Count -eq 1 -and $result[0] -eq 'b,a') ($result -join '|')
    $result = @(Process-TextFile -InputFileA ex.txt -InputFileB ab2.txt 6>$null)
    Check 'オプションなしは並び順違いを別の行にする' ($result.Count -eq 2) ($result -join '|')

    Set-Content blank.txt '' -Encoding UTF8
    New-Item -ItemType File zero.txt | Out-Null
    foreach ($f in 'blank.txt', 'zero.txt') {
        foreach ($fn in 'Process-TextFile', 'Process-TextFile-Simple') {
            $result = & $fn -InputFileA $f -InputFileB ba.txt 6>$null
            Check "$fn は除外ファイルが空でも動く ($f)" ($result -eq 'b,a') $result
        }
    }

    Set-Content in3.txt @('a,b', 'c,d', 'e,f') -Encoding UTF8
    foreach ($fn in 'Process-TextFile', 'Process-TextFile-Simple') {
        $dir = "modify_$fn"
        & $fn -InputFileA ex.txt -InputFileB in3.txt -OutputDir $dir 6>$null | Out-Null
        Set-Content "$dir\notes.txt" 'keep' -Encoding UTF8
        & $fn -InputFileA ex.txt -InputFileB in.txt -OutputDir $dir 6>$null | Out-Null
        $names = (Get-ChildItem $dir).Name -join ','
        Check "$fn は古い分割ファイルだけを消す" ($names -eq '0001.txt,notes.txt') $names
    }
    $keywords = (Get-UniqueKeywords -TargetFolder modify_Process-TextFile -FileFilter '0*.txt' 6>$null | Select-Object -Last 1).Keywords
    Check 'キーワード抽出に古い行が混ざらない' (($keywords -join ',') -eq 'a,b') ($keywords -join ',')

    Set-Content exq.txt 'foo' -Encoding UTF8
    Set-Content inq.txt 'FOO,bar,Bar' -Encoding UTF8
    New-Item -ItemType Directory o | Out-Null
    Set-Content o\1.txt 'Foo,foo,BAR' -Encoding UTF8
    foreach ($fn in 'Process-TextFile', 'Process-TextFile-Simple') {
        $result = & $fn -InputFileA exq.txt -InputFileB inq.txt 6>$null
        Check "$fn は既定で大文字小文字を区別しない" ($result -eq 'bar') $result
    }
    $keywords = (Get-UniqueKeywords -TargetFolder o 6>$null | Select-Object -Last 1).Keywords
    Check 'Get-UniqueKeywords は既定で大文字小文字をまとめる' (@($keywords).Count -eq 2) ($keywords -join '|')
    Set-WCMConfig -Config @{ CaseSensitive = $true }
    foreach ($fn in 'Process-TextFile', 'Process-TextFile-Simple') {
        $result = & $fn -InputFileA exq.txt -InputFileB inq.txt 6>$null
        Check "$fn は CaseSensitive で区別する" ($result -ceq 'FOO,bar,Bar') $result
    }
    $keywords = (Get-UniqueKeywords -TargetFolder o 6>$null | Select-Object -Last 1).Keywords
    Check 'Get-UniqueKeywords は CaseSensitive で区別する' (@($keywords).Count -eq 3) ($keywords -join '|')
    Set-WCMConfig -Config @{ CaseSensitive = $false }

    Write-Host "=== 検索と複製 ===" -ForegroundColor Cyan

    New-Item -ItemType Directory all\x, all\y | Out-Null
    Set-Content all\x\0001.txt 'kw,from_x' -Encoding UTF8
    Set-Content all\y\0001.txt 'kw,from_y' -Encoding UTF8
    Set-Content all\top.txt @('kw,top', 'other,line', '', 'a,"q"') -Encoding UTF8
    Set-Content kw.txt 'kw' -Encoding UTF8
    Set-Content kw2.txt 'never' -Encoding UTF8
    Set-Content kwand.txt @('kw,top', 'a') -Encoding UTF8
    Set-Content kwempty.txt @('', ' , ') -Encoding UTF8

    Find-TextContent -SearchFolder all -KeywordFile kwand.txt -OutputFile f.csv 6>$null
    $found = @(Get-Content f.csv)
    Check 'Find-TextContent は AND と OR で検索する' ($found.Count -eq 3 -and $found[0] -like 'MatchedPattern*') ($found -join '|')
    Check '検索結果の引用符をエスケープする' (($found -join '|') -match '"a,""q"""') ($found -join '|')
    Find-TextContent-Mismatch -SearchFolder all -KeywordFile kwand.txt -OutputFile m.csv 6>$null
    $mismatch = @(Get-Content m.csv)
    Check 'Mismatch は合致しない行だけを返す' ($mismatch.Count -eq 4 -and ($mismatch -join '|') -match 'other,line') ($mismatch -join '|')

    Find-TextContent -SearchFolder all -KeywordFile kw2.txt -OutputFile f.csv 6>$null
    Check 'Find-TextContent は一致0件で前回の結果を消す' (-not (Test-Path f.csv)) 'f.csv が残った'
    Set-Content kwall.txt @('kw', 'other', 'a') -Encoding UTF8
    Find-TextContent-Mismatch -SearchFolder all -KeywordFile kwall.txt -OutputFile m.csv 6>$null
    Check 'Mismatch は不一致0件で前回の結果を消す' (-not (Test-Path m.csv)) 'm.csv が残った'

    foreach ($fn in 'Find-TextContent', 'Find-TextContent-Mismatch') {
        Check "$fn は有効なパターンがなければエラー" (Test-Throws { & $fn -SearchFolder all -KeywordFile kwempty.txt -OutputFile e.csv -ErrorAction Stop }) '例外なし'
    }
    Check 'WithCopy は有効なパターンがなければエラー' (Test-Throws { Find-TextContent-WithCopy -SearchFolder all -KeywordFile kwempty.txt -OutputFile e.csv -DuplicateFolder edup -ErrorAction Stop }) '例外なし'

    Find-TextContent-WithCopy -SearchFolder all -KeywordFile kw.txt -OutputFile s.csv -DuplicateFolder dup 6>$null | Out-Null
    $copied = (Get-ChildItem dup -Recurse -File).FullName | ForEach-Object { $_.Substring((Get-Location).Path.Length + 5) } | Sort-Object
    Check '同名ファイルも上書きせず複製する' (($copied -join ',') -eq 'top.txt,x\0001.txt,y\0001.txt') ($copied -join ',')
    Merge-TextFiles -SourcePath dup -OutputPath merged_ok.txt 6>$null
    $merged = Get-Content merged_ok.txt -Raw
    Check 'Merge はサブフォルダの複製も読む' (($merged -match 'from_x') -and ($merged -match 'from_y')) $merged

    Set-Content s2.csv 'OLD' -Encoding UTF8
    Find-TextContent-WithCopy -SearchFolder all -KeywordFile kw2.txt -OutputFile s2.csv -DuplicateFolder dup 6>$null | Out-Null
    Check '一致0件で複製先を空にする' (@(Get-ChildItem dup -Force).Count -eq 0) (@(Get-ChildItem dup -Force).Count)
    Check '一致0件で前回の検索結果を消す' (-not (Test-Path s2.csv)) 's2.csv が残った'

    $before = @(Get-ChildItem all -Recurse -File).Count
    foreach ($case in @(
            @{ Name = '検索フォルダ自身'; Dir = 'all' },
            @{ Name = '検索フォルダの配下'; Dir = 'all\x' },
            @{ Name = '検索フォルダの親'; Dir = '.' },
            @{ Name = 'ドライブ直下'; Dir = [System.IO.Path]::GetPathRoot($workDir) })) {
        $threw = Test-Throws { Find-TextContent-WithCopy -SearchFolder all -KeywordFile kw.txt -OutputFile s3.csv -DuplicateFolder $case.Dir -ErrorAction Stop }
        Check "複製先に $($case.Name) を指定できない" $threw '拒否されなかった'
    }
    Check '拒否したとき検索元は無傷' (@(Get-ChildItem all -Recurse -File).Count -eq $before) 'ファイルが消えた'

    New-Item -ItemType Directory holder | Out-Null
    Copy-Item kw.txt holder\kw.txt
    $threw = Test-Throws { Find-TextContent-WithCopy -SearchFolder all -KeywordFile holder\kw.txt -OutputFile s3.csv -DuplicateFolder holder -ErrorAction Stop }
    Check 'キーワードファイルを含むフォルダを拒否する' ($threw -and (Test-Path holder\kw.txt)) "threw=$threw"
    Check '検索結果ファイルを含むフォルダを拒否する' (Test-Throws { Find-TextContent-WithCopy -SearchFolder all -KeywordFile kw.txt -OutputFile holder\o.csv -DuplicateFolder holder -ErrorAction Stop }) '拒否されなかった'

    Write-Host "=== 集約 ===" -ForegroundColor Cyan

    Set-Content merged.txt 'PREVIOUS' -Encoding UTF8
    New-Item -ItemType Directory emptydir | Out-Null
    Check '集約元が空ならエラー' (Test-Throws { Merge-TextFiles -SourcePath emptydir -OutputPath merged.txt -ErrorAction Stop }) 'エラーなし'
    Check '集約元が空なら既存の出力を残す' ((Get-Content merged.txt) -eq 'PREVIOUS') '出力が変わった'
    $threw = Test-Throws { Merge-TextFiles -SourcePath no_such_dir -OutputPath merged.txt -ErrorAction Stop }
    Check '集約元がなければエラーで出力を残す' ($threw -and (Test-Path merged.txt)) "threw=$threw"

    New-Item -ItemType Directory selfdir | Out-Null
    Set-Content selfdir\a.txt 'A' -Encoding UTF8
    Merge-TextFiles -SourcePath selfdir -OutputPath selfdir\out.txt 6>$null
    Merge-TextFiles -SourcePath selfdir -OutputPath selfdir\out.txt 6>$null
    Check '再実行で出力自身を集約しない' (@(Get-Content selfdir\out.txt | Where-Object { $_ }).Count -eq 1) (Get-Content selfdir\out.txt -Raw)

    New-Config r.psd1 "@{ Tasks = @(
      @{ Name='find'; Action='Find-TextContent-WithCopy'; Params=@{ SearchFolder='all'; KeywordFile='kw2.txt'; OutputFile='r.csv'; DuplicateFolder='rdup' } },
      @{ Name='merge'; Action='Merge-TextFiles'; Params=@{ SourcePath='rdup'; OutputPath='rmerged.txt' } }
    ) }"
    Check '一致0件なら Merge でエラーになる' (Test-Throws { Invoke-WCM -ConfigPath r.psd1 }) 'エラーなし'

    Write-Host "=== 出力先フォルダ ===" -ForegroundColor Cyan

    Set-Content data.csv @('Name,Date', 'x,2025/01/01', 'y,2025/02/02') -Encoding UTF8
    New-Item -ItemType Directory src | Out-Null
    Set-Content src\a.txt 'kw,q' -Encoding UTF8
    Set-Content miss.txt 'not_there' -Encoding UTF8
    $cases = [ordered]@{
        'Process-CsvAdvanced-Updated' = { Process-CsvAdvanced-Updated -InputFile ba.txt -OutputFile n1\d\o.txt; 'n1\d\o.txt' }
        'Process-CsvAdvanced'         = { Process-CsvAdvanced -InputFile ba.txt -OutputFile n2\d\o.txt; 'n2\d\o.txt' }
        'Process-TextFile'            = { Process-TextFile -InputFileA ex.txt -InputFileB ba.txt -OutputFile n3\d\o.txt | Out-Null; 'n3\d\o.txt' }
        'Process-TextFile ListFile'   = { Process-TextFile -InputFileA ex.txt -InputFileB ba.txt -OutputDir n4\m -ListFile n4\l\list.txt | Out-Null; 'n4\l\list.txt' }
        'Process-TextFile-Simple'     = { Process-TextFile-Simple -InputFileA ex.txt -InputFileB ba.txt -OutputFile n5\d\o.txt | Out-Null; 'n5\d\o.txt' }
        'Process-TextFile-Updated'    = { Process-TextFile-Updated -InputFileA ex.txt -InputFileB ba.txt -OutputFile n7\d\o.txt | Out-Null; 'n7\d\o.txt' }
        'Get-UniqueKeywords'          = { Get-UniqueKeywords -TargetFolder src -OutputFile n8\d\o.txt | Out-Null; 'n8\d\o.txt' }
        'Merge-TextFiles'             = { Merge-TextFiles -SourcePath src -OutputPath n9\d\o.txt; 'n9\d\o.txt' }
        'Find-TextContent'            = { Find-TextContent -SearchFolder src -KeywordFile kw.txt -OutputFile n10\d\o.csv | Out-Null; 'n10\d\o.csv' }
        'Find-TextContent-WithCopy'   = { Find-TextContent-WithCopy -SearchFolder src -KeywordFile kw.txt -OutputFile n11\d\o.csv -DuplicateFolder n11\dup | Out-Null; 'n11\d\o.csv' }
        'Find-TextContent-Mismatch'   = { Find-TextContent-Mismatch -SearchFolder src -KeywordFile miss.txt -OutputFile n12\d\o.csv | Out-Null; 'n12\d\o.csv' }
        'Find-UnusedSearchTerms'      = { Find-UnusedSearchTerms -SearchTermsFile miss.txt -TargetDirectory src -OutputFile n13\d\o.txt | Out-Null; 'n13\d\o.txt' }
        'Export-CsvFile'              = { Add-CsvColumn -Path data.csv -ColumnName S -DefaultValue v -OutputPath n14\d\o.csv | Out-Null; 'n14\d\o.csv' }
    }
    foreach ($name in $cases.Keys) {
        $path = $null
        try { $path = & $cases[$name] 6>$null | Select-Object -Last 1 } catch { $path = $null }
        Check "$name は出力先フォルダを作る" ($path -and (Test-Path $path)) "path=$path"
    }

    Write-Host "=== 設定ファイル ===" -ForegroundColor Cyan

    New-Item -ItemType Directory cfg\modify | Out-Null
    Set-Content cfg\data.csv @('Name,Date', 'x,2025/01/01', 'y,2025/02/02') -Encoding UTF8
    Set-Content cfg\ex.txt 'zzz' -Encoding UTF8
    Set-Content cfg\in.txt 'p,q' -Encoding UTF8
    Set-Content cfg\modify\0001.txt 'kept' -Encoding UTF8
    New-Config cfg\p.psd1 "@{ Tasks = @(
      @{ Name='slash'; Action='Select-CsvRows'; Params=@{ Path='data.csv'; Column='Date'; Value='2025/01/01'; OutputPath='sel.csv' } },
      @{ Name='bareA'; Action='Process-TextFile'; Params=@{ InputFileA='ex.txt'; InputFileB='in.txt'; OutputFile='tf.txt' } },
      @{ Name='bareFolder'; Action='Get-UniqueKeywords'; Params=@{ TargetFolder='modify'; OutputFile='kw.txt'; FileFilter='*.txt' } }
    ) }"
    Invoke-WCM -ConfigPath cfg\p.psd1 6>$null | Out-Null
    $selected = if (Test-Path cfg\sel.csv) { Get-Content cfg\sel.csv -Raw } else { '' }
    Check '/ を含む値をパス扱いしない' ($selected -match '2025/01/01' -and $selected -notmatch 'y,') $selected
    Check 'InputFileA/B は設定ファイル基準で解決する' ((Test-Path cfg\tf.txt) -and ((Get-Content cfg\tf.txt) -eq 'p,q')) 'tf.txt'
    Check 'フォルダ名だけの指定も設定ファイル基準で解決する' ((Get-Content cfg\kw.txt) -eq 'kept') 'kw.txt'

    foreach ($action in 'Write-Output', 'Remove-Item', 'Write-WCMLog') {
        Remove-Item a_first.txt -ErrorAction SilentlyContinue
        New-Config a.psd1 "@{ Tasks = @(
          @{ Name='first'; Action='Process-TextFile'; Params=@{ InputFileA='ex.txt'; InputFileB='ba.txt'; OutputFile='a_first.txt' } },
          @{ Name='bad'; Action='$action'; Params=@{} }
        ) }"
        $message = ''
        try { Invoke-WCM -ConfigPath a.psd1 6>$null | Out-Null } catch { $message = "$_" }
        Check "Action $action を実行前に拒否する" ($message -match $action -and -not (Test-Path a_first.txt)) $message
    }
    New-Config a2.psd1 "@{ Tasks = @( @{ Action='process-textfile'; Params=@{ InputFileA='ex.txt'; InputFileB='ba.txt'; OutputFile='a2.txt' } } ) }"
    Invoke-WCM -ConfigPath a2.psd1 6>$null | Out-Null
    Check 'Action 名は大文字小文字を区別しない' (Test-Path a2.txt) 'a2.txt'

    '{"Tasks":[{"Action":"Process-TextFile","Params":{"InputFileA":"ex.txt","InputFileB":"ba.txt","OutputFile":"j.txt"}}]}' | Set-Content j.json -Encoding UTF8
    Invoke-WCM -ConfigPath j.json 6>$null | Out-Null
    Check 'JSON の設定ファイルも動く' (Test-Path j.txt) 'j.txt'

    Copy-Item (Join-Path $moduleRoot 'examples') sample -Recurse
    Invoke-WCM -ConfigPath sample\wcm.run.psd1 6>$null | Out-Null
    Check 'サンプル設定がそのまま動く' (Test-Path demo_output\from_config_out.csv) 'from_config_out.csv'
    Set-WCMConfig -Reset -Config @{ LogPath = '' }

    Write-Host "=== 区切り文字 ===" -ForegroundColor Cyan

    Check '本物のタブを受け付ける' (-not (Test-Throws { Set-WCMConfig -Config @{ DefaultDelimiter = "`t" } })) '拒否された'
    Set-Content tab.txt "a b`tc`td" -Encoding UTF8
    Set-Content tabex.txt 'c' -Encoding UTF8
    Process-CsvAdvanced-Updated -InputFile tab.txt -ExcludeFile tabex.txt -OutputFile tab_o.txt
    Check 'タブで要素を分割する' ((Get-Content tab_o.txt) -eq "a b`td") (Get-Content tab_o.txt)
    Check '文字列の \t は拒否する' (Test-Throws { Set-WCMConfig -Config @{ DefaultDelimiter = '\t' } }) '受け付けた'
    Set-WCMConfig -Config @{ DefaultDelimiter = ',' }
}
catch {
    $script:failed++
    Write-Host "テストの実行中に例外が発生しました: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    Pop-Location
    Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module WCM -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "成功: $script:passed / 失敗: $script:failed"
if ($script:failed -gt 0) {
    exit 1
}
