#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#
#

require 'yaml'
require 'fileutils'
require 'optparse'
require 'tempfile'

VERSION = "0.2.0a"
DAISYM = "R DAISY Maker ver #{VERSION}"
DNAME = "rdm"
PLEXTALK = "PLEXTALK DAISY Producer ver 0.2.4.0"
PNAME = "ptk"
@params = {"ptk" => DNAME, "generator" => DAISYM,
           "type" => nil, "sesame" => nil}

parser = OptionParser.new
scriptfile = File.basename($0)
parser.banner = "Usage: ruby #{scriptfile} [options] config.yaml"
parser.on('-P', 'Set generator all at PLEXTALK Producer.') {
   @params["ptk"] = PNAME
   @params["generator"] = PLEXTALK
}
parser.on('-p', 'Set generator only at PLEXTALK Producer.') {
   @params["generator"] = PLEXTALK
}
parser.on('--textncx', 'build textNCX'){
   @params["type"] = 'textNCX'
}
parser.on('--textdaisy4', 'build textDAISY4 epub3'){
   @params["type"] = 'textDAISY4'
}
parser.on('--bb', '傍点を太字で代用（daisy3のみ）'){
   @params["sesame"] = 'bold'
}
parser.on('--bu', '傍点を下線で代用（daisy3のみ）'){
   @params["sesame"] = 'underline'
}
parser.on('--bi', '傍点を斜体で代用（daisy3のみ）'){
   @params["sesame"] = 'italic'
}
parser.on('-v', '--version', 'バージョン情報を表示') {
   puts "#{DAISYM}"
   exit 0
}
parser.on('-h', '--help', 'このヘルプを表示して終了') {
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
GENERATOR =  @params["generator"]
puts "producer mode." if GENERATOR == PLEXTALK

BINDIR = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH << File.join(BINDIR, "../lib")
require 'rdm/daisy'
require 'rdm/phrase'
#require 'compiler'
require 'rdm/ncxbuilder'
require 'rdm/opfbuilder'

def new_chapter
   @chapter = Chapter.new
   @daisy.add_chapter(@chapter)
end

def new_section
   @sect = Section.new
   @chapter.add_section(@sect)
   @sectcount += 1
end

def check_phrase_type(f)
   f.each_line {|phrase|
      phr = phrase.chomp
      case phr
      when /\A=+[\s]/
         args = phr.slice(/=+/).size
         phr2 = phr.sub(/=+\s/, '')
         @p = Headline.new(phr2, args)
         unless @p.valid_args?
            mes = "レベルが深すぎます : #{File.basename(f)} line:#{@lineno}\n#{phr}"
            print_error(mes)
         end
         new_chapter() if args == 1
         new_section()
         @sect.add_phrase(@p)
      when %r<\A//\}>
         mes = "ブロックのはじまりが見つかりません : \n#{File.basename(f)} line:#{@lineno}\n#{phr}"
         print_error(mes)
      when %r<\A//[a-z]+>
         read_type(phr, f)
      when /@<fn>/
         read_reftype(phr)
      when /@<an>/
         read_reftype(phr)
      when /^[\s　]*$/
         @p = Paragraph.new("<p />")
         @sect.add_phrase(@p)
      when /\A[0-9０-９]+(?:ページ|ぺーじ)?\z/
         @daisy.skippable.normal = "false"
         @p = Normal.new(phr)
         @sect.add_phrase(@p)
      when /\A[fF]:[0-9０-９]+(?:ページ|ぺーじ)?\z/
         @daisy.skippable.front = "false"
         @p = Front.new(phr)
         @sect.add_phrase(@p)
      when /\A[sS]:[0-9０-９]+(?:ページ|ぺーじ)?\z/
         @daisy.skippable.special = "false"
         @p = Special.new(phr)
         @sect.add_phrase(@p)
      else
         str = phr
         @daisy.compile_inline_tag(str)
         @p = Sent.new(phr)
         @sect.add_phrase(@p)
      end
      @lineno += 1
   }
end

def read_type(phr, f)
   type = phr.slice(/[a-z]+/)
   case type
   when /\Atable\z/
      phr, args = read_phrase(phr, f)
      check_args(args, type)
      table_flat(phr, args)
      @tagids[args[0]] << Table.new("#{File.basename(f)} - line:#{@lineno}", args[0])
   when /\Aimage\z/
      phr, args = read_phrase(phr, f)
      check_args(args, type)
      check_image(phr, args)
   when /\Afootnote\z/
      phr, args = read_phrase(phr, f)
      type = 'Note'
      check_args(args, type)
      @daisy.skippable.note = "false"
      note_flat(phr, args, type)
   when /\Aannotation\z/
      phr, args = read_phrase(phr, f)
      type = 'Annotation'
      check_args(args, type)
      @daisy.skippable.annotation = "false"
      note_flat(phr, args, type)
   when /\Aprodnote\z/
      phr, args = read_phrase(phr, f)
      type = 'Prodnote'
      check_args(args, type)
      @daisy.skippable.prodnote = "false"
      note_flat(phr, args, type)
   when /\Asidebar\z/
      phr, args = read_phrase(phr, f)
      type = 'Sidebar'
      check_args(args, type)
      @daisy.skippable.sidebar = "false"
      note_flat(phr, args, type)
#   when /\Alinenum\z/
#
   when /\Aquote\z/
      phr, args = read_phrase(phr, f)
      type = 'Quote'
      note_flat(phr, args, type)
   when /\Aitalic\z/
      phr, args = read_phrase(phr, f)
      sent_flat(phr, "italic")
   when /\Abold\z/
      phr, args = read_phrase(phr, f)
      sent_flat(phr, "bold")
   when /\Aunderline\z/
      phr, args = read_phrase(phr, f)
      sent_flat(phr, "underline")
   else
      mes = "未定義のタグです : //#{type}\n#{File.basename(f)} line:#{@lineno}\n#{phr}"
      print_error(mes)
   end
end

def read_reftype(phrase)
   mes = "引数の文法が違うようです : #{phrase}\n#{File.basename(@f)} line:#{@lineno}"
   if /@<fn>{([^{]+?)}/ =~ phrase
      args = $1
      print_error(mes)  unless /\A[a-z0-9_-]+\z/ =~ $1
      phr = phrase.sub(/@<fn>{[^{]+}/, '')
      @daisy.skippable.noteref = "false"
      p = Noteref.new(phr, args)
      @skip_list[args] << Skip.new(@f, @lineno, p)
   elsif @daisy.instance_of?(TEXTDaisy)
      mes = "使用できないタグです : #{phrase}\n#{File.basename(@f)} line:#{@lineno}"
      print_error(mes)
   elsif /@<an>\[([^\[]+)\]{([^{]+?)}/ =~ phrase
      args, keyword = $1, $2
      print_error(phrase)  unless /\A[a-z0-9_-]+\z/ =~ $1
#      @daisy.skippable.annoref = "false"
      exstr = %Q[<annoref idref="##{args}">#{keyword}</annoref>]
      phr = phrase.sub(/@<an>\[[^\[]+\]{[^{]+}/, exstr)
      p = Annoref.new(phr, args)
      @skip_list[args] << Skip.new(@f, @lineno, p)
   else
      print_error(mes)
   end
   @sect.add_phrase(p)
end

def read_phrase(phr, f)
   args = parse_args(phr.sub(%r<\A//[a-z]+>, '').rstrip.chomp('{'))
   phrs = block_open?(phr) ? read_block(f) : nil
   return phrs, args
end

def parse_args(str)
   return [] if str.empty?
   unless str[0,1] == '[' and str[-1,1] == ']'
      mes = "引数の文法が違うようです : #{str}\n#{File.basename(@f)} line:#{@lineno}\n#{str}"
      print_error(mes)
      return []
   end
   str[1..-2].split('][', -1)
end

def block_open?(phr)
   phr.rstrip[-1,1] == '{'
end

def read_block(f)
   buf = []
   c = 0
   f.each_line {|line|
      if %r<\A//\}> =~ line
         break
      else
         buf.push line.rstrip
         c = c + 1
         if f.eof?
            mes = "ブロックの終りが見つかりませんでした。(始まりは #{buf})\n#{File.basename(@f)} line:#{@lineno}"
            print_error(mes)
            return buf
         end
      end
   }
   no = f.lineno
   no = no + c
   f.lineno = no
   @lineno += c
   buf
end

def check_args(args, type)
   unless 1 == args.size or 2 == args.size
      mes = "引数の文法が違うようです : #{type}[#{args}]\n#{File.basename(@f)} line:#{@lineno}"
      print_error(mes)
   end
end

def table_header(th, row, column)
   row = row + 1
   theader = {}
   case th
   when /-+/
      table_header_column(theader, column)
   when /\|+/
      table_header_row(theader, column, row)
   when /\++/
      table_header_column(theader, column)
      table_header_row(theader, column, row)
   end
   theader
end

def table_header_column(theader, column)
   (1..column).each {|n|
      theader["#{n}"] = 'th'
   }
end

def table_header_row(theader, column, row)
   1.step(row * (column - 1), column) {|n|
      theader["#{n}"] = 'th'
   }
end

def table_tag(theader, num)
   if theader["#{num}"] == 'th'
      tag = 'th'
   else
      tag = 'td'
   end
   tag
end

def table_flat(phr, args)
   unless phr.size == 0
# v caption
#=begin
      unless args[1].nil?
         @capt = Table.new("", args)
         @sect.add_phrase(@capt)
      end
#=end
# ^ caption
      row = phr.size
      column = 0
      table = []
      t = []
      th = ''
      phr.each {|r|
         t = r.split(/\s/)
         if /[-\|\+]+/ =~ t.to_s
            th = t[0].to_s
            row = row - 1
         else
            table << t
         end
         column = t.size if column < t.size
      }
      theader = {}
      theader = table_header(th, row, column) unless th == ''
      table.each_with_index {|tr, i|
         cc = 0
         tr.each {|td|
            cc = cc + 1
            num = column * i.to_i + cc
            tag = table_tag(theader, num)
            p = Table.new(td, args)
            p.set_table(num, row, column, tag)
            @sect.add_phrase(p)
         }
         if cc < column
            (column - cc).times {|c|
               num = column * i.to_i + c
               tag = table_tag(theader, num)
               p = Table.new("　", args)
               p.set_table(num, row, column, tag)
               @sect.add_phrase(p)
            }
         end
      }
# v caption
#=begin
      @capt.set_table(0, row, column, '') if @capt
#=end
# ^ caption
   else
      mes = "テーブルのデータがありません :  //table#{args}\n#{File.basename(@f)} line:#{@lineno}"
      print_error(mes)
   end
end

def image_group_set(sw, args)
   ig = ImageGroup.new(args)
   eval ("ig.#{sw}")
   @sect.add_phrase(ig)
end

def check_image(phr, args)
   em = {"errmes1" => "画像ファイルが指定されていません '//image[#{args}]{'",
    "errmes2" => "そのファイルは見つかりません : ",
    "errmes3" => "サポートされていない画像タイプです : ",
    "errmes4" => " は画像サイズが大きすぎます Max:#{Daisy::IMGWIDTH}*#{Daisy::IMGHEIGHT} : "}
   where = "\n#{File.basename(@f)} line:#{@lineno}"
   @imgcount = 0
   @imgids = ""
   @pnotes = []
   @group = []
   phr.each {|p|
      if /\A@<pn>(?:\[(.+)?\])?{([^{]+)}/ =~ p
         @daisy.skippable.prodnote = "false"
         render, phrase = $1, $2
         @o = Prodnote.new(phrase, render)
         result = @o.valid_render?
         unless result
            mes = "render の指定が違っているようです : [#{render}]" + where
            print_error(mes)
         end
         @pnotes << @o
         @o.group = args[0]
      elsif /\A[0-9０-９]+(?:ページ|ぺーじ)?\z/ =~ p
         @daisy.skippable.normal = "false"
         @o = Normal.new(p)
      elsif /\A[fF]:[0-9０-９]+(?:ページ|ぺーじ)?\z/ =~ p
         @daisy.skippable.front = "false"
         @o = Front.new(p)
      elsif /\A[sS]:[0-9０-９]+(?:ページ|ぺーじ)?\z/ =~ p
         @daisy.skippable.special = "false"
         @o = Special.new(p)
      else
         unless File.exist?(p)
            if @o.instance_of?(Image)
               @o.caption = p
            end
            next
         end
         @imgcount += 1
         @imgids = @imgids + "#{args[0]}-#{@imgcount} "
         result = @daisy.check_imagefile(p)
         print_error(em["#{result}"] + p + where) if /errmes[1-3]/ =~ result
         print_error("'#{p}'" + em["#{result}"] + where) if /errmes4/ =~ result
         @o = Image.new(result, "#{args[0]}-#{@imgcount}")
         width, height = @daisy.get_image_size(p)
         @o.width = width; @o.height = height
         @tagids[@o.args] << Image.new("#{File.basename(@f)} - line:#{@lineno}", @o.args)
      end
      @group << @o
   }
   print_error(em["errmes1"] + where) if @imgcount == 0
   @pnotes.each {|pn|
      pn.ref = @imgids.rstrip
   }

   image_group_set("start", args[0]) if @group.size > 1 or args[1]
   @group.each {|obj|
      if obj.instance_of?(Image)
         @imgcount -= 1
         obj.ref = @imgids.rstrip
         @sect.add_phrase(obj)
         if @imgcount == 0 and args[1]
#            c = Caption.new(args[1])
#            c.ref = @imgids.rstrip
#            @sect.add_phrase(c)
            @caption = Caption.new(args[1])  ## <<120401
            @caption.ref = @imgids.rstrip    ## <<120401
         end
      else
         @sect.add_phrase(obj)
      end
   }
## >>120402
   if @caption
      @sect.add_phrase(@caption)  ## <<120401
      @caption = nil
   end
## <<120402
   image_group_set("finish", args[0]) if @group.size > 1 or args[1]
end

def note_flat(phr, args, type)
   line = phr.size
   unless line == 0
      if 'Note' == type or 'Annotation' == type
         notes = [] if line > 1
      end
      str = ""
      phr.each {|p|
         str = str + p + "\n"
         next if 'Sidebar' == type or 'Quote' == type
         pp = eval ("#{type}.new(p, args)")
         @sect.add_phrase(pp)
         if 'Prodnote' == type
            result = pp.valid_render?
            unless result
               mes = "render の指定が違っているようです : [#{args}]\n#{File.basename(@f)} line:#{@lineno}"
               print_error(mes)
            end
            next
         end
         @skip_list[args[0]] << Skip.new(@f, @lineno, pp) if notes.nil?
         notes << pp unless notes.nil?
      }
      if 'Sidebar' == type #or 'Quote' == type
         str.chomp!
#         str.sub!(/\n/, "</p>\n<p>")
#         strs = "<p>" + str + "</p>"
#         pp = eval ("#{type}.new(strs, args)")
         pp = eval ("#{type}.new(str, args)")
         @sect.add_phrase(pp)
         if pp.instance_of?(Sidebar)
            result = pp.valid_render?
            unless result
               mes = "render の指定が違っているようです : [#{args}]\n#{File.basename(@f)} line:#{@lineno}"
               print_error(mes)
            end
         end
# Quote 変更ここから
      elsif 'Quote' == type
         q = Quote.new
         lines = str.split(/\n/)
         lines.each {|line|
            q.add_lines(line)
         }
         @sect.add_phrase(q)
# Quote 変更ここまで
      end
      unless notes.nil?
         ns = eval ("#{type}s.new(str, args)")
         ns.notes = notes
         @skip_list[args[0]] << Skip.new(@f, @lineno, ns)
      end
   else
      type = 'footnote' if type == 'Note'
      mes = "注釈本文がありません : //#{type.downcase}#{args}
#{File.basename(@f)} line:#{@lineno}"
      print_error(mes)
   end
end

def sent_flat(phr, tag)
   phr.each {|p|
      if /^[\s　]*$/ =~ p
         s = Paragraph.new("<p />")
         @sect.add_phrase(s)
      else
         str = @daisy.compile_inline_tag(p)
         sent = eval ("@daisy.tag_#{tag}(str)")
         s = Sent.new(sent)
         @sect.add_phrase(s)
      end
   }
end

def check_same_args?
   @tagids.each {|key, t|
      if t.size != 1
         tagstr = ""
         t.each {|obj|
            tagstr = tagstr + "#{obj.phrase} //#{obj.namedowncase}[#{key}]\n"
         }
         mes = "異なるタグで同じ識別子を使っているようです :\n" + tagstr
         print_error(mes)
      end
   }
end

def skippable_check
   check_skipable_syntax(@skip_list) if @skip_list != nil
end

def check_skipable_syntax(skip_list)
   check_note_ref_pare(skip_list)
   check_note_ref_order(skip_list)
end

def check_note_ref_order(skip_list)
   skip_list.each {|key, skip|
      ref = 0
      note = 0
      skip.each_with_index {|s, i|
         @sf = s.file
         @sl = s.lineno
         @so = s.obj
         ref = i if noteref?(s.obj)
         note = i if note?(s.obj) or notes?(s.obj)
         ref = i if annoref?(s.obj)
         note = i if annotation?(s.obj) or annotations?(s.obj)
      }
      if ref > note
         mes = "注釈と注釈番号の順序が反対のようです : [#{key}]
#{@sf} line:#{@sl}\n#{@so.phrase}"
         print_error(mes)
      end
   }
end

def check_note_ref_pare(skip_list)
   skip_list.each {|key, skip|
      ref = 0
      note = 0
      skip.each {|s|
         @sf = s.file
         @sl = s.lineno
         @so = s.obj
         ref += 1 if noteref?(s.obj)
         note += 1 if note?(s.obj)
         note += 1 if notes?(s.obj)
         ref += 1 if annoref?(s.obj)
         note += 1 if annotation?(s.obj)
         note += 1 if annotations?(s.obj)
      }
      unless ref == 0
         mes = ""
         if ref > 1
            mes = "同じ識別子を持った注釈番号が複数あるようです [#{key}]
#{@sf} line:#{@sl}\n#{@so.phrase}"
            print_error(mes)
         elsif note > 1
            mes = "同じ識別子を持った注釈が複数あるようです [#{key}]
#{@sf} line:#{@sl}\n#{@so.phrase}"
            print_error(mes)
         elsif ref > note
            mes = "注釈番号 [#{key}] に対応する注釈が見つかりません
#{@sf} line:#{@sl}\n#{@so.phrase}"
            print_error(mes)
         elsif ref < note
            mes = "注釈番号 [#{key}] に対応する注釈が複数あるようです
#{@sf} line:#{@sl}\n#{@so.phrase}"
            print_error(mes)
         end
      end
   }
end

def set_note_ref_chain
   child = nil
   @skip_list.each {|key, skip|
      skip.reverse_each {|s|
         if notes?(s.obj) or annotations?(s.obj)
            s.obj.notes.reverse.each {|n|
               unless child.nil?
                  n.child = child
               end
               child = n
            }
         elsif note?(s.obj) or annotation?(s.obj)
            unless child.nil?
               s.obj.child = child
            end
            child = s.obj
         elsif noteref?(s.obj) or annoref?(s.obj)
            unless child.nil?
               s.obj.child = child
            end
            child = nil
         end
      }
      child = nil
   }
end

def set_readid
   @daisy.book.each {|chapter|
      totalid = 0
      chapter.sections.each {|section|
         readid = 0
         section.phrases.each {|phr|
            if noteref?(phr)
               totalid += 1
               readid += 1
               phr.totalid = totalid
               phr.readid = readid
               p = phr
               until p.child.nil?
                  totalid += 1
                  readid += 1
                  p.child.totalid = totalid
                  p.child.readid = readid
                  p = p.child
               end
            elsif parag?(phr) or image?(phr) or imggrp?(phr)
               next
            else
               totalid += 1
               readid += 1
               phr.totalid = totalid if phr.totalid.nil?
               phr.readid = readid if phr.readid.nil?
            end
         }
      }
   }
end

def note?(obj)
   obj.instance_of?(Note)
end
def notes?(obj)
   obj.instance_of?(Notes)
end
def noteref?(obj)
   obj.instance_of?(Noteref)
end
def annotation?(obj)
   obj.instance_of?(Annotation)
end
def annotations?(obj)
   obj.instance_of?(Annotations)
end
def annoref?(obj)
   obj.instance_of?(Annoref)
end
def parag?(obj)
   obj.instance_of?(Paragraph)
end
def image?(obj)
   obj.instance_of?(Image)
end
def imggrp?(obj)
   obj.instance_of?(ImageGroup)
end

def main
   begin
      if ARGV.size != 1
         yamls = Dir.glob("*.yaml")
         if 0 == yamls.size
            script = File.basename($0)
            puts "Usage: ruby #{script} configfile(yaml)"
            puts "yaml ファイルが見つかりませんでした。"
            exit 0
         else
            puts "yaml ファイルが指定されないので、'#{yamls[0]}' を使用します。"
         end
      end

      yamlfile = ARGV[0].nil? ? yamls[0] : ARGV[0]
      values = YAML.load_file(yamlfile)
      debug = values["debug"]

      values["multimediaType"] = @params["type"] unless @params["type"].nil?

      bookname = File.basename(yamlfile, ".yaml")
      if File.exist?(bookname)
         mes = "#{bookname} ディレクトリが既に存在します。先に削除するか名前を変えてから実行してください。"
         STDERR.puts mes
         exit 0
      end
      temp = debug.nil? ? Dir.mktmpdir : "."
      case values["multimediaType"]
      when /textNCX/
         @daisy = TEXTDaisy.new(values)
         @daisy.sesame = @params["sesame"]
      when /textDAISY4/
         @daisy = TEXTDaisy4.new(values)
      when nil
         mes = "処理を終了します。
yaml ファイルもしくは、オプションで図書タイプを指定してください。"
         print_error(mes)
      else
         mes = "残念ですが、今のところテキストデイジーにしか対応していません。"
         print_error(mes)
      end
      @daisy.bookname = bookname
      @daisy.mk_temp(temp)
      @sectcount = 0
      ti = Hash.new {|ti, key| ti[key] = []}
      @tagids = ti
      s = Hash.new {|s, key| s[key] = []}
      @skip_list = s
      if File.exists?("SECTIONS")
         File.open("SECTIONS") {|section|
            section.each_line {|file|
               if /\Acover(?:.txt)?/ =~ file
                  @daisy.build_cover(file.chomp)
                  next
               end
               File.open("#{file.chomp}", "r:UTF-8") {|f|
                  @lineno = 1
                  @f = f
                  check_phrase_type(f)
               }
            }
         }
      else
         mes = "SECTIONS ファイルが見つかりません。作成してから再実行してください。"
         print_error(mes)
      end
      check_same_args?
      skippable_check()
      set_note_ref_chain()
      set_readid()
      @daisy.build_daisy
      @daisy.build_ncx
      @daisy.build_opf
      @daisy.copy_files
      FileUtils.rm_r(temp) if debug.nil?
   rescue => err
      STDERR.puts err
      FileUtils.rm_r(temp) if debug.nil? and File.exist?(temp)
      FileUtils.rm_r(bookname) if debug.nil? and File.exist?(bookname)
   end
end

def print_error(errmes)
   raise errmes.encode("SJIS")
#   STDERR.puts errmes
   exit 1
end

main
