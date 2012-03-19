#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#

VERSION = '0.3.0'
BINDIR = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH << File.join(BINDIR, "../lib")

require 'fileutils'
require 'optparse'
require 'yaml'
require 'compiler'
require 'exchangekana'

$LOAD_PATH.each {|path|
   @mecabso = "#{path}/MeCab.so"
   if File.exists?(@mecabso)
      require 'mecabex'
      @mecabso = true
      break
   else
      @mecabso = false
   end
}

WORDS = 600
POEM = 200
STARTPAGE = 1
@words_per_page = WORDS

def print_(message)
   if @params["log"]
     @logfile.puts message
   else
      puts message
   end
end

@params = {"aozora" => nil, "paging" => nil, "split" => true, "ruby" => nil, "bouten" => nil, "log" => nil, "cuttag" => nil, "cutpage" => nil, "poem" => nil}
parser = OptionParser.new
scriptfile = File.basename($0)
parser.banner = "Usage: ruby #{scriptfile} [options]"
parser.on('-s', '--split', '句点でフレーズを分割する（標準）') {
   @params["split"] = true
}
parser.on('--nosplit', 'フレーズ分けをしない') {
   @params["split"] = false
}
parser.on('-a', '--aozora', '青空文庫を編集（-p -s を含む）') {
   @params["aozora"] = true
   @params["paging"] = true
   @params["split"] = true
}
parser.on('-b', '--bu', '傍点を＊下線＊で置き換える（要 -a）') {
   @params["bouten"] = "underline" if @params["aozora"]
}
parser.on('--bb', '傍点を＊太字＊で置き換える（要 -a）') {
   @params["bouten"] = "bold" if @params["aozora"]
}
parser.on('--bi', '傍点を＊斜体＊で置き換える（要 -a）') {
   @params["bouten"] = "italic" if @params["aozora"]
}
parser.on('--nobouten', '傍点を無視（削除）する（要 -a）') {
   @params["bouten"] = false if @params["aozora"]
}
parser.on('-p', '--paging', '自動でページを挿入') {
   @params["paging"] = true
}
parser.on('--nopaging', 'ページ挿入しない') {
   @params["paging"] = false
}
parser.on('--poem', 'ページ挿入を詩篇モードで行う') {
   if @params["paging"]
      @params["poem"] = true
      @words_per_page = POEM
   end
}
parser.on('-r', '--rubya', 'ルビを振る（青空文庫 形式）') {
   if @mecabso
      @params["ruby"] = "aozora"
   else
      print_("この環境ではルビは使えません")
   end
}
parser.on('--rubyr', 'ルビを振る（ReVIEW 形式）'){
   if @mecabso
      @params["ruby"] = "review"
   else
      print_("この環境ではルビは使えません")
   end
}
parser.on('-w', '--wakati', 'わかち書きモードで出力') {
   if @mecabso
      @params["wakati"] = true
   else
      print_("この環境ではルビは使えません")
   end
}
parser.on('-c', '--cutunknown', '未知の青空文庫タグを削除（要 -a）') {
   @params["cuttag"] = true if @params["aozora"]
}
parser.on('--cutpage', '青空文庫の改ページタグを削除（要 -a）') {
   @params["cutpage"] = true if @params["aozora"]
}
####
parser.on('--join','join split line(like PDF => TXT)') {
   @params["join"] = true
   @params["split"] = false
}
####
parser.on('-l', '--log', 'ログファイル作成') {
   @params["log"] = true
}
parser.on('-h', '--help', 'このヘルプメッセージを表示') {
   puts parser.help
   exit 0
}
parser.on('-v', '--version', 'バージョンを表示'){
   puts "pedit.rb ver #{VERSION}"
   exit 0
}

begin
  parser.parse!
rescue OptionParser::ParseError => err
  STDERR.puts "#{$0}: error: #{err.message}"
  $stderr.puts parser.help
  exit 1
end

if @params["aozora"] == nil
   if @params["paging"] == nil
      @params["split"] = true if @params["split"].nil?
   end
end

if @params["log"]
   @logfile = File.open("log.txt", "w:UTF-8")
end

def load_gaiji
   @gaiji = {}
   File.open("#{BINDIR}/../data/prc.txt", "r:UTF-8") {|f|
      f.each_line {|line|
         line.chomp!
         prc, utf8 = line.split
         @gaiji[prc] = utf8
      }
   }
end

