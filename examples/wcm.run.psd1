@{
  # モジュール共通設定（Set-WCMConfig で反映されます）
  ModuleConfig = @{
    DefaultEncoding  = 'UTF8'
    DefaultDelimiter = ','
    HasHeader        = $true
    BackupFiles      = $true
    BackupExtension  = '.backup'
    CaseSensitive    = $false
    UseRegex         = $false

    # ログ（任意）
    LogEnabled        = $true
    LogLevel          = 'INFO'
    # 空なら Temp 配下に WCM.log
    LogPath           = 'demo_output/WCM.log'
    LogToConsole      = $true
  }

  # 実行したいメイン処理を列挙します（順に実行）
  Tasks = @(
    @{ 
      Name   = 'csv_advanced'
      Action = 'Process-CsvAdvanced-Updated'
      Params = @{
        InputFile   = 'examples/sample_data.csv'
        ReplaceFile = 'examples/rules.csv'
        ExcludeFile = 'examples/exclude.txt'
        OutputFile  = 'demo_output/from_config_out.csv'
      }
    }
  )
}
