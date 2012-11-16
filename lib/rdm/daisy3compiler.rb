# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#

require 'rdm/compiler'

class Daisy3

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
      @xindent = 6
   end

   def xml_footer
      if @ptag
         @xindent = @xindent - 2
         @xfile.puts(indent("</p>", @xindent))
         @ptag = false
      end
      @@level.downto(1) {|num|
         @xindent = @xindent - 2
         @xfile.puts(indent(%Q[</level#{num}>], @xindent))
      }
      @xfile.puts <<EOT
    </bodymatter>
  </book>
</dtbook>
EOT
   end

   def print_level
      if @@befour_level
         if @@befour_level < @@level
            (@@level - @@befour_level).times {|l|
               @xfile.puts(indent("<level#{@@befour_level + l + 1}>", @xindent))
               @xindent += 2
            }
         elsif @@befour_level > @@level
            @@befour_level.downto(@@level) {|l|
               @xindent -= 2
               @xfile.puts(indent("</level#{l}>", @xindent))
            }
            @xfile.puts(indent("<level#{@@level}>", @xindent))
            @xindent += 2
         else
            @xindent -= 2
            @xfile.puts(indent("</level#{@@befour_level}>", @xindent))
            @xfile.puts(indent("<level#{@@level}>", @xindent))
            @xindent += 2
         end
      else
         unless @@start_level == 1
            (@@start_level - 1).times {|l|
               @xfile.puts(indent("<level#{l + 1}>", @xindent))
               @xindent += 2
            }
         end
         @xfile.puts(indent("<level#{@@level}>", @xindent))
         @xindent += 2
      end
   end

   def compile_doctitle_tag(phr)
      if %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("</doctitle>", @xindent))
         @ptag = false
      else
         @@befour_level = @@level unless @@level.nil?
         @@level = phr.arg
         @@start_level = @@level if @@start_level.nil?
         print_level()
         @xfile.puts(indent("<doctitle>", @xindent))
         @xindent += 2
      end
      @header = true
   end

   def compile_headline_tag(phr)
      if %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
         @ptag = false
      else
         @@befour_level = @@level unless @@level.nil?
         @@level = phr.arg
         @@start_level = @@level if @@start_level.nil?
         print_level()
         if phr.indent
            @xfile.puts(indent(%Q[<#{phr.tag} class="indent_#{phr.indent}">], @xindent))
         else
            @xfile.puts(indent("<#{phr.tag}>", @xindent))
         end
         @xindent += 2
      end
      @header = true
   end

   def print_sentence(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      phrase = Phrase::cut_front_space(phr.phrase)
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">], @xindent))
         @xfile.puts(indent(%Q[#{phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</sent>], @xindent))
      else
         @xfile.puts(indent(%Q[<sent id="#{idstr}" smilref="#{smilstr}">#{phr.phrase}</sent>], @xindent))
      end
   end

   def compile_text(phr)
      check_paragraph()
      print_sentence(phr)
   end

   def compile_noteref_sentence(phr)
      check_paragraph()
      phr.phrase.each_with_index {|s, i|
         if s.instance_of?(Noteref) #or s.instance_of?(Annoref)
            s.str = Phrase::exchange_entity(s.str)
            tag = phr.namedowncase.sub(/::sentence/, "")
            refstr = %Q[<#{tag} id="#{s.arg}-ref" idref="##{s.noteArg}">#{s.str}</#{tag}>]
            @xfile.puts(indent(refstr, @xindent))
         elsif 0 == i
            s = Phrase::exchange_entity(s)
            smilstr, idstr = compile_id(phr)
            sent = %Q[<sent id="#{idstr}" smilref="#{smilstr}">#{s}]
            @xfile.puts(indent(sent, @xindent))
         elsif phr.phrase.size == i + 1
            s = Phrase::exchange_entity(s)
            @xfile.puts(indent(%Q[#{s}</sent>], @xindent))
         else
            s = Phrase::exchange_entity(s)
            @xfile.puts(indent("#{s}", @xindent))
         end
      }
   end

   def paragraph_post?
      if @ptag
         @xindent -= 2
         @xfile.puts(indent("</p>", @xindent))
         @ptag = false
      end
   end

   def notegroup_end_tag(phr)
      paragraph_post?()
      @xindent -= 2
      @xfile.puts(indent("<#{phr.tag}>", @xindent))
   end

   def compile_note_tag(phr)
      paragraph_post?()
      if %r!\A/! =~ phr.tag
         notegroup_end_tag(phr)
      else
         smilstr = compile_smilstr_escapeble(phr)
         @xfile.puts(indent(%Q[<#{phr.tag} id="#{phr.arg}" smilref="#{smilstr}">], @xindent))
         @xindent += 2
      end
   end

   def check_refstr(phr)
      unless phr.noteref.nil?
         if /-E\z/ =~ phr.arg
            return "#{phr.phrase} 注、終わり。"
         elsif /-0\z/ =~ phr.arg
            phr.cut_brace
            return "#{phr.noteref}:#{phr.phrase}"
         else
            return phr.phrase
         end
      end
      return phr.phrase
   end

   def compile_note_render_tag(phr)
      if %r!\A/! =~ phr.tag
         notegroup_end_tag(phr)
      elsif phr.instance_of?(Prodnote) and phr.group
         smilstr = compile_smilstr_escapeble(phr)
         @xfile.puts(indent(%Q[<#{phr.tag} render="#{phr.render}" imgref="#{phr.ref}" smilref="#{smilstr}">], @xindent))
         @xindent += 2
      else
         smilstr = compile_smilstr_escapeble(phr)
         @xfile.puts(indent(%Q[<#{phr.tag} render="#{phr.render}" smilref="#{smilstr}">], @xindent))
         @xindent += 2
      end
   end

   def compile_sidebar_caption(phr)
      @xfile.puts(indent("<hd>", @xindent))
      print_caption(phr)
      @xfile.puts(indent("</hd>", @xindent))
   end

   def compile_quote_tag(phr)
      if %r!\A/! =~ phr.tag
         notegroup_end_tag(phr)
      elsif phr.border
         @xfile.puts(indent(%Q[<#{phr.tag} class="border">], @xindent))
         @xindent += 2
      else
         @xfile.puts(indent(%Q[<#{phr.tag}>], @xindent))
         @xindent += 2
      end
   end

   def compile_quote_indent(phr)
      if phr.terminal
         @xindent -= 2
         @xfile.puts(indent("</p>", @xindent))
         @ptag = false
      else
         if @m_indent
            @m_indent = false
         elsif @ptag
            @xindent -= 2
            @xfile.puts(indent("</p>", @xindent))
         end
         @xfile.puts(indent(%Q[<p class="indent_#{phr.indent}">], @xindent))
         @xindent += 2
         @ptag = true
      end
   end

   def add_pagestr?(phr)
      if @daisy2 and 'textNCX' == @xmeta.multimediaType
         return "#{phr.phrase}ページ"
      else
         return phr.phrase
      end
   end

   def compile_pagenum(phr)
      smilstr, idstr = compile_id(phr)
      phr.ncxsrc = smilstr
      phrase = add_pagestr?(phr)
      @xfile.puts(indent("<br />", @xindent)) if @ptag
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<pagenum id="#{idstr}" smilref="#{smilstr}" page="#{phr.namedowncase}">], @xindent))
         @xfile.puts(indent(%Q[#{phrase}], @xindent + 2))
         @xfile.puts(indent(%Q[</pagenum>], @xindent))
      else
         @xfile.puts(indent(%Q[<pagenum id="#{idstr}" smilref="#{smilstr}" page="#{phr.namedowncase}">#{phrase}</pagenum>], @xindent))
      end
      @xfile.puts(indent("<br />", @xindent)) if @ptag
   end

   def compile_table_tag(phr)
      tabref = compile_table_id(phr.arg)
      if phr.border
         @xfile.puts(indent(%Q[<table border="1" id="#{phr.arg}" smilref="#{tabref}">], @xindent))
         @xindent += 2
      elsif %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
      elsif %r!\s/! =~ phr.tag
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
      elsif 'table' == phr.tag
         @xfile.puts(indent(%Q[<table id="#{phr.arg}" smilref="#{tabref}">], @xindent))
         @xindent += 2
      elsif 'nowrap' == phr.style
         @xfile.puts(indent(%Q[<#{phr.tag} class="nowrap">], @xindent))
         @xindent += 2
      else
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
         @xindent += 2
      end
      @header = true
   end

   def compile_table_caption(phr)
      compile_caption(phr)
   end

   def compile_image_caption(phr)
      @xfile.puts(indent(%Q[<caption imgref="#{phr.ref}">], @xindent))
      print_caption(phr)
      @xfile.puts(indent("</caption>", @xindent))
   end

   def compile_caption(phr)
      @xfile.puts(indent("<caption>", @xindent))
      print_caption(phr)
      @xfile.puts(indent("</caption>", @xindent))
   end

   def print_caption(phr)
      @xindent += 2
      print_sentence(phr)
      @xindent -= 2
   end

   def compile_image(phr)
      @img_list << "Images/#{phr.file}"
      @xfile.puts(indent(%Q[<img src="Images/#{phr.file}" id="#{phr.arg}" alt="#{phr.alt}" width="#{phr.width}" height="#{phr.height}" />], @xindent))
   end

   def compile_imagegroup(phr)
      if phr.start?
         @xfile.puts(indent(%Q[<imggroup id="#{phr.arg}">], @xindent))
         @xindent += 2
      else
         @xindent -= 2
         @xfile.puts(indent(%Q[</imggroup>], @xindent))
      end
   end

   def compile_list_tag_ulol(phr)
      if %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("</list>", @xindent))
      elsif phr.instance_of?(Ul)
         smilstr = compile_smilstr_escapeble(phr)
         @xfile.puts(indent(%Q[<list type="#{phr.type}" id="#{phr.arg}" smilref="#{smilstr}">], @xindent))
         @xindent += 2
         @header = true
      elsif phr.instance_of?(Ol)
         smilstr = compile_smilstr_escapeble(phr)
         @xfile.puts(indent(%Q[<list type="#{phr.type}" enum="#{phr.enum}" id="#{phr.arg}" smilref="#{smilstr}">], @xindent))
         @xindent += 2
         @header = true
      end
   end

   def compile_list_tag_dl(phr)
      if %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
      else
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
         @xindent += 2
         @header = true
      end
   end


   def smil_header
      if @daisy2 and 'audioFullText' == @xmeta.multimediaType
         if 0 > @sectcount - 2
            totalElapsedTime = "0:00:00.000"
         else
            times = []
            (0..@sectcount - 2).each {|c|
               times << read_time_in_this_smil(@seqs[c].dur)
            }
            totalElapsedTime = time_add_time(times)
            if totalElapsedTime.kind_of?(Array)
               raise "#{@sectcount - 1}番目のsmilファイルで#{totalElapsedTime[1]}"
            end
         end
      else
         totalElapsedTime = @xmeta.totalElapsedTime
      end
      @sfile.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE smil PUBLIC "-//NISO//DTD dtbsmil 2005-1//EN" "dtbsmil-2005-2.dtd">
<smil xmlns="http://www.w3.org/2001/SMIL20/">
  <head>
    <meta name="dtb:uid" content="#{@meta.iUid}" />
    <meta name="dtb:generator" content="#{GENERATOR}" />
    <meta name="dtb:totalElapsedTime" content="#{totalElapsedTime}" />
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

   def set_tableEnd_id(phr)
      if @daisy2
         return phr.endcell.readid unless phr.endcell.nil?
      else
         return zerosuplement(phr.endcell.readid, 5)
      end
   end

   def print_table_seq(phr)
      tblendid = set_tableEnd_id(phr)
      @sfile.puts(indent(%Q[<seq id="es#{phr.arg}" class="table" end="DTBuserEscape;phr#{tblendid}.end">], @indent))
      @indent += 2
   end

   def compile_smil_table(phr)
      unless phr.endcell.nil?
         print_table_seq(phr)
         @endcell = phr.endcell.readid
      end
      compile_smil_text(phr)
      if @endcell == phr.readid
         @indent -= 2
         @sfile.puts(indent("</seq>", @indent))
      end
   end

   def compile_smil_list(phr)
      print_seq_pre(phr) unless @customTest
      compile_smil_text(phr)
      print_seq_post(phr) if /-E/ =~ phr.arg
   end

   private

   def compile_id(phr)
      if @daisy2
         id = phr.totalid
         phrnum = phr.readid
      else
         id = zerosuplement(phr.totalid, 7)
         phrnum = zerosuplement(phr.readid, 5)
      end
      smilnum = zerosuplement(@sectcount, 5)
      idstr = "t#{id}"
      smilstr = "#{PTK}#{smilnum}.smil#phr#{phrnum}"
      return smilstr, idstr
   end

   def compile_smilstr_escapeble(phr)
      id, name = get_custom_name(phr.ncxsrc)
      "#{PTK}#{zerosuplement(@sectcount, 5)}.smil#es#{id}"
   end

   def get_custom_name(phr)
      name = phr.namedowncase.sub(/::(?:sentence|caption)/, "")
      id = phr.arg.sub(/-.+/, "")
      return id, name
   end

   def print_seq_pre(phr)
      print_note_seq_pre(phr) if footnote_sentence?(phr)
      print_list_seq_pre(phr) if list_sentence?(phr)
      @indent += 2
      @customTest = true
   end

   def print_note_seq_pre(phr)
      seqid, customName = get_custom_name(phr)
      @sfile.puts(indent(%Q[<seq id="es#{seqid}" customTest="#{customName}">], @indent))
   end

   def print_list_seq_pre(phr)
      @sfile.puts(indent(%Q[<seq id="es#{phr.arg}" class="list">], @indent))
   end

   def print_seq_post(phr)
      @indent -= 2
      @sfile.puts(indent("</seq>", @indent))
      @customTest = false
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
         mes = "[注意] 漢字以外が含まれているようです : #{rubytag}"
         puts mes
      end
      unless @yomi
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
end

class TEXTDaisy
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

   def compile_smil_page(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}" customTest="#{phr.namedowncase}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" />], @indent + 2))
      @sfile.puts(indent("</par>", @indent))
   end

   def compile_smil_customtest(phr)
      print_seq_pre(phr) unless @customTest
      compile_smil_text(phr)
      print_seq_post(phr) if /-E/ =~ phr.arg
   end

   def compile_smil_text(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" />], @indent + 2))
      @sfile.puts(indent(%Q[</par>], @indent))
   end
end

class AudioFullTextDaisy3
   def compile_smil_headline(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @seq["seq"] += 1
      src, cBegin, cEnd = set_par_audio(phr) if @daisy2
      @sfile.puts <<EOT
    <seq id="seq#{@seq["seq"]}">
      <par id="phr#{phrnum}">
        <text src="#{xmlfilename}#t#{tnum}" />
EOT
      if src
         @sfile.puts <<EOT
        <audio src="Audios/#{src}" clipBegin="#{cBegin}" clipEnd="#{cEnd}" />
EOT
      end
      @sfile.puts <<EOT
      </par>
EOT
      @indent = 6
   end

   def compile_smil_page(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      src, cBegin, cEnd = set_par_audio(phr) if @daisy2
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}" customTest="#{phr.namedowncase}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" />], @indent + 2))
      if src
         @sfile.puts(indent(%Q[<audio src="Audios/#{src}" clipBegin="#{cBegin}" clipEnd="#{cEnd}" />], @indent + 2))
      end
      @sfile.puts(indent("</par>", @indent))
   end

   def compile_smil_customtest(phr)
      print_seq_pre(phr) unless @customTest
      compile_smil_text(phr)
      print_seq_post(phr) if /-E/ =~ phr.arg
   end

   def compile_smil_text(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      src, cBegin, cEnd = set_par_audio(phr) if @daisy2
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" />], @indent + 2))
      if src
         @sfile.puts(indent(%Q[<audio src="Audios/#{src}" clipBegin="#{cBegin}" clipEnd="#{cEnd}" />], @indent + 2))
      end
      @sfile.puts(indent(%Q[</par>], @indent))
   end
end