def join(line)				##
   if /[^。」]\n/ =~ line
     line.chomp! unless /\d+(?:ページ|ぺーじ)/ =~ line
   end
   return line
end					##

def aozora(line)
   @linenum += 1
#   @genpon = true if /原本奥付/ =~ line
#   line = genpon_head(line) if /^底本：/ =~ line and !@genpon
#   line = set_head(line) if /^　　　+/ =~ line
   while /［＃.+］/ =~ line
      if /［＃[^［]*(?:字下げ|字上げ|天付き|地付き|右寄せ).*］/ =~ line
         line, mes = set_indent(line)
      elsif /※［＃[^［]+］/ =~ line
         line, result, mes = set_gaiji(line)
         unless result
            mes = "文字変換できないため残します。:#{@f} line- #{@linenum}\n#{line}\n"
            print_(mes)
            break
         end
      elsif /［＃.*(?:同行|窓)*(?:大|中|小)見出し.*］/ =~ line
         line, mes = set_head(line)
      elsif /［＃[^［]*(?:太字|斜体|下線|傍線)[^［]*］/ =~ line
         line, mes = set_modify(line)
      elsif /［＃([^［]+図|挿絵)（([^（]+\.\w+)[^（]*）入る.*］/ =~ line
         line, mes = set_image(line, $1, $2)
      elsif /［＃(?:ここから|ここで)罫囲み(?:終わり)?］/ =~ line
         line, mes = set_quote(line)
      elsif /［＃[^［]*傍点[^［]*］/ =~ line
         if @params["bouten"].nil?
            mes = "傍点の処理が指定されていないので残します。:#{@f} line- #{@linenum}\n#{line}\n"
            print_(mes)
            break
         elsif !@params["bouten"]
            mes = "指示により傍点タグを削除します。:#{@f} line- #{@linenum}\n#{line}\n"
            line.gsub!(/［＃[^［]*傍点[^［]*］/, "")
         else
            line, mes = set_modify(line)
         end
      elsif /［＃改(?:丁|ページ|段)］/ =~ line
         if @params["cutpage"]
            mes = "指示によりページタグを削除します。:#{@f} line- #{@linenum}\n#{line}\n"
            line.gsub!(/［＃改(?:丁|ページ|段)］/, "")
         else
            mes = "図書作成時のページ挿入に使用するため残します。:#{@f} line- #{@linenum}\n#{line}\n"
            print_(mes)
            break
         end
      else
         if @params["cuttag"]
            mes = "指示によりタグを削除します。:#{@f} line- #{@linenum}\n#{line}\n"
            line.gsub!(/［＃[^［]+］/, "")
         else
            mes = "判別できないため残します。:#{@f} line- #{@linenum}\n#{line}\n"
            print_(mes)
            break
         end
      end
      print_(mes)
   end
   count_up(line)
   if 0 < @head
      if /^=+\s$/ =~ line
         line.gsub!(/\n/, "")
      elsif 2 < @head
         line = "<br />" + line.gsub(/\n/, "")
      else
         line = line.gsub(/\n/, "")
      end
      @head += 1
   end
   line
end

def bouten_message(line)
   case @params["bouten"]
   when "underline"
      mes = "傍点を「下線」で代用します。:#{@f} line- #{@linenum}\n#{line}\n"
   when "bold"
      mes = "傍点を「太字」で代用します。:#{@f} line- #{@linenum}\n#{line}\n"
   when "italic"
      mes = "傍点を「斜体」で代用します。:#{@f} line- #{@linenum}\n#{line}\n"
   end
end

def count_up(line)
   crcount = line.count("\n")
   @linenum = @linenum + (crcount - 1)
end

def split_period(line)
   phrases = []
   if /^[\s　]*$/ =~ line
      phrases << line
   elsif /。$/ =~ line
      phrases = line.split(/。/)
      num = phrases.size - 1
      phrases.each_with_index {|phr, i|
         if num > i
            phrases[i] = "#{phr}。\n"
         end
      }
   else
      phrases = line.split(/。/)
      num = phrases.size - 1
      phrases.each_with_index {|phr, i|
         if num > i
            phrases[i] = "#{phr}。\n"
         else
            phrases[i] = "#{phr}\n"
         end
      }
   end
   phrases
end

def genpon_head(line)
   "= 原本奥付\n\n" + line
end

