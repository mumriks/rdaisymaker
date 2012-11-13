# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#

require 'fileutils'
require 'optparse'
require 'tempfile'
require 'date'
require 'rexml/document'
require 'yaml'

VERSION = '0.3.0'
RD2 = "R Daisy2.02 Exchanger ver #{VERSION}"
PLEXTALK = "PLEXTALK DAISY Producer ver 0.2.4.0"
DNAME = "rdm"
PNAME = "ptk"

BINDIR = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH << File.join(BINDIR, "../lib")
require 'rdm/daisy'
require 'rdm/phrase'
require 'rdm/daisy2'
require 'rdm/bookcheck'
require 'rdm/ncxbuilder'
require 'rdm/opfbuilder'

@params = {'type' => 'textNCX', 'pagedirection' => 'ltr', 'datevih' => true,
           'file' => false, 'generator' => RD2, 'ptk' => DNAME}

parser = OptionParser.new
scriptfile = File.basename($0)
parser.banner = "Usage: ruby #{scriptfile} options"
parser.on('--to-text3', 'テキストデイジー図書に変換(標準)'){
   puts "daisy2.02 図書をテキストデイジー3図書に変換します。"
}
parser.on('--to-aft3', 'AudioFullText DAISY3に変換'){
   @params["type"] = 'audioFullText'
   puts "daisy2.02 図書を音声付デイジー3図書に変換します。"
}
parser.on('--to-text4', 'テキストのみEPUB3(横組み)に変換'){
   @params["type"] = 'textDAISY4'
   @params["pagedirection"] = 'ltr'
   puts "daisy2.02 図書をEPUB3図書（横組み）に変換します。"
}
parser.on('--to-aft4', 'AudioFullText DAISY4(EPUB3)に変換'){
   @params["type"] = 'audioFullTextDAISY4'
   @params["pagedirection"] = 'ltr'
   puts "daisy2.02 図書を音声付EPUB3図書（横組み）に変換します。"
}
parser.on('--rtl', '文字を縦組みにする（EPUB3でのみ有効）'){
   @params["pagedirection"] = 'rtl'
   puts "文字を縦組みにします（EPUB3）"
}
parser.on('--rtl-date', '文字を縦組み日付処理にする（EPUB3）'){
   @params["pagedirection"] = 'rtl'
   @params["datevih"] = false
   puts "文字を縦組みにします。日付も独自に処理します。（EPUB3）"
}
parser.on('--to-text', '本文を抽出してテキストに(コンソール)'){
   @params["type"] = 'text'
   puts "本文を抽出してコンソールにテキストを表示します。"
}
parser.on('--to-text-f', '本文を抽出してテキストに(ファイル)'){
   @params["type"] = 'text'
   @params["file"] = true
   puts "本文を抽出してファイルにテキストを保存します。"
}
parser.on('--bookcheck', 'Daisy2.02図書のファイルチェックのみ'){
   @params["type"] = 'check'
}
parser.on('-p', '--producer', 'GENERATORをPLEXTALKProducerに'){
   @params["generator"] = PLEXTALK
   @params["ptk"] = PNAME
   puts "PLEXTALK Producer mode."
}
parser.on('-v', '--version', 'バージョン情報を表示'){
   puts "#{RD2}"
   exit 0
}
parser.on('-h', '--help', 'このヘルプを表示して終了'){
   puts parser.help
   exit 0
}
begin
   parser.parse!
rescue OptionParser::ParseError => err
   STDERR.puts "#{$0}: error: #{err.message}"
   $stderr.puts parser.help
   exit 1
end

PTK = @params["ptk"]
GENERATOR = @params["generator"]

def load_yaml_data
   if ARGV.size != 1
      yamls = Dir.glob("*.yaml")
      if 0 == yamls.size
         puts "yaml ファイルが指定されないので、図書データを使用します"
      else
         yamlfile = yamls[0]
         puts "#{yamls[0]} を使用します"
      end
   else
      yamlfile = ARGV[0]
   end
   if yamlfile
      values = YAML.load_file(yamlfile)
      @daisy.meta.title = values["title"] unless values["title"].nil?
      @daisy.meta.publisher = values["publisher"] unless values["publisher"].nil?
      @daisy.meta.date = values["date"] unless values["date"].nil?
      @daisy.meta.isbn = values["isbn"] unless values["isbn"].nil?
      @daisy.meta.author = values["author"] unless values["author"].nil?
      @daisy.meta.translator = values["trl"] unless values["trl"].nil?
      @daisy.meta.editor = values["edt"] unless values["edt"].nil?
      @daisy.meta.illustlator = values["ill"] unless values["ill"].nil?
      @daisy.meta.photographer = values["pht"] unless values["pht"].nil?
      @daisy.xmeta.sourceDate = values["sourceDate"] unless values["sourceDate"].nil?
      @daisy.xmeta.sourcePublisher = values["sourcePublisher"] unless values["sourcePublisher"].nil?
      @daisy.meta.language = values["language"] unless values["language"].nil?
      @daisy.meta.pageDirection = values["pagedirection"] unless values["pagedirection"].nil?
      @daisy.xmeta.multimediaType = values["multimediaType"] unless values["multimediaType"].nil?
      @debug = values["debug"]
   end
