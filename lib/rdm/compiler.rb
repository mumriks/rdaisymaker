# encoding: utf-8
# Copyright (c) 2011 Kishida Atsushi
#

class Daisy
   @paragraph_print = false
   @normal_print = false
   @indent = 0

   ZENKIGOU = Regexp.new("[！”＃＄％＆’（）＝～｜￥「」＜＞｛｝【】『』〔〕≪≫・；：＋＊－／＠‘　、。]")
   ZENEISU = Regexp.new("[０-９ａ-ｚＡ-Ｚ]")
   KANA = Regexp.new("[ぁ-ゖァ-ヺー]")
   KANJI = Regexp.new("[^#{KANA}#{ZENEISU}#{ZENKIGOU}!-~]")

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
            inline_tag_syntax_err(str) unless /.+,.+/ =~ args
            kanji, ruby = args.split(/,/)
            tag = tag_ruby(kanji, ruby, 'review')
         when '<i>'
            tag = tag_italic(args)
         when '<b>'
            tag = tag_bold(args)
         when '<u>'
            tag = tag_underline(args)
         when '<s>'
            tag = tag_sesamedot(args) if self.kind_of?(Daisy4)
            tag = check_instead(str, args) if self.kind_of?(Daisy3)
         else
            print_error("未定義のインラインタグです : \n#{str}")
         end
         str.sub!(/@#{type}{#{args}}/, tag)
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
      %Q[<span class="sesamedot">#{args}</span>]
#      print_error("まだ傍点は未設定：daisy4")
   end

   def check_instead(str, args)
      if self.sesame.nil?
         print_error("傍点の処理が設定されていません : \n#{str}")
      else
         eval("tag_#{self.sesame}(args)")
      end
   end

   private

   def tag_ruby(kanji, ruby, type)
      k = kanji.gsub(/[\s　]/, '')
      r = ruby.gsub(/[\s　]/, '')
      rubytag = "@<ruby>{#{k},#{r}}" if 'review' == type
      rubytag = "#{k}《#{r}》" if 'daisy' == type
      unless /#{KANA}+/ =~ r
         errmes = "ルビタグの読み部分が違っているようです : #{rubytag}"
         print_error(errmes)
      end
      unless /#{KANJI}+/ =~ k
         errmes = "ルビタグの漢字部分が違っているようです : #{rubytag}"
         print_error(errmes)
      end
      tag = %Q!<span class="ruby">#{k}<span class="rp">（</span><span class="rt">#{r}</span><span class="rp">）</span></span>!
   end

   def indent(str, n)
      str.gsub(/^/, " " * n)
   end

   def check_paragraph
      if @paragraph_print
         @xfile.puts(indent("<p>", @xindent))
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