def set_head(line)
   if /［＃「[^「]+」は.*(大|中|小)見出し］/ =~ line
      str = $1
      head = check_head(str)
      line = head + line
      line.gsub!(/［＃[^［]+］/, "")
      mes = "#{str}見出しとして処理しました。:#{@f} line- #{@linenum}\n#{line}\n"
   elsif /［＃(大|中|小)見出し］([^［]+)［＃.+見出し終わり］/ =~ line
      str = $1
      head = check_head(str)
      line = head + $2 + "\n"
      mes = "#{str}見出しとして処理しました。:#{@f} line- #{@linenum}\n#{line}\n"
#   elsif /［＃(?:ここから|ここで)(大|中|小)見出し(?:終わり)*］/ =~ line
#      mes = "処理が未定のため残しています。:#{@f} line- #{@linenum}\n#{line}\n"
   elsif /［＃ここから(大|中|小)見出し］/ =~ line
      str = $1
      head = check_head(str)
      mes = "＊ここから#{str}見出しとして処理します。＊:#{@f} line- #{@linenum}\n#{line}\n"
      line = head + line.sub(/［＃ここから(?:大|中|小)見出し］/, "")
      @head = 1
   elsif /［＃ここで(?:大|中|小)見出し終わり］/ =~ line
      mes = "＊ここまでを#{str}見出しとして処理しました。＊:#{@f} line-#{@linenum}\n#{line}\n"
      line.sub!(/［＃ここで(?:大|中|小)見出し終わり］/, "")
      @head = 0
   elsif /^　　　+/ =~ line
      line = "= " + line
      mes = "見出しとして処理します。 :#{@f} line- #{@linenum}\n#{line}\n"
   end
   return line, mes
end

def check_head(str)
   case str
   when "大"
      head = "= "
   when "中"
      head = "== "
   when "小"
      head = "=== "
   end
end

def set_modify(line)
   if @reg
      line = modify_block_end?(line, "［＃ここで#{@reg}終わ?り］")
   elsif /［＃[^［]*太字[^［]*］/ =~ line
      line = modify_(line, "太字", "bold")
      mes = "太字を処理しました。:#{@f} line- #{@linenum}\n#{line}\n"
   elsif /［＃[^［]*斜体[^［]*］/ =~ line
      line = modify_(line, "斜体", "italic")
      mes = "斜体を処理しました。:#{@f} line- #{@linenum}\n#{line}\n"
   elsif /［＃[^［]*(下線|傍線)[^［]*］/ =~ line
      modify = $1
      line = modify_(line, modify, "underline")
      mes = "#{modify}を処理しました。:#{@f} line- #{@linenum}\n#{line}\n"
   elsif /［＃[^［]*傍点[^［]*］/ =~ line
      line = modify_(line, "傍点", @params["bouten"])
      mes = bouten_message(line)
   end
   return line, mes
end

def modify_(line, reg, modify)
   if /［＃「([^「]+)」[^［]*#{reg}］/ =~ line
      line = modify1(line, $&, modify[0, 1], $1)
   elsif /［＃#{reg}］([^［]+)［＃#{reg}終わ?り］/ =~ line
      line = modify2(line, $&, modify[0, 1], $1)
   elsif /［＃ここから#{reg}］/ =~ line
      @reg = reg
      line = modify_block_open?(line, $&, modify)
   elsif /［＃ここで#{reg}終わ?り］/ =~ line
      line = modify_block_end?(line, $&)
   end
end