end

def set_bookname
   dirs = Dir.pwd.split("/")
   @daisy.bookname = dirs[dirs.size - 1]
   if File.exist?(@daisy.bookname)
      mes = "#{@daisy.bookname} ディレクトリが既に存在します。先に削除するか名前を変えてから実行してください。"
      STDERR.puts mes
      exit 1
   end
end

def set_temp
   @temp = @debug.nil? ? Dir.mktmpdir : "."
   @daisy.mk_temp(@temp)
end

def rename_src_audio_files
   capital_small = @bcd2.errors.exist.find_all {|num, file| 0 < num }
   unless capital_small.empty?
      rename_list = capital_small.find_all {|num, file|
                  Daisy::FT_AUDIO =~ File.extname(file[0]) }
      rename = {}
      rename_list.each {|num, file| rename[file[0]] = file[1] }
      @daisy.seqs.each {|s|
         s.item.each {|par|
            unless rename[par.audio.src].nil?
               par.audio.src = rename[par.audio.src]
            end
         }
      }
      puts "ソースファイル内の以下の audio ファイル名を変更しました。"
      rename_list.each {|num, file|
         puts "'#{file[0]}'  =>  '#{file[1]}'"
      }
   end
end

def check_file(paths)
   unless paths.empty?
      paths.each {|f|
         mes, name = @daisy.check_audio_file(f)
         if /errmes[25]/ =~ mes
            print_error(Daisy::ERRMES[mes] + f )
         end
      }
   end
end

def check_audio_files
   check_file(@bcd2.srcNames.srcAudios)
   rename_src_audio_files()
end

def exchangeToDaisy3over
   case @params["type"]
   when 'textNCX'
      @daisy.xmeta.totalTime = "0:00:00.000"
      @daisy.xmeta.totalElapsedTime = "0:00:00.000"
   when 'audioFullText'
      check_audio_files()
   when 'textDAISY4'
      @daisy.xmeta.multimediaType = "textstream"
   when 'audioFullTextDAISY4'
      @daisy.xmeta.multimediaType = "audioFullText"
      check_audio_files()
   end
   @daisy.image_too_big?
   @daisy.check_meta
   @daisy.build_daisy
   @daisy.copy_files
   FileUtils.rm_r(@temp) if @debug.nil?
end

def exchangeToText
   f = File.open('doc.txt', 'w:UTF-8') if @params["file"]
   @daisy.book.each {|c|
      c.sections.each {|s|
         s.phrases.each {|p|
            if f
               f.puts p.phrase
            else
               puts p.phrase
            end
         }
      }
   }
   if f
      puts "doc.txt を作成しました"
      f.close
   end
end

def exist?(target)
   if !target.nil? and File.exist?(target)
      return true
   else
      return false
   end
end

def read_book_data
   set_bookname()
   set_temp()
   @bcd2 = BookCheck::Daisy2.new(@daisy)
   load_yaml_data()
   @bcd2.srcNames.srcHtmls.each {|h|
      doc = REXML::Document.new(File.open(h))
      @daisy.new_chapter
      @daisy.get_doc(doc.elements["/html/body"])
   }
end

def main
   begin
      values = {}
      case @params["type"]
      when 'text'
         @daisy = TEXT.new(values)
         read_book_data()
         exchangeToText()
      when 'check'
         @daisy = TEXT.new(values)
         set_bookname()
         BookCheck::Daisy2.new(@daisy)
      when 'textNCX'
         @daisy = TEXTDaisy.new(values)
         @daisy.xmeta.multimediaType = "textNCX"
         read_book_data()
         exchangeToDaisy3over()
      when 'audioFullText'
         @daisy = AudioFullTextDaisy3.new(values)
         @daisy.xmeta.multimediaType = "audioFullText"
         read_book_data()
         exchangeToDaisy3over()
      when 'textDAISY4'
         @daisy = TEXTDaisy4.new(values)
         @daisy.datevih = @params["datevih"]
         read_book_data()
         exchangeToDaisy3over()
      when 'audioFullTextDAISY4'
         @daisy = AudioFullTextDaisy4.new(values)
         @daisy.datevih = @params["datevih"]
         read_book_data()
         exchangeToDaisy3over()
      end
   rescue => err
      STDERR.puts err
      if @debug.nil?
         FileUtils.rm_r(@temp) if exist?(@temp)
         FileUtils.rm_r(@daisy.bookname) if exist?(@daisy.bookname)
      end
      exit 1
   end
end

main
