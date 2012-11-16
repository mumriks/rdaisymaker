# encoding: sjis
# Copyright (c) 2012 Kishida Atsushi
# 0.2
require 'win32ole'

def serch_path
   paths = []
   paths = serch_ruby_path_by_wmi
   paths = serch_ruby_path if paths.empty?
   paths.flatten!
   if 1 < paths.size
      return check_version(paths)
   else
      return paths[0]
   end
end

def serch_ruby_path_by_wmi
   rubys = []
   service = WIN32OLE.connect('WinMgmts:Root\\CIMV2')
   set = service.execQuery("select * from Win32_Product  where Name like '%Ruby%'")
   set.each {|ins|
      rubys << ins.InstallLocation unless ins.InstallLocation.nil?
   }
   return rubys
end

def serch_ruby_path
   rubys = []
   ["C:/Program Files", "C:/Program Files (x86)"].each {|path|
      rubys << Dir.glob("#{path}/Ruby*").find_all {|f| File.directory?(f)}
   }
   return rubys
end

def check_version(paths)
   max, maxver, maxpatch = nil, nil, nil
   pathver, pathpatch = nil, nil
   paths.each {|path|
      if max.nil?
         max = path
         if /-(\d\.\d\.\d)(-[pP]\d+)?/ =~ max
            maxver = $1; maxpatch = $2
         end
         next
      else
         if /-(\d\.\d\.\d)(-[pP]\d+)?/ =~ path
            pathver = $1; pathpatch = $2
         end
         next if 0 < ( maxver <=> pathver )
         if 0 == ( maxver <=> pathver )
            next if 0 < ( maxpatch <=> pathpatch )
            max = path if 0 > ( maxpatch <=> pathpatch )
         else
            max = path
         end
      end
   }
   return max
end

def make_console
   File.open("rdmconsole.bat", "w"){|f|
      f.puts <<EOT
@rem R DAISY Maker 実行コンソール起動バッチファイル
@set path=%path%;#{@rubypath};#{@bindir};
start cmd
EOT
   }
end

def make_pedit_bat
   File.open("#{@bindir}/pedit.bat", "w"){|f|
      f.puts <<EOT
@rem 編集支援ツール起動バッチファイル
@ruby #{@bindir}/pedit.rb %*
EOT
   }
end

def make_rdm_bat
   File.open("#{@bindir}/rdm.bat", "w"){|f|
      f.puts <<EOT
@rem R DAISY Maker 起動バッチファイル
@ruby #{@bindir}/rdaisymaker.rb %*
EOT
   }
end

def make_rd2_bat
   File.open("#{@bindir}/rd2.bat", "w"){|f|
      f.puts <<EOT
@rem R Daisy2.02 Exchanger 起動バッチファイル
@ruby #{@bindir}/rdaisy202.rb %*
EOT
   }
end

def error
   STDERR.puts "先に Ruby をインストールしてください。"
   exit 0
end

@rubypath = "#{serch_path}/bin"
error() if @rubypath.nil?
@bindir = File.expand_path("./bin", Dir.pwd)
make_console()
make_pedit_bat()
make_rdm_bat()
make_rd2_bat()
