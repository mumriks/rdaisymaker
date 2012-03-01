# encoding: sjis
# Copyright (c) 2012 Kishida Atsushi
#
cdir = Dir.pwd
bindir = File.expand_path("./bin", cdir)
path32 = "c:/Program Files/Ruby-1.9.3/bin"
path64 = "c:/Program Files (x86)/Ruby-1.9.3/bin"
if File.exists?(path32)
   rubypath = path32
elsif File.exists?(path64)
   rubypath = path64
else
   puts "先に Ruby をインストールしてください。"
   exit 0
end

File.open("rdmconsole.bat", "w"){|f|
   f.puts <<EOT
@rem R DAISY Maker 実行コンソール起動バッチファイル
@set path=%path%;#{rubypath};#{bindir};
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
