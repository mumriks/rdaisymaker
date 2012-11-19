# encoding: utf-8
# Copyright (c) 2011 Kishida Atsushi
#

class Daisy
   @indent = 0

   ZENKIGOU = Regexp.new("[！”＃＄％＆’※（）＝～｜￥「」＜＞｛｝【】『』〔〕≪≫〈〉［］―…・；：＋＊－／＠‘　、。]")
   ZENEISU = Regexp.new("[０-９ａ-ｚＡ-Ｚ]")
   HIRA = Regexp.new("[ぁ-ゖ]")
   KATA = Regexp.new("[ァ-ヺー]")
   KANA = Regexp.new("[#{HIRA}#{KATA}]")
   KANJI = Regexp.new("[^#{KANA}#{ZENEISU}#{ZENKIGOU}!-~\s]")

   def zerosuplement(fig, place)
      sprintf("%0#{place}d", fig)
   end

   def compile_paragraph(phr)
      if @header
         @header = false
         if 2 == phr.arg
            @xfile.puts(indent("<p />", @xindent))
         elsif 2 < phr.arg
            (phr.arg - 1).times { @xfile.puts(indent("<p />", @xindent)) }
         end
      elsif @ptag
         @ptag = false
         @xindent -= 2
         if 2 > phr.arg
            @xfile.puts(indent("</p>", @xindent))
         elsif 2 == phr.arg
            @xfile.puts(indent("</p>", @xindent))
            @xfile.puts(indent("<p />", @xindent))
         elsif 2 < phr.arg
            @xfile.puts(indent("</p>", @xindent))
            (phr.arg - 2).times { @xfile.puts(indent("<p />", @xindent)) }
         end
      elsif !@header and !@ptag
         if 2 == phr.arg
            @xfile.puts(indent("<p />", @xindent))
         elsif 2 < phr.arg
            (phr.arg - 1).times { @xfile.puts(indent("<p />", @xindent)) }
         end
      end
   end

   def compile_plain_tag(phr)
      @xfile.puts(indent("<#{phr.tag}>", @xindent))
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

   def compile_indent(tag)
      if /\Ax[1-9]?|\A[1-9]/ =~ tag.indent
         if @ptag
            @xindent -= 2
            @xfile.puts(indent("</p>", @xindent))
            @ptag = false
         end
         @xfile.puts(indent(%Q[<div class="indent_#{tag.indent}">], @xindent))
         @xindent += 2
      elsif /-/ =~ tag.indent
         @m_indent = true
      elsif tag.terminal
         @xindent -= 2
         if @m_indent
            @xfile.puts(indent("</div>", @xindent))
            @m_indent = false
         elsif @ptag
            @xfile.puts(indent("</p>", @xindent))
            @xfile.puts(indent("</div>", @xindent - 2))
            @xindent -= 2
            @ptag = false
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
      unless @header
         unless @ptag
            if @m_indent
               @xfile.puts(indent(%Q[<p class="indent_-1">], @xindent))
            else
               @xfile.puts(indent("<p>", @xindent))
            end
            @xindent += 2
            @ptag = true
         end
      end
   end

   def compile_table_id(arg)
      smilnum = zerosuplement(@sectcount, 5)
      tabref = "#{PTK}#{smilnum}.smil#es#{arg}"
      return tabref
   end

   def set_smil_num(phr)
      unless phr.readid == nil
        if @daisy2
            phrnum = phr.readid
            tnum = phr.totalid
        else
         phrnum = zerosuplement(phr.readid, 5)
         tnum = zerosuplement(phr.totalid, 7)
        end
      end
      xmlfilename = File.basename(@xfile)
      return xmlfilename, phrnum, tnum
   end

   def footnote_sentence?(phr)
      return true if phr.instance_of?(Note::Sentence)
      return true if phr.instance_of?(Annotation::Sentence)
      return true if phr.instance_of?(Prodnote::Sentence)
      return true if phr.instance_of?(Sidebar::Caption)
      return true if phr.instance_of?(Sidebar::Sentence)
      return false
   end

   def list_sentence?(phr)
      return true if phr.instance_of?(Li::Sentence)
      return true if phr.instance_of?(Dt::Sentence)
      return true if phr.instance_of?(Dd::Sentence)
      return false
   end

   def note_with_ref?(phr)
      return true if phr.instance_of?(Note) and !phr.ref.nil?
      return true if phr.instance_of?(Annotation) and !phr.ref.nil?
      return false
   end

end
