# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#
#

class TEXTDaisy

   @paragraph_print = false
   @normal_print = false
   @indent = 0

   def zerosuplement(fig, place)
      sprintf("%0#{place}d", fig)
   end

   def xml_header(xmlfile)
      @table_id = 0
      xmlfile.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<?xml-stylesheet href="#{@bookname}.css" type="text/css" media="screen"?>
<?xml-stylesheet href="#{@bookname}.xsl" type="text/xsl" media="screen"?>
<!DOCTYPE dtbook PUBLIC "-//NISO//DTD dtbook 2005-3//EN" "dtbook-2005-3.dtd">
<dtbook xml:lang="#{@meta.language}" version="2005-3" xmlns="http://www.daisy.org/z3986/2005/dtbook/">
  <head>
    <meta name="dc:Title" content="#{@meta.title}" />
    <meta name="dtb:uid" content="#{@meta.iUid}" />
  </head>
  <book>
    <bodymatter>
EOT
      @xindent = 4
   end

   def xml_footer(xmlfile)
      if @normal_print
         @xindent = @xindent - 2
         xmlfile.puts(indent("</p>", @xindent))
         @normal_print = false
      end
      @level.downto(1) {|num|
         @xindent = @xindent - 2
         xmlfile.puts(indent(%Q[</level#{num}>], @xindent))
      }
      xmlfile.puts <<EOT
    </bodymatter>
  </book>
</dtbook>
EOT
   end

   def compile_headline(phr, xmlfile, sectcount)
      befour_level = @level
      @level = phr.args
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      if @level == 1
         @xindent = @xindent + 2
      elsif befour_level >= @level
         befour_level.downto(@level) {|num|
            @xindent = @xindent - 2
            xmlfile.puts(indent(%Q[</level#{num}>], @xindent))
         }
      end
      xmlfile.puts(indent(%Q[<level#{@level}>], @xindent))
      xmlfile.puts(indent(%Q[<h#{phr.args}>], @xindent + 2))
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent + 4))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 6))
         xmlfile.puts(indent(%Q[</sent>], @xindent + 4))
      else
         xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 4))
      end
      xmlfile.puts(indent(%Q[</h#{phr.args}>], @xindent + 2))
      @xindent = @xindent + 2
   end

   def compile_paragraph(xmlfile)
      if @normal_print
         @xindent = @xindent - 2
         xmlfile.puts(indent(%Q[</p>], @xindent))
         @normal_print = false
      else
         xmlfile.puts(indent(%Q[<p />], @xindent))
      end
      @paragraph_print = true
   end

   def compile_annoref(phr, xmlfile, sectcount)
   end

   def compile_noteref(phr, xmlfile, sectcount)
      check_paragraph(xmlfile)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent(%Q[<#{phr.namedowncase} id="#{idstr}" smilref="#{smilstr}" idref="##{idstr.succ}">], @xindent))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         xmlfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
      else
         xmlfile.puts(indent(%Q[<#{phr.namedowncase} id="#{idstr}" smilref="#{smilstr}" idref="##{idstr.succ}">#{phr.phrase}</#{phr.namedowncase}>], @xindent))
      end
      @normal_print = true
   end

   def compile_note(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      xmlfile.puts(indent(%Q[<#{phr.namedowncase} id="#{idstr}" smilref="#{smilstr}">], @xindent))
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent("<p>", @xindent + 2))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 4))
         xmlfile.puts(indent("</p>", @xindent + 2))
      else
         xmlfile.puts(indent(%Q[<p>#{phr.phrase}</p>], @xindent + 2))
      end
      xmlfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
   end

   def compile_prodnote(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      if phr.group.nil?
         compile_prodnote_normal(phr, xmlfile, smilstr, idstr)
      else
         compile_prodnote_group(phr, xmlfile, smilstr, idstr)
      end
   end

   def compile_sidebar(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      xmlfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" id="#{idstr}" smilref="#{smilstr}">], @xindent))
      xmlfile.puts(indent(%Q[<hd>#{phr.caption}</hd>], @xindent + 2)) unless phr.caption.nil?
      phr.phrase.each_line {|p|
         xmlfile.puts(indent(%Q[#{p}], @xindent + 2))
      }
      xmlfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
   end

   def compile_text(phr, xmlfile, sectcount)
      check_paragraph(xmlfile)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         xmlfile.puts(indent(%Q[</sent>], @xindent))
      else
         xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent))
      end
      @normal_print = true
   end

   def compile_quote(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      xmlfile.puts(indent(%Q[<blockquote id="#{idstr}" smilref="#{smilstr}">], @xindent))
      phr.phrase.each_line {|p|
         xmlfile.puts(indent(%Q[#{p}], @xindent + 2))
      }
      xmlfile.puts(indent(%Q[</blockquote>], @xindent))
   end

   def compile_pagenum(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent(%Q[<pagenum id="#{idstr}" smilref="#{smilstr}" page="#{phr.namedowncase}">], @xindent))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         xmlfile.puts(indent(%Q[</pagenum>], @xindent))
      else
         xmlfile.puts(indent(%Q[<pagenum id="#{idstr}" smilref="#{smilstr}" page="#{phr.namedowncase}">#{phr.phrase}</pagenum>], @xindent))
      end
   end

   def compile_table(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      tabref = compile_table_id(phr.args, sectcount)
      num, row, column = phr.get_table
      if phr.phrase == "" and phr.caption != nil
         xmlfile.puts(indent(%Q[<table border="1" smilref="#{tabref}">], @xindent))
         xmlfile.puts(indent(%Q[<caption id="#{idstr}" smilref="#{smilstr}">#{phr.caption}</caption>], @xindent + 2))
      elsif 1 == num
#      num, row, column = phr.get_table
#      if 1 == num
#         tabref = compile_table_id(sectcount)
#         phr.uid = @table_id
#         tabref = compile_table_id(phr.args, sectcount)
         xmlfile.puts(indent(%Q[<table border="1" smilref="#{tabref}">], @xindent)) if phr.caption.nil?
         xmlfile.puts(indent("<tr>", @xindent + 2))
         xmlfile.puts(indent(%Q[<#{phr.tag}>], @xindent + 4))
         if /\A</ =~ phr.phrase
            xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent + 6))
            xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 8))
            xmlfile.puts(indent("</sent>", @xindent + 6))
         else
            xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 6))
         end
         xmlfile.puts(indent(%Q[</#{phr.tag}>], @xindent + 4))
      elsif row * column == num
         table_sentence(phr, xmlfile, smilstr, idstr)
         xmlfile.puts(indent("</tr>", @xindent + 2))
         xmlfile.puts(indent("</table>", @xindent))
      elsif num % column == 0 && num < row * column
         table_sentence(phr, xmlfile, smilstr, idstr)
         xmlfile.puts(indent("</tr>", @xindent + 2))
      elsif num % column == 1
         xmlfile.puts(indent("<tr>", @xindent + 2))
         table_sentence(phr, xmlfile, smilstr, idstr)
      else
         table_sentence(phr, xmlfile, smilstr, idstr)
      end
   end

   def compile_image(phr, xmlfile)
      @img_list << phr.phrase
      xmlfile.puts(indent(%Q[<img src="image/#{phr.phrase}" id="#{phr.args}" alt="#{phr.caption}" width="#{phr.width}" height="#{phr.height}" />], @xindent))
   end

   def compile_caption(phr, xmlfile, sectcount)
      smilstr, idstr = compile_id(sectcount, phr)
      phr.ncxsrc = smilstr
      xmlfile.puts(indent(%Q[<caption id="#{idstr}" smilref="#{smilstr}" imgref="#{phr.ref}">#{phr.phrase}</caption>], @xindent))
   end

   def compile_imagegroup(phr, xmlfile)
      if phr.start?
         xmlfile.puts(indent(%Q[<imggroup id="#{phr.args}">], @xindent))
         @xindent = @xindent + 2
      else
         @xindent = @xindent - 2
         xmlfile.puts(indent(%Q[</imggroup>], @xindent))
      end
   end


   def smil_header(smilfile)
      smilfile.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE smil PUBLIC "-//NISO//DTD dtbsmil 2005-1//EN" "dtbsmil-2005-2.dtd">
<smil xmlns="http://www.w3.org/2001/SMIL20/">
  <head>
    <meta name="dtb:uid" content="#{@meta.iUid}" />
    <meta name="dtb:generator" content="#{GENERATOR}" />
    <meta name="dtb:totalElapsedTime" content="#{@xmeta.totalElapsedTime}" />
    <customAttributes>
      <customTest id="normal" defaultState="#{@skippable.normal}" override="visible" />
      <customTest id="front" defaultState="#{@skippable.front}" override="visible" />
      <customTest id="special" defaultState="#{@skippable.special}" override="visible" />
      <customTest id="note" defaultState="#{@skippable.note}" override="visible" />
      <customTest id="noteref" defaultState="#{@skippable.noteref}" override="visible" />
      <customTest id="annotation" defaultState="#{@skippable.annotation}" override="visible" />
      <customTest id="linenum" defaultState="#{@skippable.linenum}" override="visible" />
      <customTest id="sidebar" defaultState="#{@skippable.sidebar}" override="visible" />
      <customTest id="prodnote" defaultState="#{@skippable.prodnote}" override="visible" />
    </customAttributes>
  </head>
  <body>
EOT
      @indent = 2
      @seq = Hash.new(0)
   end

   def smil_footer(smilfile)
      smilfile.puts <<EOT
    </seq>
  </body>
</smil>
EOT
      @indent = 0
   end

   def compile_smil_headline(phr, smilfile, xmlfile)
      xmlfilename, phrnum, tnum = set_smil_num(xmlfile, phr)
      @seq["seq"] += 1
      smilfile.puts <<EOT
    <seq id="seq#{@seq["seq"]}">
      <par id="phr#{phrnum}">
        <text src="#{xmlfilename}.xml#t#{tnum}" />
      </par>
EOT
      @indent = 6
   end

   def compile_smil_customtest(phr, smilfile, xmlfile)
      xmlfilename, phrnum, tnum = set_smil_num(xmlfile, phr)
      smilfile.puts <<EOT
      <par id="phr#{phrnum}" customTest="#{phr.namedowncase}">
        <text src="#{xmlfilename}.xml#t#{tnum}" />
      </par>
EOT
   end

   def compile_smil_table(phr, smilfile, xmlfile)
      xmlfilename, phrnum, tnum = set_smil_num(xmlfile, phr)
      now, row, column = phr.get_table
         seqid = phr.args
         tblend = phr.readid + (row * column - 1)
         tblendid = zerosuplement(tblend, 5)
      if phr.phrase == "" and phr.caption != nil
         smilfile.puts(indent(%Q[<seq id="tab#{seqid}" class="table" end="DTBuserEscape;phr#{tblendid.succ}.end">], @indent))
         table_par(phrnum, smilfile, xmlfilename, tnum)
      elsif 1 == now
         smilfile.puts(indent(%Q[<seq id="tab#{seqid}" class="table" end="DTBuserEscape;phr#{tblendid}.end">], @indent)) if phr.caption.nil?
         table_par(phrnum, smilfile, xmlfilename, tnum)
      elsif row * column == now
         table_par(phrnum, smilfile, xmlfilename, tnum)
         smilfile.puts(indent(%Q[</seq>], @indent))
      else
         table_par(phrnum, smilfile, xmlfilename, tnum)
      end
   end

   def compile_smil_text(phr, smilfile, xmlfile)
      xmlfilename, phrnum, tnum = set_smil_num(xmlfile, phr)
      smilfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent))
      smilfile.puts(indent(%Q[<text src="#{xmlfilename}.xml#t#{tnum}" />], @indent + 2))
      smilfile.puts(indent(%Q[</par>], @indent))
   end

   def compile_smil_image(phr, smilfile, xmlfile)
   end


   ZENKIGOU = Regexp.new("[！”＃＄％＆’（）＝～｜￥「」＜＞｛｝【】『』〔〕≪≫・；：＋＊－／＠‘　、。]")
   ZENEISU = Regexp.new("[０-９ａ-ｚＡ-Ｚ]")
   KANA = Regexp.new("[ぁ-ゖァ-ヺー]")
   KANJI = Regexp.new("[^#{KANA}#{ZENEISU}#{ZENKIGOU}!-~]")

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
         else
            print_error("未定義のインラインタグです : #{str}")
         end
         str.sub!(/@#{type}{#{args}}/, tag)
      end
      if /@<\w+>/ =~ str
         print_error("インラインタグの文法が違っているようです : #{str}")
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

   def compile_prodnote_normal(phr, xmlfile, smilstr, idstr)
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" id="#{idstr}" smilref="#{smilstr}">], @xindent))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         xmlfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
      else
         xmlfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</#{phr.namedowncase}>], @xindent))
      end
   end

   def compile_prodnote_group(phr, xmlfile, smilstr, idstr)
      if /\A</ =~ phr.phrase
         xmlfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" imgref="#{phr.ref}" id="#{idstr}" smilref="#{smilstr}">], @xindent))
         xmlfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         xmlfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
      else
         xmlfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" imgref="#{phr.ref}" id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</#{phr.namedowncase}>], @xindent))
      end
   end

   def check_paragraph(xmlfile)
      if @paragraph_print
         xmlfile.puts(indent("<p>", @xindent))
         @paragraph_print = false
         @xindent = @xindent + 2
      end
   end

   def table_sentence(phr, xmlfile, smilstr, idstr)
      xmlfile.puts(indent(%Q[<#{phr.tag}>], @xindent + 4))
      xmlfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 6))
      xmlfile.puts(indent(%Q[</#{phr.tag}>], @xindent + 4))
   end

   def compile_id(sectcount, phr)
      id = zerosuplement(phr.totalid, 7)
      smilnum = zerosuplement(sectcount, 5)
      phrnum = zerosuplement(phr.readid, 5)
      idstr = "t#{id}"
      smilstr = "#{PTK}#{smilnum}.smil#phr#{phrnum}"
      return smilstr, idstr
   end

#   def compile_table_id(sectcount)
   def compile_table_id(args, sectcount)
      smilnum = zerosuplement(sectcount, 5)
      @table_id += 1
#      tablenum = zerosuplement(@table_id, 5)
#      tabref = "#{PTK}#{smilnum}.smil#tab#{tablenum}"
      tableid = args
      tabref = "#{PTK}#{smilnum}.smil#tab#{tableid}"
      return tabref
   end

   def set_smil_num(xmlfile, phr)
      unless phr.readid == nil
         phrnum = zerosuplement(phr.readid, 5)
         tnum = zerosuplement(phr.totalid, 7)
      end
      xmlfilename = File.basename(xmlfile, ".xml")
      return xmlfilename, phrnum, tnum
   end

   def table_par(phrnum, smilfile, xmlfilename, tnum)
      smilfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent + 2))
      smilfile.puts(indent(%Q[<text src="#{xmlfilename}.xml#t#{tnum}" />], @indent + 4))
      smilfile.puts(indent(%Q[</par>], @indent + 2))
   end

   def print_error(errmes)
      raise errmes
#      STDERR.puts errmes
      exit 1
   end

end