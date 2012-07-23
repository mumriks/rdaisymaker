# encoding: utf-8
# Copyright (c) 2011 Kishida Atsushi
#

class Daisy
   @paragraph_print = false
   @normal_print = false
   @indent = 0

   ZENKIGOU = Regexp.new("[！”＃＄％＆’（）＝～｜￥「」＜＞｛｝【】『』〔〕≪≫・；：＋＊－／＠‘　、。]")
   ZENEISU = Regexp.new("[０-９ａ-ｚＡ-Ｚ]")
#   KANA = Regexp.new("[ぁ-ゖァ-ヺー]")
   HIRA = Regexp.new("[ぁ-ゖ]")
   KATA = Regexp.new("[ァ-ヺー]")
   KANA = Regexp.new("[#{HIRA}#{KATA}]")
#   KANJI = Regexp.new("[^#{KANA}#{ZENEISU}#{ZENKIGOU}!-~]")
   KANJI = Regexp.new("[^#{KANA}#{ZENEISU}#{ZENKIGOU}!-~\s]")

   def zerosuplement(fig, place)
      sprintf("%0#{place}d", fig)
   end

   def compile_paragraph
      if @normal_print
         @xindent = @xindent - 2
         @xfile.puts(indent(%Q[</p>], @xindent))
         @normal_print = false
      else
         @xfile.puts(indent(%Q[<p />], @xindent))
      end
      @paragraph_print = true
   end

   def compile_daisy_ruby(str)
      while /｜?(#{KANJI}+)《([^《]+)》/ =~ str
         kanji = $1
         ruby = $2
         tag = tag_ruby(kanji, ruby, 'daisy')
         str.sub!(/｜?#{kanji}《#{ruby}》/, tag)
      end
      str
   end

   def compile_inline_tag(str)
      while /@(<[a-z]+>){([^{]+?)}/ =~ str
         type = $1
         args = $2
         case type
         when '<ruby>'
            unless /.+,.+/ =~ args
               mes = "ルビタグの文法が違うようです：#{str}"
               print_error(mes)
            end
            kanji, ruby = args.split(/,/)
            tag = tag_ruby(kanji, ruby, 'review')
         when '<i>'
            tag = tag_italic(args)
         when '<b>'
            tag = tag_bold(args)
         when '<u>'
            tag = tag_underline(args)
         when '<s>'
            if self.kind_of?(Daisy3)
               @sesame = true
               tag = ""
ruby = false
               args.scan(/./).each {|s|
ruby = true if "《" == s
                  tag += tag_sesamedot(s) unless ruby
ruby = false if "》" == s
               }
            else
               tag = tag_sesamedot(args)
            end
         when '<sup>'
            tag = tag_sup(args)
         when '<sub>'
            tag = tag_sub(args)
         when '<vih>'
            tag = tag_vih(args)
         when '<date>'
            tag = tag_date(args)
         when '<indent>'
            tag = tag_indent(args)
            if "err" == tag
               print_error("記法が違っているようです : \n#{str}")
            end
         else
            print_error("未定義のインラインタグです : \n#{str}")
         end
         str.sub!(/@#{type}\{#{args}\}/, tag)
      end
      if /@<\w+>/ =~ str
         print_error("インラインタグの文法が違っているようです : \n#{str}")
      end
      str
   end

   def tag_italic(args)
      "<em>#{args}</em>"
   end
   def tag_bold(args)
      "<strong>#{args}</strong>"
   end
   def tag_underline(args)
      %Q[<span class="underline">#{args}</span>]
   end
   def tag_sesamedot(args)
      %Q[<span class="sesame_dot">#{args}</span>]
   end
   def tag_sup(args)
      "<sup>#{args}</sup>"
   end
   def tag_sub(args)
      "<sub>#{args}</sub>"
   end

   def compile_indent(args)
      if /\Ax?[1-9]/ =~ args
         @xfile.puts(indent(%Q[<div class="indent_#{args}">], @xindent))
         @xindent += 2
      elsif /-/ =~ args
         @m_indent = true
      elsif "end" == args
         if @normal_print
            if @m_indent
               @xfile.puts(indent("</p>", @xindent - 2))
               @xindent -= 2
               @m_indent = false
            else
               @xfile.puts(indent("</p>", @xindent - 2))
               @xfile.puts(indent("</div>", @xindent - 4))
               @xindent -= 4
            end
            @normal_print = false
         else
            @xfile.puts(indent("</div>", @xindent))
         end
      end
   end

   private

   def indent(str, n)
      str.gsub(/^/, " " * n)
   end

   def check_paragraph
      if @paragraph_print
         if @m_indent
            @xfile.puts(indent(%Q[<p class="indent_-1">], @xindent))
         else
            @xfile.puts(indent("<p>", @xindent))
         end
         @paragraph_print = false
         @xindent = @xindent + 2
      end
   end

   def table_sentence(phr, smilstr, idstr)
      @xfile.puts(indent(%Q[<#{phr.tag}>], @xindent + 4))
      @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 6))
      @xfile.puts(indent(%Q[</#{phr.tag}>], @xindent + 4))
   end

   def compile_table_id(args)
      smilnum = zerosuplement(@sectcount, 5)
      @table_id += 1
      tableid = args
      tabref = "#{PTK}#{smilnum}.smil#tab#{tableid}"
      return tabref
   end

   def set_smil_num(phr)
      unless phr.readid == nil
         phrnum = zerosuplement(phr.readid, 5)
         tnum = zerosuplement(phr.totalid, 7)
      end
      xmlfilename = File.basename(@xfile)
      return xmlfilename, phrnum, tnum
   end

   def table_par(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent + 2))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" />], @indent + 4))
      @sfile.puts(indent(%Q[</par>], @indent + 2))
   end

   def print_error(errmes)
      raise errmes
#      STDERR.puts errmes
      exit 1
   end

end
