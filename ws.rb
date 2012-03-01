# encoding: sjis
# Copyright (c) 2012 Kishida Atsushi
#
cdir = Dir.pwd
bindir = File.expand_path("./bin", cdir)

File.open("rdmconsole.bat", "w"){|f|
   f.puts <<EOT
@rem R DAISY Maker 実行コンソール起動バッチファイル
@set path=%path%;c:/Program Files (x86)/Ruby-1.9.3/bin;#{bindir};
start cmd
EOT
}

File.open("#{bindir}/pedit.bat", "w"){|f|
   f.puts <<EOT
@rem 編集支援ツール起動バッチファイル
@ruby #{bindir}/pedit.rb %*
EOT
}

File.open("#{bindir}/rdm.bat", "w"){|f|
   f.puts <<EOT
@rem R DAISY Maker 起動バッチファイル
@ruby #{bindir}/rdaisymaker.rb %*
EOT
}
