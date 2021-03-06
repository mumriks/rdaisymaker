#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright (c) 2011, 2012 Kishida Atsushi
#
#

require 'yaml'
require 'fileutils'
require 'optparse'
require 'tempfile'

VERSION = "0.3.1"
DAISYM = "R DAISY Maker ver #{VERSION}"
DNAME = "rdm"
PLEXTALK = "PLEXTALK DAISY Producer ver 0.2.4.0"
PNAME = "ptk"
@params = {"ptk" => DNAME, "generator" => DAISYM,
           "type" => nil, "pagedirection" => nil,
           "yomi" => false, "datehiv" => true, "colophon" => false}

parser = OptionParser.new
scriptfile = File.basename($0)
parser.banner = "Usage: ruby #{scriptfile} [options] config.yaml"
parser.on('-P', 'Set generator all at PLEXTALK Producer.') {
   @params["ptk"] = PNAME
   @params["generator"] = PLEXTALK
   puts "producer mode lite."
}
parser.on('-p', 'Set generator only at PLEXTALK Producer.') {
   @params["generator"] = PLEXTALK
   puts "producer mode."
}
parser.on('-3', '--to-text3', 'build textNCX'){
   @params["type"] = 'textNCX'
   puts "テキストデイジー図書を作成します。"
}
parser.on('-4', '--to-text4', 'build textDAISY4 epub3(横組)'){
   @params["type"] = 'textDAISY4'
   @params["pagedirection"] = "ltr"
   puts "EPUB3 図書を作成します（テキストのみ）。"
}
parser.on('--rtl', '文字組みを縦組にする (epub3)'){
   @params["pagedirection"] = "rtl"
   puts "文字を縦組みにします。"
}
parser.on('--rtl-date', '縦組み、日付縦中横個別処理 (epub3)'){
   @params["pagedirection"] = "rtl"
   @params["datehiv"] = false
   puts "文字を縦組みにし、日付の縦中横処理を個別に行います（暫定）。"
}
parser.on('-c', '--hiv-colophon', '縦組み図書に横書き指定があれば適用する'){
   @params["colophon"] = true
   puts "縦組み図書に横書き指定があれば適用します。"
}
parser.on('--yomi', '漢字に読み情報があれば設定'){
   @params["yomi"] = true
   puts "読み情報を使用します。"
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

BINDIR = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH << File.join(BINDIR, "../lib")
require 'rdm/daisy'
require 'rdm/phrase'
require 'rdm/ncxbuilder'
require 'rdm/opfbuilder'
require 'rdm/rdm'

def new_chapter
   @chapter = Chapter.new
   @daisy.add_chapter(@chapter)
end

def new_section
   @sect = Section.new
   @chapter.add_section(@sect)
   @sectcount += 1
   @rdm.noterefNum = 0
end

def level_mes(phr)
   "レベルが深すぎるか、インデントが不正です : #{File.basename(@rdm.file)} line:#{@rdm.lineno}\n#{phr}"
end

def no_headline
   "見出し文字もナビ文字もありません : #{File.basename(@rdm.file)} line:#{@rdm.lineno}\n"
end

PARAGRAPH = /^[\s　]*$/

def make_paragraph
   if 0 < @paCount
      obj = Paragraph.new(@paCount)
      @paCount = 0
      return obj
   end
end

def has_navstr?(phr)
   if /@<navi>{([^}]+)}/ =~ phr
      navstr = $1
      return phr.sub!(/@<navi>{[^}]+}/, ""), navstr
   else
      return phr, nil
   end
end

def make_headline(phr)
   arg = phr.slice(/=+/).size
   phr2, navstr = has_navstr?(phr.sub(/=+\s/, ''))
   if /\A@<indent>{([^,]+),([^}]+)}/ =~ phr2
      indent = $1
      phr2 = $2
   end
   print_error(no_headline) if '' == phr2 and navstr.nil?
   h = Headline.new(arg, indent) if Headline.valid_args?(arg, indent)
   print_error(level_mes(phr)) unless h
   hs = @rdm.make_sentence(phr2, 'Headline::Sentence', arg)
   hs.set_navstr(navstr)
   if @daisy.kind_of?(Daisy3)
      hs.phrase = navstr if '' == phr2
   end
   new_chapter() if arg == 1
   new_section()
   return [h, hs, h.dup.post]
