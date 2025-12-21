@{
  ModuleConfig = @{
    DefaultEncoding  = 'UTF8'
    DefaultDelimiter = ','
    HasHeader        = $true
    BackupFiles      = $true
    BackupExtension  = '.backup'
    CaseSensitive    = $false
    UseRegex         = $false

    LogEnabled   = $true
    LogLevel     = 'INFO'
    LogPath      = 'demo_output/WCM.log'
    LogToConsole = $true
  }

  Tasks = @(
    @{
      Name   = 'csv_advanced'
      Action = 'Process-CsvAdvanced-Updated'
      Params = @{
        InputFile   = 'work\combined\combined.txt'
        ReplaceFile = 'work\replaces\replace_words.csv'
        ExcludeFile = 'work\rules\exclude4.txt'
        OutputFile  = 'output\result.txt'
      }
    },
    @{
      Name   = 'text_file'
      Action = 'Process-TextFile'
      Params = @{
        InputFileA = 'work\rules\exclude4.txt'  # 除外リスト
        InputFileB = 'output\result.txt'        # 処理対象テキスト
        OutputDir  = '.\output\modify'           # パスは任意で変更可
        # OutputFile = 'output\result2.txt'      # 1ファイル出力もしたいなら任意で追加
        # SortItems = $true                      # 必要なら
        # CountExclusions = $true                # 必要なら
      }
    }
  )
}
