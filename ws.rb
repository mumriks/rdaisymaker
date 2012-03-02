# encoding: sjis
# Copyright (c) 2012 Kishida Atsushi
#
cdir = Dir.pwd
bindir = File.expand_path("./bin", cdir)
path1 = "c:/Program Files/Ruby-1.9.3/bin"
path2 = "c:/Program Files (x86)/Ruby-1.9.3/bin"
if File.exists?(path1)
   rubypath = path1
elsif File.exists?(path2)
   rubypath = path2
else
   puts "��� Ruby ���C���X�g�[�����Ă��������B"
   exit 0
end

File.open("rdmconsole.bat", "w"){|f|
   f.puts <<EOT
@rem R DAISY Maker ���s�R���\�[���N���o�b�`�t�@�C��
@set path=%path%;#{rubypath};#{bindir};
start cmd
EOT
}

File.open("#{bindir}/pedit.bat", "w"){|f|
   f.puts <<EOT
@rem �ҏW�x���c�[���N���o�b�`�t�@�C��
@ruby #{bindir}/pedit.rb %*
EOT
}

File.open("#{bindir}/rdm.bat", "w"){|f|
   f.puts <<EOT
@rem R DAISY Maker �N���o�b�`�t�@�C��
@ruby #{bindir}/rdaisymaker.rb %*
EOT
}