end

def check_phrase_type(phrase)
   objs = []
   phr = phrase.chomp
   case phr
   when /\A=+[\s]/
      pr = make_paragraph()
      heads = make_headline(phr)
      if @sect.phrases.empty?
         objs << heads
      else
         objs << pr
         objs << heads
      end
   when %r<\A//\}>
      mes = "ブロックのはじまりが見つかりません : \n#{File.basename(@rdm.file)} line:#{@rdm.lineno}\n#{phr}"
      print_error(mes)
   when %r<\A//[a-z]+>
     @type = nil
      pr = make_paragraph()
      objs << pr if pr
      objs << read_type(phr)
   when /@<fn>/
      pr = make_paragraph()
      objs << pr if pr
      objs << @rdm.make_sentence(phr)
      @daisy.skippable.noteref = 'false'
   when /@<an>/
      pr = make_paragraph()
      objs << pr if pr
      objs << @rdm.make_sentence(phr)
      @daisy.skippable.annoref = 'false'
   when PARAGRAPH
      @paCount += 1
   when /\A[fFsS]?:?[0-9０-９]+(?:ページ|ぺーじ)?\z/
      pr = make_paragraph()
      objs << pr if pr
      objs << make_page(phr)
   else
      pr = make_paragraph()
      objs << pr if pr
      str = phr
      str, mes = @daisy.compile_inline_tag(str)
      print_error(mes + "#{File.basename(@rdm.file)}, line:#{@rdm.lineno}\n#{str}") unless mes.nil?
      objs << Sentence.new(phr)
   end
   @rdm.lineno += 1
   return objs.flatten
end

def read_type(phr)
   objs = []
   type = phr.slice(/[a-z]+/)
   case type
   when /\Atable(b?)\z/
      phr, args = read_phrase(phr)
      check_args(args, type)
      objs << table_block(phr, args, $1)
   when /\Aimage\z/
      phr, args = read_phrase(phr)
      check_args(args, type)
      objs << image_block(phr, args)
   when /\Afootnote\z/
      @type = 'Note'
      phr, args = read_phrase(phr)
      check_args(args, type)
      @daisy.skippable.note = "false"
      objs << note_block(phr, args, @type)
   when /\Aannotation\z/
      @type = 'Annotation'
      phr, args = read_phrase(phr)
      check_args(args, type)
      @daisy.skippable.annotation = "false"
      objs << note_block(phr, args, @type)
   when /\Aprodnote\z/
      @type = 'Prodnote'
      phr, args = read_phrase(phr)
      check_args(args, type)
      @daisy.skippable.prodnote = "false"
      objs << note_block(phr, args, @type)
   when /\Asidebar\z/
      @type = 'Sidebar'
      phr, args = read_phrase(phr)
      check_args(args, type)
      @daisy.skippable.sidebar = "false"
      objs << note_block(phr, args, @type)
   when /\Aline\z/
      @type = 'Line'
      phr, args = read_phrase(phr)
      @daisy.skippable.linenum = "false" unless args[0].nil?
      objs << line_num_block(phr, args)
   when /\Apoem\z/
      phr, args = read_phrase(phr)
      objs << poem_block(phr, args)
   when /\Aquote(.?)\z/
      @type = 'Quote'
      phr, args = read_phrase(phr)
      args[0] = $1 if args[0].nil?
      objs << note_block(phr, args, @type)
   when /\Aitalic\z/
      phr, args = read_phrase(phr)
      objs << modify_sentence(phr, 'italic')
   when /\Abold\z/
      phr, args = read_phrase(phr)
      objs << modify_sentence(phr, 'bold')
   when /\Aunderline\z/
      phr, args = read_phrase(phr)
      objs << modify_sentence(phr, 'underline')
   when /\Aindent\z/
      phr, args = read_phrase(phr)
      objs << indent_block(phr, args)
   when /\Alist\z/
      phr, args = read_phrase(phr)
      objs << list_block(phr, args)
   when /\Ahorizontal\z/, /\Acolophon\z/
      @@type = type
      phr, args = read_phrase(phr)
      objs << horizontal_block(phr, args)
   else
      mes = "未定義のタグです : //#{@type}\n#{File.basename(@rdm.file)} line:#{@rdm.lineno}\n#{phr}"
      print_error(mes)
   end
   return objs
