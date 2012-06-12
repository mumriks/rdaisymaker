# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#

require 'rdm/compiler'

class TEXTDaisy

   def xml_header
      @table_id = 0
      @xfile.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<?xml-stylesheet href="#{@bookname}.css" type="text/css" media="screen"?>
<?xml-stylesheet href="#{@bookname}.xsl" type="text/xsl" media="screen"?>
<!DOCTYPE dtbook PUBLIC "-//NISO//DTD dtbook 2005-3//EN" "dtbook-2005-3.dtd">
<dtbook xml:lang="#{@meta.language}" version="2005-3" xmlns="http://www.daisy.org/z3986/2005/dtbook/">
  <head>
    <meta name="dc:Title" content="#{@meta.title}" />
    <meta name="dtb:uid" content="#{@meta.iUid}" />
    <link rel="stylesheet" type="text/css" href="#{@bookname}.css" />
  </head>
  <book>
    <bodymatter>
EOT
      @xindent = 4
   end

   def xml_footer
      if @normal_print
         @xindent = @xindent - 2
         @xfile.puts(indent("</p>", @xindent))
         @normal_print = false
      end
      @level.downto(1) {|num|
         @xindent = @xindent - 2
         @xfile.puts(indent(%Q[</level#{num}>], @xindent))
      }
      @xfile.puts <<EOT
    </bodymatter>
  </book>
</dtbook>
EOT
   end

   def compile_headline(phr)
      befour_level = @level
      @level = phr.args
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      if @level == 1
         @xindent = @xindent + 2
      elsif befour_level >= @level
         befour_level.downto(@level) {|num|
            @xindent = @xindent - 2
            @xfile.puts(indent(%Q[</level#{num}>], @xindent))
         }
      end
      phr.phrase.sub!(/^[\s　]+/, "")
      @xfile.puts(indent(%Q[<level#{@level}>], @xindent))
      if phr.indent
         @xfile.puts(indent(%Q[<h#{phr.args} class="indent_#{phr.indent}">], @xindent + 2))
      else
         @xfile.puts(indent(%Q[<h#{phr.args}>], @xindent + 2))
      end
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent + 4))
         @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 6))
         @xfile.puts(indent(%Q[</sent>], @xindent + 4))
      else
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 4))
      end
      @xfile.puts(indent(%Q[</h#{phr.args}>], @xindent + 2))
#      @xindent = @xindent + 2
   end

   def compile_annoref(phr)
   end

   def compile_noteref(phr)
      check_paragraph()
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
=begin
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<#{phr.namedowncase} id="#{idstr}" smilref="#{smilstr}" idref="##{idstr.succ}">], @xindent))
         @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
      else
         @xfile.puts(indent(%Q[<#{phr.namedowncase} id="#{idstr}" smilref="#{smilstr}" idref="##{idstr.succ}">#{phr.phrase}</#{phr.namedowncase}>], @xindent))
      end
=end
      phr.phrase.gsub!(/fnr/, phr.namedowncase)
      phr.phrase.sub!(/id=""/, %Q[id="#{idstr}-ref"])
      phr.phrase.sub!(/idref="#"/, %Q[idref="##{idstr.succ}"])
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent))
         @xfile.puts(indent(%Q[#{preStr}#{phr.phrase}#{postStr}], @xindent + 2))
         @xfile.puts(indent(%Q[</sent>], @xindent))
      else
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent))
      end
#
      @normal_print = true
   end

   def compile_note(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      @xfile.puts(indent(%Q[<#{phr.namedowncase} id="#{idstr}" smilref="#{smilstr}">], @xindent))
      phrase = check_refstr(phr)
      if /\A</ =~ phrase #phr.phrase
         @xfile.puts(indent("<p>", @xindent + 2))
         @xfile.puts(indent("#{phrase}", @xindent + 4))
         @xfile.puts(indent("</p>", @xindent + 2))
      else
#         @xfile.puts(indent(%Q[<p>#{phr.phrase}</p>], @xindent + 2))
         @xfile.puts(indent(%Q[<p>#{phrase}</p>], @xindent + 2))
      end
      @xfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
   end

   def check_refstr(phr)
      unless phr.noteref.nil?
         phr.cut_brace
         phrase = "#{phr.noteref}:#{phr.phrase} 注、終わり。"
      else
         phrase = phr.phrase
      end
      return phrase
   end

   def compile_prodnote(phr)
      if phr.group.nil?
         compile_prodnote_normal(phr)
      else
         compile_prodnote_group(phr)
      end
   end

   def compile_sidebar(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      @xfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" id="#{idstr}" smilref="#{smilstr}">], @xindent))
      @xfile.puts(indent(%Q[<hd>#{phr.caption}</hd>], @xindent + 2)) unless phr.caption.nil?
      phr.phrase.each_line {|ph|
         ph.sub!(/\n/, "")
         @xfile.puts(indent(%Q[<p>#{ph}</p>], @xindent + 2))
      }
      @xfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
   end

   def compile_text(phr)
      phr.phrase.sub!(/^[\s　]+/, "") if @paragraph_print
      check_paragraph()
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent))
         @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</sent>], @xindent))
      else
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent))
      end
      @normal_print = true
   end

   def compile_quote(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      @xfile.puts(indent(%Q[<blockquote id="#{idstr}" smilref="#{smilstr}">], @xindent))
# Quote 変更
      phr.lines.each {|sent|
         sent.phrase.sub!(/^[\s　]+/, "")
         if /^<span class="(x?[1-9])">/ =~ sent.phrase
            num = $1
            str = sent.phrase.sub(/<span class=".+">/, "")
            str.sub!("</span>", "")
            @xfile.puts(indent(%Q[<p class="indent_#{num}">#{str}</p>], @xindent + 2))
         else
            @xfile.puts(indent(%Q[<p>#{sent.phrase}</p>], @xindent + 2))
         end
      }
#      phr.phrase.each_line {|p|
#         xmlfile.puts(indent(%Q[#{p}], @xindent + 2))
#      }
      @xfile.puts(indent(%Q[</blockquote>], @xindent))
   end

   def compile_pagenum(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      @xfile.puts(indent("<br />", @xindent)) unless @paragraph_print
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<pagenum id="#{idstr}" smilref="#{smilstr}" page="#{phr.namedowncase}">], @xindent))
         @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</pagenum>], @xindent))
      else
         @xfile.puts(indent(%Q[<pagenum id="#{idstr}" smilref="#{smilstr}" page="#{phr.namedowncase}">#{phr.phrase}</pagenum>], @xindent))
      end
      @xfile.puts(indent("<br />", @xindent)) unless @paragraph_print
   end

   def compile_table(phr)
      smilstr, idstr = compile_id(phr)
      tabref = compile_table_id(phr.args)
      num, row, column = phr.get_table
      if phr.phrase == "" and phr.caption != nil
         @xfile.puts(indent(%Q[<table border="1" smilref="#{tabref}">], @xindent))
         @xfile.puts(indent(%Q[<caption id="#{idstr}" smilref="#{smilstr}">#{phr.caption}</caption>], @xindent + 2))
      elsif 1 == num
#      num, row, column = phr.get_table
#      if 1 == num
#         tabref = compile_table_id(sectcount)
#         phr.uid = @table_id
#         tabref = compile_table_id(phr.args, sectcount)
         @xfile.puts(indent(%Q[<table border="1" smilref="#{tabref}">], @xindent)) if phr.caption.nil?
         @xfile.puts(indent("<tr>", @xindent + 2))
         @xfile.puts(indent(%Q[<#{phr.tag}>], @xindent + 4))
         if /\A</ =~ phr.phrase
            @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent + 6))
            @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 8))
            @xfile.puts(indent("</sent>", @xindent + 6))
         else
            @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 6))
         end
         @xfile.puts(indent(%Q[</#{phr.tag}>], @xindent + 4))
      elsif row * column == num
         table_sentence(phr, smilstr, idstr)
         @xfile.puts(indent("</tr>", @xindent + 2))
         @xfile.puts(indent("</table>", @xindent))
      elsif num % column == 0 && num < row * column
         table_sentence(phr, smilstr, idstr)
         @xfile.puts(indent("</tr>", @xindent + 2))
      elsif num % column == 1
         @xfile.puts(indent("<tr>", @xindent + 2))
         table_sentence(phr, smilstr, idstr)
      else
         table_sentence(phr, smilstr, idstr)
      end
   end

   def compile_image(phr)
      @img_list << phr.phrase
      @xfile.puts(indent(%Q[<img src="Images/#{phr.phrase}" id="#{phr.args}" alt="#{phr.caption}" width="#{phr.width}" height="#{phr.height}" />], @xindent))
   end

   def compile_caption(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      @xfile.puts(indent(%Q[<caption imgref="#{phr.ref}">], @xindent))
      @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 2))
      @xfile.puts(indent(%Q[</caption>], @xindent))
   end

   def compile_imagegroup(phr)
      if phr.start?
         @xfile.puts(indent(%Q[<imggroup id="#{phr.args}">], @xindent))
         @xindent = @xindent + 2
      else
         @xindent = @xindent - 2
         @xfile.puts(indent(%Q[</imggroup>], @xindent))
      end
   end

   def compile_list(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      if "begin" == phr.args
         if '*' == phr.enum
            @xfile.puts(indent(%Q[<list type="#{phr.type}">], @xindent))
         elsif ':' == phr.enum
            @xfile.puts(indent("<dl>", @xindent))
         else
            @xfile.puts(indent(%Q[<list type="#{phr.type}" enum="#{phr.enum}">], @xindent))
         end
      end
      if '' == phr.dl
         @xfile.puts(indent("<li>", @xindent + 2))
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 4))
         @xfile.puts(indent("</li>", @xindent + 2))
      elsif 'dt' == phr.dl
         if phr.args.nil? #phr.enum.nil?
            @xfile.puts(indent("</dd>", @xindent + 2))
         end
         @xfile.puts(indent("<dt>", @xindent + 2))
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 4))
      elsif 'dd0' == phr.dl
         @xfile.puts(indent("</dt>", @xindent + 2))
         @xfile.puts(indent("<dd>", @xindent + 2))
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 4))
      elsif /dd[1-9]+/ =~ phr.dl
         @xfile.puts(indent("<br />", @xindent + 2))
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent + 4))
      end
      if "end" == phr.args
         if 'dl' == phr.type
            @xfile.puts(indent("</dd>", @xindent + 2))
            @xfile.puts(indent("</dl>", @xindent))
         else
            @xfile.puts(indent("</list>", @xindent))
         end
      end

   end


   def smil_header
      @sfile.puts <<EOT
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

   def smil_footer
      @sfile.puts <<EOT
    </seq>
  </body>
</smil>
EOT
      @indent = 0
   end

   def compile_smil_headline(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @seq["seq"] += 1
      @sfile.puts <<EOT
    <seq id="seq#{@seq["seq"]}">
      <par id="phr#{phrnum}">
        <text src="#{xmlfilename}#t#{tnum}" />
      </par>
EOT
      @indent = 6
   end

   def compile_smil_customtest(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts <<EOT
      <par id="phr#{phrnum}" customTest="#{phr.namedowncase}">
        <text src="#{xmlfilename}#t#{tnum}" />
      </par>
EOT
   end

   def compile_smil_table(phr)
      now, row, column = phr.get_table
      seqid = phr.args
      tblend = phr.readid + (row * column - 1)
      tblendid = zerosuplement(tblend, 5)
      if phr.phrase == "" and phr.caption != nil
         @sfile.puts(indent(%Q[<seq id="tab#{seqid}" class="table" end="DTBuserEscape;phr#{tblendid.succ}.end">], @indent))
         table_par(phr)
      elsif 1 == now
         @sfile.puts(indent(%Q[<seq id="tab#{seqid}" class="table" end="DTBuserEscape;phr#{tblendid}.end">], @indent)) if phr.caption.nil?
         table_par(phr)
      elsif row * column == now
         table_par(phr)
         @sfile.puts(indent(%Q[</seq>], @indent))
      else
         table_par(phr)
      end
   end

   def compile_smil_text(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" />], @indent + 2))
      @sfile.puts(indent(%Q[</par>], @indent))
   end

   def compile_smil_image(phr)
   end


   def compile_prodnote_normal(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" id="#{idstr}" smilref="#{smilstr}">], @xindent))
         @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
      else
         @xfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</#{phr.namedowncase}>], @xindent))
      end
   end

   def compile_prodnote_group(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" imgref="#{phr.ref}" id="#{idstr}" smilref="#{smilstr}">], @xindent))
         @xfile.puts(indent(%Q[#{phr.phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</#{phr.namedowncase}>], @xindent))
      else
         @xfile.puts(indent(%Q[<#{phr.namedowncase} render="#{phr.render}" imgref="#{phr.ref}" id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</#{phr.namedowncase}>], @xindent))
      end
   end

   private

   def compile_id(phr)
      id = zerosuplement(phr.totalid, 7)
      smilnum = zerosuplement(@sectcount, 5)
      phrnum = zerosuplement(phr.readid, 5)
      idstr = "t#{id}"
      smilstr = "#{PTK}#{smilnum}.smil#phr#{phrnum}"
      return smilstr, idstr
   end

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
#         errmes = "ルビタグの漢字部分が違っているようです : #{rubytag}"
#         print_error(errmes)
         mes = "[注意] 漢字以外が含まれているようです : #{rubytag}"
         puts mes
      end
      unless @add_yomi
#         return tag = k if /#{KATA}+/ =~ r
         return tag = k if /\A[yY]/ =~ r
      end
      r = r.sub(/\A[yY]/, '')
      tag = %Q!<span class="ruby">#{k}<span class="rp">（</span><span class="rt">#{r}</span><span class="rp">）</span></span>!
   end

   def tag_vih(args)
      args
   end
   def tag_date(args)
      args
   end
   def tag_indent(args)
      if /^(x?[1-9]?|[1-9]),(.+)$/ =~ args
         num = $1
         sent = $2.sub(/^[\s　]+/, "")
         return %Q[<span class="#{num}">#{sent}</span>]
      end
      return "err"
   end
end