def modify1(line, reg, modify, str)
   line.sub!(/#{reg}/, "")
   line.sub!(str, "@<#{modify}>{#{str}}")
end

def modify2(line, reg, modify, str)
   line.sub!(/#{reg}/, "@<#{modify}>{#{str}}")
end

def modify_block_open?(line, reg, modify)
   m = /#{reg}/.match(line)
   line.chomp!
   if /\A#{reg}\z/ =~ line
      line.sub!(/#{reg}/, "//#{modify}{")
   elsif m.pre_match == "" and m.post_match != ""
      line.sub!(/#{reg}/, "//#{modify}{\n")
   elsif m.pre_match != "" and m.post_match == ""
      line.sub!(/#{reg}/, "\n//#{modify}{")
   else
      line.sub!(/#{reg}/, "\n//#{modify}{\n")
   end
end

def modify_block_end?(line, reg)
   @reg = false
   m = /#{reg}/.match(line)
   line.chomp!
   if /\A#{reg}\z/ =~ line
      line.sub!(/#{reg}/, "//}")
   elsif m.pre_match == "" and m.post_match != ""
      line.sub!(/#{reg}/, "//}\n")
   elsif m.pre_match != "" and m.post_match == ""
      line.sub!(/#{reg}/, "\n//}")
   else
      line.sub!(/#{reg}/, "\n//}\n")
   end
end

def set_indent(line)
   mes = "インデントは非対応のため削除します。:#{@f} line- #{@linenum}\n#{line}\n"
   line.sub!(/［＃[^［]*(?:字下げ|字上げ|天付き|地付き)?(?:終わ?り)?］/, "")
   return line, mes
end

def set_quote(line)
   if /［＃ここから罫囲み］/ =~ line
      line = modify_block_open?(line, "［＃ここから罫囲み］", "quote")
      mes = "罫囲みのはじまりを設定しました。:#{@f} line- #{@linenum}\n#{line}\n"
   elsif /［＃ここで罫囲み終わり］/ =~ line
      line = modify_block_end?(line, "［＃ここで罫囲み終わ?り］")
      mes "罫囲みの終わりを設定しました。:#{@f} line- #{@linenum}\n#{line}\n"
   end
   return line, mes
end

def set_image(line, caption1, filename)
   @imgnum += 1
   m = /(〈[^〈]+〉)/.match(line)
   if m
      caption = m
   elsif m.nil? and caption1 != nil
      caption = caption1
   end
   tag = "//image[img#{@imgnum}][#{caption}]{
#{filename}
#{caption}
//}
"
   line.sub!(/［＃(?:[^［]+図|挿絵)（[^（]+\.\w+[^（]*）入る.*(?:〈[^〈]+〉)?］/, tag)
   mes = "画像を設定しました。:#{@f} line- #{@linenum}\n#{line}\n"
   return line, mes
end

def set_gaiji(line)
   result = false
   if /※［＃[^［]+、[^［]*(\d+-\d+-\d+)］/ =~ line
      key = $1
      unless @gaiji[key].nil?
         line.gsub!(/※［＃[^［]+、[^［]*\d+-\d+-\d+］/, @gaiji[key])
         mes = "文字を変換しました。「#{@gaiji[key]}」:#{@f} line- #{@linenum}
#{line}\n"
         result = true
      end
   end
   return line, result, mes
end

def count_up_words(line)
   l = line.gsub(/\n/, "")
   @words = @words + l.size unless /［＃改(?:丁|ページ|段)］/ =~ line
end

def paging(line)
   count_up_words(line)
   if @params["ruby"]
      words_per_page = @words_per_page * 2
   else
      words_per_page = @words_per_page
   end
   if /\A=+\s/ =~ line and 0 < @words #and 2 < @linenum
      l = line.gsub(/\n/, "").size
      unless 0 == @words - l
         line = add_page_befour(line)
         @words = 0
      end
   elsif /［＃改(?:丁|ページ|段)］/ =~ line
      if 0 < @words
         line = add_page_replace(line)
      else
         line = "\n"
      end
      @words = 0
   elsif words_per_page < @words
      line = add_page_after(line)
      @words = 0
   end
   line
end

def add_page_befour(line)
   add_page() + line
end

def add_page_replace(line)
   add_page()
end

def add_page_after(line)
   line + add_page()
end

def add_page
   @linenum += 3
   @pagenum += 1
   pagestr = "\n#{@pagenum}ページ\n\n"
end

@kanji = TEXTDaisy::KANJI
@kana = TEXTDaisy::KANA
def check_ruby(line)
   line2 = line
   lineArray = []
   num = 0
   noruby = []
   while m = /#{@kanji}*｜?#{@kanji}+《[^《]+》#{@kana}*/.match(line2)
      rubyarea = $&; befourstr = m.pre_match #$`
      unless befourstr == ""
         lineArray << befourstr
         noruby << num
         num += 1
      end
      lineArray << rubyarea
      line2.sub!(/#{befourstr}#{rubyarea}/, "")
      num += 1
   end
   unless line2 == ""
      lineArray << line2
      noruby << num
   end
   return lineArray, noruby
end

def split_reading(str, reading)
   rubystr = ""
   readHira = ExchangeKana.new(reading).to_hiragana
   while m = /#{@kana}+/.match(str)
      befour = m.pre_match;  after = m.post_match
      r = /#{m}/.match(readHira)
      if r
         befour_hira = r.pre_match
         after_hira = r.post_match
      else
         befour_hira = nil
         after_hira = nil
      end
      if /#{@kanji}+/ =~ befour and befour_hira != nil
         rubystr = rubystr + "#{befour}《#{befour_hira}》" if @params["ruby"] == "aozora"
         rubystr = rubystr +  "@<ruby>{#{befour},#{befour_hira}}" if @params["ruby"] == "review"
      end
      rubystr =  rubystr + "#{m}"
      str = after; readHira = after_hira
   end
   if /\A#{@kanji}+\z/ =~ str
      rubystr = rubystr + "#{str}《#{readHira}》" if @params["ruby"] == "aozora"
      rubystr = rubystr + "@<ruby>{#{str},#{readHira}}" if @params["ruby"] == "review"
   end
   rubystr
end

def addRuby(line)
   lineArray, noruby = check_ruby(line)
   tagger = @model.createTagger()
   noruby.each {|num|
      @str = ""
      n = tagger.parseToNodeEx(lineArray[num])
      n = n.next
      while n.next do
         ns = n.surfaceEx; nf = n.featureEx
         if @kanji =~ ns
            unless n.reading.nil? or n.pos == "記号"
               rubystr = split_reading(ns, n.reading)
               @str = @str + rubystr
            else
               @str = @str + ns
            end
         else
            @str = @str + ns
         end
         n = n.next
      end
      lineArray[num] = @str
   }
   str = ""
   lineArray.each {|l|
      str = str + l
   }
   str
end

def startMecab
   if @params["wakati"]
      @model = MeCab::Model.new(" -Owakati")
   elsif @params["ruby"]
      @model = MeCab::Model.new
   end
end
def wakati(line)
   lineArray, noruby = check_ruby(line)
   tagger = @model.createTagger()
   noruby.each {|num|
      @str = ""
      wakatiStr = tagger.parseEx(lineArray[num])
      lineArray[num] = wakatiStr
   }
   str = ""
   lineArray.each {|l|
      str = str + l
   }
   str
end

def new_line(lines)
   new_line = ""
   lines.each {|l|
      if @params["paging"]
         new_line = new_line + paging(l)
      else
         new_line = new_line + l
      end
   }
   line = new_line
end

def split4ruby(line)
   if @params["ruby"]
      crstr = ""
      cr = line.count("\n")
      cr.times { crstr = crstr + "\n" }
      l = addRuby(line)
      line = l + crstr
   else
      line
   end
end

def edit(file)
   @f = source_fname = file.chomp
   new_fname = File.basename(source_fname, ".*") + "-edit.txt"
   @efile = File.open(new_fname, "w:UTF-8")
   @imgnum = 0
   @linenum = 0
   @words = 0
   @head = 0
   @poemline = 0
   File.open("#{source_fname}", "r:UTF-8") {|f|
      f.each_line {|line|
         @lineno += 1
         if @params["aozora"]
            if @params["split"] and /^［＃[^［]+］$/ !~ line
                  lines = split_period(line)
            else
               lines = [line]
            end
            lines.each_with_index {|line, i|
               line = aozora(line)
               lines[i] = split4ruby(line)
            }
            line = new_line(lines)
         elsif @params["split"]
            lines = split_period(line)
            lines.each_with_index {|line, i|
               lines[i] = split4ruby(line)
            }
            line = new_line(lines)
         elsif @params["paging"]
            line = addRuby(line) + "\n" if @params["ruby"]
            line = paging(line)
         elsif @params["ruby"]
            line = addRuby(line)
         elsif @params["wakati"]
            line = wakati(line)
         elsif @params["join"]			##
            line = join(line)			##
         end
         if @params["join"] or 0 < @head	##
            @efile.print line			##
         else					##
            @efile.puts line
         end					##
      }
      #@efile.puts(paging("［＃改ページ］")) if @params["paging"]
   }
end

if @params["aozora"]
   load_gaiji()
end

def main
   startMecab if @params["wakati"] or @params["ruby"]
   @lineno = 0
   @pagenum = STARTPAGE
   if ARGV.size != 0
      ARGV.each {|file|
         edit(file)
      }
   elsif File.exists?("SECTIONS")
      File.open("SECTIONS") {|section|
         section.each_line {|file|
            edit(file)
         }
      }
   else
      puts "SECTIONS ファイルがありません。"
   end
   @logfile.close if @params["log"]
end

main