end

def read_phrase(phr)
   args = parse_args(phr.sub(%r<\A//[a-z]+>, '').rstrip.chomp('{'))
   phrs = block_open?(phr) ? read_block(@rdm.file) : nil
   return phrs, args
end

def parse_args(str)
   return [] if str.empty?
   unless str[0,1] == '[' and str[-1,1] == ']'
      mes = "引数の文法が違うようです : #{str}\n#{File.basename(@rdm.file)} line:#{@rdm.lineno}\n#{str}"
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
   block = nil
   f.each_line {|line|
      if %r<\A//\}> =~ line
         break
      elsif %r!\A//[a-z]+! =~ line
         block = read_type(line)
         buf.push block
         c += block.size
         @rdm.lineno += c
      else
         buf.push line.rstrip
         c += 1
         @rdm.lineno += c
         if f.eof?
            mes = "ブロックの終りが見つかりませんでした。(始まりは #{buf})\n#{File.basename(@rdm.file)} line:#{@rdm.lineno}"
            print_error(mes)
         end
      end
   }
   return buf
end

def check_args(args, type)
   unless 1 == args.size or 2 == args.size
      mes = "引数の文法が違うようです : #{type}[#{args}]\n#{File.basename(@rdm.file)} line:#{@rdm.lineno}"
      print_error(mes)
   end
end

def table_block(phr, args, border)
   objs = []
   @rdm.first_sentence = nil
   unless phr.size == 0
      tbl = Table.new(args[0], border)
      objs << tbl
      @rdm.tagids[args[0]] << ["#{File.basename(@rdm.file)} - line:#{@rdm.lineno}", tbl]
      objs << @rdm.make_table_caption(args) unless args[1].nil?
      th, row, column, table = @rdm.get_table_structure(phr)
      theader = {}
      table = @rdm.table_header(phr) unless th == ''
      table.each_with_index {|tr, i|
         objs << Tr.new
         cc = 0
         tr.each {|td|
            cc = cc + 1
            num = column * i.to_i + cc
            tag = @rdm.table_tag(num)
            if td.kind_of?(Array)
               objs << @rdm.valid_syntax_at_table?(td)
            elsif "" == td
               objs << eval("#{tag}.new.null")
            else
               cells, @ts = @rdm.make_table_cell(tag, td)
               objs << cells
            end
         }
         if cc < column
            (column - cc).times {|c|
               num = column * i.to_i + c
               tag = @rdm.table_tag(num)
               objs << eval("#{tag}.new.null")
            }
         end
         objs << Tr.new.post
      }
      objs << Table.new(args[0]).post
      @rdm.first_sentence.arg = args[0] if args[1].nil?
      @rdm.first_sentence.endcell = @ts
   else
      @rdm.not_table_data(args)
   end
   return objs
end

def image_block(phr, args)
   objs = []
   img = nil
   pnotes = []
   group = []
   phr.each {|p|
      if p.kind_of?(Array)
         if @rdm.valid_syntax_at_image?(p)
            group << p
            pnotes << p[0]
            p[0].group = args[0]
         end
      elsif /\A[fFsS]?:?[0-9０-９]+(?:ページ|ぺーじ)?\z/ =~ p
         @rdm.not_page_in_image
      else
         if img.instance_of?(Image)
            if Daisy::FT_IMAGE =~ p
               mes, image = @daisy.check_imagefile(p)
               img = @rdm.make_image(mes, image, args)
               img.width, img.height = set_image_size("#{@daisy.i_path}/#{image}")
               group << img
            elsif img.alt.nil?
               img.alt = p.gsub(/《[^》]+》/, "")
            else
               @rdm.invalid_phrase_in_image(p)
            end
         else
            mes, image = @daisy.check_imagefile(p)
            img = @rdm.make_image(mes, image, args)
            img.width, img.height = set_image_size("#{@daisy.i_path}/#{image}")
            group << img
         end
      end
   }
   print_error(Daisy::ERRMES["errmes1"] + where) if @rdm.imgcount == 0
   pnotes.each {|pn| pn.ref = @rdm.imgids.rstrip }
   objs << @rdm.make_image_group(group, args)
   return objs
end

def set_image_size(file)
   width, height = @daisy.get_image_size(file)
   return width, height
end

def check_image_size
   unless 0 == @rdm.big_image.size
      puts "次の画像は推奨サイズ(#{Daisy::IMGWIDTH}x#{Daisy::IMGHEIGHT})よりも大きいです。"
      @rdm.big_image.uniq.each {|img|
         width, height = Daisy::get_image_size(img)
         puts "#{img} (#{width} x #{height})"
      }
      if @daisy.kind_of?(Daisy3)
         print_error("図書作成を終了します。")
#      elsif @daisy.kind_of?(Daisy4)
#         print_error("図書作成を終了します。(4)")
      end
   end
end

def indent_block(phr, args)
   objs = []
   pr = make_paragraph()
   objs << pr if pr
   if Indent.valid_indent?(args[0])
      if 'Quote' == @type
         @i = Quote::Indent.new(args[0])
      elsif 'Line' == @type
         @i = Line::Indent.new(args[0])
      else
         @i = Indent.new(args[0])
      end
   end
   objs << @i
   phr.each_with_index {|ph, i|
      if ph.kind_of?(Array)
         objs << ph
         next
      elsif PARAGRAPH =~ ph
         @paCount += 1
      elsif /\A[fFsS]?:?[0-9０-９]+(?:ページ|ぺーじ)?\z/ =~ ph
         pr = make_paragraph()
         objs << pr if pr
         objs << make_page(ph)
      else
         pr = make_paragraph()
         objs << pr if pr
         if @type
            objs << @rdm.make_sentence(ph, "#{@type}::Sentence", "bis#{i}")
         else
            objs << @rdm.make_sentence(ph, "Sentence", "is#{i}")
         end
      end
   }
   pr = make_paragraph()
   objs << pr if pr
   objs << @i.dup.post
   return objs
end

def note_block(phr, args, type)
   objs = []
   line = @rdm.check_phrase_size(type, phr)
   @n = @rdm.make_note_pre(args, type)
   objs << @n
   unless line == 0
      @paCount = 0
      @rdm.first_sentence = nil
      phr.each_with_index {|p, i|
         if p.kind_of?(Array)
            if @rdm.valid_syntax_at_note?(p)
               objs << p
               next
            end
         end
         case type
         when 'Quote'
            if PARAGRAPH =~ p
               @paCount += 1
            else
               pr = make_paragraph()
               objs << pr if pr
               objs << @rdm.make_sentence(p, 'Quote::Sentence')
            end
         when 'Note', 'Annotation'
            if PARAGRAPH =~ p
               @paCount += 1
            else
               pr = make_paragraph()
               objs << pr if pr
               if line == i + 1
                  ns = @rdm.make_sentence(p, "#{type}::Sentence", "#{args[0]}-E")
               else
                  ns = @rdm.make_sentence(p, "#{type}::Sentence", "#{args[0]}-#{i}")
               end
               objs << ns
               @rdm.first_sentence = ns if @rdm.first_sentence.nil?
               @rdm.skipChainList << [args[0], Skip.new(@rdm.file, @rdm.lineno, ns)]
            end
         when 'Prodnote', 'Sidebar'
            if PARAGRAPH =~ p
               @paCount += 1
            else
               pr = make_paragraph()
               objs << pr if pr
               if args[1] and @rdm.first_sentence.nil?
                  objs << @rdm.sidebar_caption(args[1])
               end
               if line == i + 1
                  ns = @rdm.make_sentence(p, "#{type}::Sentence", "ps#{@rdm.nCount}-E")
               else
                  ns = @rdm.make_sentence(p, "#{type}::Sentence", "ps#{@rdm.nCount}-#{i}")
               end
               objs << ns
               @rdm.first_sentence = ns if @rdm.first_sentence.nil?
            end
        end
      }
   else
      @rdm.no_sentence_in_note(type, args)
   end
   pr = make_paragraph()
   objs << pr if pr
   objs << @n.dup.post
   @n.ncxsrc = @rdm.first_sentence unless 'Quote' == type
   return objs
end

def modify_sentence(phr, tag)
   objs = []
   phr.each {|p|
      if PARAGRAPH =~ p
         objs << Paragraph.new.null
      else
         str, mes = @daisy.compile_inline_tag(p)
         print_error(mes + "#{File.basename(@rdm.file)}, line:#{@rdm.lineno}\n#{str}") unless mes.nil?
         sent = eval ("@daisy.tag_#{tag}(str)")
         objs << @rdm.make_sentence(sent, 'Sentence')
      end
   }
   return objs
end

def list_block(phr, args)
   objs = []
   list, type, id = @rdm.list_pre(phr[0], args)
   objs << list
   list_num = phr.size - 1
   phr.each_with_index {|p, i|
      @rdm.not_data_in_list if '' == p
      if p.kind_of?(Array)
         if @rdm.valid_syntax_at_list?(p)
#            objs << p
         end
      end
      case i
      when 0
         if 'dl' == type
            if /\A:\s+/ =~ p
               @dd = false
               objs << @rdm.make_dt(p, id)
            else
               @rdm.not_dt_data(p)
            end
         else
            objs << @rdm.make_li(p, id)
         end
      when list_num
         if 'dl' == type
            if /\A:\s+/ =~ p
               @rdm.not_dd_data(p)
            else
               objs << Dd.new unless @dd
               objs << @rdm.make_dd(p, "#{id}-E")
            end
         else
            objs << @rdm.make_li(p, "#{id}-E")
         end
      else
         if 'dl' == type
            if /\A:\s+/ =~ p
               if @dd
                  @dd = false
                  objs << Dd.new.post
                  objs << @rdm.make_dt(p)
               else
                  @rdm.not_dd_data(p)
               end
            else
               unless @dd
                  @dd = true
                  objs << Dd.new
               end
               objs << @rdm.make_sentence(p, "Dd::Sentence")
            end
         else
            objs << @rdm.make_li(p)
         end
      end
   }
   objs << list.dup.post
   list.ncxsrc = @rdm.first_sentence
   return objs
end

def horizontal_block(phr, args)
   objs = []
   div = Div.new
   div.style = @@type
   objs << div
   phr.each {|line|
      if line.kind_of?(Array)
         objs << line
      else
         objs << check_phrase_type(line)
      end
   }
   objs << div.dup.post
   return objs
end

def poem_block(phr, args)
   unless args[0].nil?
      num = args[0].empty? ? nil : args[0].to_i
   end
   objs = make_line(phr, num, true)
   unless args[1].nil?
      title = args[1].empty? ? nil : args[1]
   end
   unless args[2].nil?
      author = args[2].empty? ? nil : args[2]
   end
   objs.unshift Poem::Author.new(author) unless author.nil?
   objs.unshift Poem::Title.new(title) unless title.nil?
   pm = Poem.new("pm#{@rdm.nCount}")
   objs.unshift pm
   @rdm.nCount += 1
   objs.push pm.dup.post
   return objs
end

def line_num_block(phr, args)
   unless args[0].nil?
      num = args[0].empty? ? nil : args[0].to_i
   end
   objs = make_line(phr, num, false)
   lg = Linegroup.new("lg#{@rdm.nCount}")
   lg.startnum = num
   objs.unshift lg
   @rdm.nCount += 1
   objs.push lg.dup.post
   return objs
end

def make_line(phr, num, poem)
   objs = []
   phr.each {|line|
      if line.kind_of?(Array)
         if poem
            objs << line if @rdm.valid_syntax_at_poem?(line)
         else
            objs << line if @rdm.valid_syntax_at_linegroup?(line)
         end
      elsif PARAGRAPH =~ line
         next
      elsif /\A[fFsS]?:?[0-9０-９]+(?:ページ|ぺーじ)?\z/ =~ line
         objs << make_page(line)
      elsif /\A@<date>{(.+)}\z/ =~ line
         date = $1
         objs << Dateline.new("dl#{@rdm.nCount}")
         @rdm.nCount += 1
         objs << @rdm.make_sentence(date, "Dateline::Sentence")
         objs << Dateline.new.post
      else
         objs << Line.new("l#{@rdm.nCount}")
         @rdm.nCount += 1
         objs << @rdm.make_sentence(num.to_s, "Linenum::Sentence") unless num.nil?
         num += 1 unless num.nil?
         objs << @rdm.make_sentence(line, "Line::Sentence")
         objs << Line.new.post
      end
   }
   @paCount += 1 if 2 > @paCount
   return objs
end

def make_page(phr)
   case phr.chomp
   when /\A[0-9０-９]+(?:ページ|ぺーじ)?\z/
      @daisy.skippable.normal = "false"
      return Normal.new(phr)
   when /\A[fF]:[0-9０-９]+(?:ページ|ぺーじ)?\z/
      @daisy.skippable.front = "false"
      return Front.new(phr)
   when /\A[sS]:[0-9０-９]+(?:ページ|ぺーじ)?\z/
      @daisy.skippable.special = "false"
      return Special.new(phr)
   end
end

def set_skippable_mark
   if 0 < @rdm.skippable.size
      @rdm.skippable.each {|s|
         eval "@daisy.skippable.#{s} = 'false'"
      }
   end
end

def set_readid
   @daisy.book.each {|chapter|
      totalid = 0
      chapter.sections.each {|section|
         readid = 0
         section.phrases.each {|phr|
            if phr.kind_of?(Phrase)
               if @rdm.noterefS?(phr)
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
               else
                  if phr.totalid.nil?
                     totalid += 1
                     phr.totalid = totalid
                  end
                  if phr.readid.nil?
                     readid += 1
                     phr.readid = readid
                  end
               end
            end
         }
      }
   }
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
      unless debug.nil?
         puts "デバッグモードで実行しています。\n"
      end

      values["multimediaType"] = @params["type"] unless @params["type"].nil?
      values["pagedirection"] = @params["pagedirection"] unless @params["pagedirection"].nil?

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
         @daisy.yomi = @params["yomi"]
      when /textDAISY4/
         @daisy = TEXTDaisy4.new(values)
         @daisy.datehiv = @params["datehiv"]
         @daisy.hivColophon = @params["colophon"]
         @daisy.yomi = @params["yomi"]
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
      @paCount = 0
      @rdm = RDM.new
      if File.exists?("SECTIONS")
         File.open("SECTIONS") {|section|
            section.each_line {|file|
               next if /^#/ =~ file
               if /\Acover(?:.txt)?/ =~ file
                  @daisy.build_cover(file.chomp)
                  next
               end
               File.open("#{file.chomp}", "r:UTF-8") {|f|
                  @rdm.lineno = 1
                  @rdm.file = f
                  f.each_line {|phrase|
                     objs = check_phrase_type(phrase)
                     objs.each {|o| @sect.add_phrase(o) }
                  }
                  pr = make_paragraph()
                  @sect.add_phrase(pr) if pr
               }
               @rdm.refNum_unity?(file)
            }
         }
      else
         mes = "SECTIONS ファイルが見つかりません。作成してから再実行してください。"
         print_error(mes)
      end
      @rdm.check_same_args?()
      check_image_size()
      @rdm.skippable_check()
      set_skippable_mark()
      @rdm.set_note_ref_chain()
      set_readid()
      @daisy.build_daisy
      @daisy.copy_files
      FileUtils.rm_r(temp) if debug.nil?
   rescue => err
      STDERR.puts $0, err
      FileUtils.rm_r(temp) if debug.nil? and File.exist?(temp)
      FileUtils.rm_r(bookname) if debug.nil? and File.exist?(bookname)
   end
end

def print_error(errmes)
   raise errmes.encode("SJIS")
   exit 1
end

main
