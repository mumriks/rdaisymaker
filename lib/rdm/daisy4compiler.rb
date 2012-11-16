# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#

require 'rdm/compiler'

class Daisy4

   def alternate_stylesheet(name = nil)
      refstr = "Styles/" if "nav" == name
      refstr = "../Styles/cover_" if "cover" == name
      refstr = "../Styles/" if name.nil?
      if "rtl" == @meta.pageDirection
         str = %Q[      <link rel="alternate stylesheet" href="#{refstr}horizontal.css"
            type="text/css" class="horizontal" title="horizontal layout"/>
      <link rel="stylesheet" href="#{refstr}vertical.css"
            type="text/css" class="vertical" title="vertical layout"/>]
      elsif "ltr" == @meta.pageDirection
         str = %Q[      <link rel="stylesheet" href="#{refstr}horizontal.css"
            type="text/css" class="horizontal" title="horizontal layout"/>
      <link rel="alternate stylesheet" href="#{refstr}vertical.css"
            type="text/css" class="vertical" title="vertical layout"/>]
      end
      return str
   end

   def cover_page(image)
      stylesheetStr = alternate_stylesheet("cover")
      @xfile.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops"
      lang="#{@meta.language}" xml:lang="#{@meta.language}">
    <head>
      <title>#{@meta.title}</title>
#{stylesheetStr}
    </head>
    <body class="cover" epub:type="cover">
       <div>
          <img src="../Images/#{image}" alt="画像：表紙" class="cover-image" id="coverimg"/>
       </div>
    </body>
</html>
EOT
   end

   def xml_header
      @table_id = 0
      stylesheetStr = alternate_stylesheet()
      @xfile.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops"
      xmlns:speak="http://www.w3.org/2001/10/synthesis"
      lang="#{@meta.language}" xml:lang="#{@meta.language}">
    <head>
      <title>#{@meta.title}</title>
#{stylesheetStr}
    </head>
    <body>
EOT
      @xindent = 6
   end

   def xml_footer
      if @ptag
         @xindent = @xindent - 2
         @xfile.puts(indent("</p>", @xindent))
         @ptag = false
      end
      if @daisy2
         @@level.downto(@@start_level) {|num|
            @xindent -= 2
            @xfile.puts(indent("</section>", @xindent))
         }
      else
         @@level.downto(1) {|num|
            @xindent -= 2
            @xfile.puts(indent("</section>", @xindent))
         }
      end
      @xfile.puts <<EOT
   </body>
</html>
EOT
   end

   def print_sentence(phr)
      idstr = compile_id(phr)
      phrase = Phrase::cut_front_space(phr.phrase)
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent))
         @xfile.puts(indent("#{phrase}", @xindent + 2))
         @xfile.puts(indent("</span>", @xindent))
      else
         @xfile.puts(indent(%Q[<span id="#{idstr}">#{phr.phrase}</span>], @xindent))
      end
   end

   def print_level(phr)
      if @@befour_level
         if @@befour_level < @@level
            (@@level - @@befour_level).times {|l|
               @xfile.puts(indent(%Q[<section id="s#{phr.object_id}">], @xindent))
               @xindent += 2
            }
         elsif @@befour_level > @@level
            @@befour_level.downto(@@level) {|l|
               @xindent -= 2
               @xfile.puts(indent("</section>", @xindent))
            }
            @xfile.puts(indent(%Q[<section id="s#{phr.object_id}">], @xindent))
            @xindent += 2
         else
            @xindent -= 2
            @xfile.puts(indent("</section>", @xindent))
            @xfile.puts(indent(%Q[<section id="s#{phr.object_id}">], @xindent))
            @xindent += 2
         end
      else
         @xfile.puts(indent(%Q[<section id="s#{phr.object_id}">], @xindent))
         @xindent += 2
      end
   end

   def compile_doctitle_tag(phr)
      phr.tag = "h1" if "doctitle" == phr.tag
      phr.tag = "/h1" if "/doctitle" == phr.tag
      compile_headline_tag(phr)
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
         print_level(phr)
         if phr.indent
            @xfile.puts(indent(%Q[<h#{phr.arg} class="indent_#{phr.indent}">], @xindent))
         else
            @xfile.puts(indent("<#{phr.tag}>", @xindent))
         end
         @xindent += 2
      end
      @header = true
   end

   def compile_noteref_sentence(phr)
      check_paragraph()
      idstr = compile_id(phr)
      phr.phrase.each_with_index {|s, i|
         if s.instance_of?(Noteref) #or s.instance_of?(Annoref)
            s.str = Phrase::exchange_entity(s.str)
            name = phr.namedowncase.sub(/::sentence/, "")
            ref = compile_id(phr.child)
            refstr = %Q[<a rel="note" epub:type="#{name}" id="#{s.arg}ref" href="##{ref}">#{s.str}</a>]
            @xfile.puts(indent(refstr, @xindent))
         elsif 0 == i
            s = Phrase::exchange_entity(s)
            sent = %Q[<span id="#{idstr}">#{s}]
            @xfile.puts(indent(sent, @xindent))
         elsif phr.phrase.size == i + 1
            s = Phrase::exchange_entity(s)
            @xfile.puts(indent("#{s}</span>", @xindent))
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
      @xfile.puts(indent("</aside>", @xindent))
   end

   def compile_note_tag(phr)
      paragraph_post?()
      if %r!\A/! =~ phr.tag
         notegroup_end_tag(phr)
      else
         idstr = compile_id(phr.ncxsrc)
         @xfile.puts(indent(%Q[<aside id="#{phr.arg}" epub:type="#{phr.namedowncase}">], @xindent))
         @xindent += 2
      end
   end

   def check_refstr(phr)
      phrase = phr.phrase.sub(/^[\s　]+/, "")
      unless phr.noteref.nil?
         phr.cut_brace
         phrase = "#{phr.noteref}:#{phrase} 注、終わり。"
      end
      return phrase
   end

   def compile_note_render_tag(phr)
      if %r!\A/! =~ phr.tag
         notegroup_end_tag(phr)
      else
         @xfile.puts(indent(%Q[<aside id="#{phr.arg}">], @xindent))
         @xindent += 2
      end
   end
   def compile_sidebar_caption(phr)
      @xfile.puts(indent("<header>", @xindent))
      print_caption(phr)
      @xfile.puts(indent("</header>", @xindent))
   end

   def compile_text(phr)
      check_paragraph()
      print_sentence(phr)
   end

   def compile_quote_tag(phr)
      if %r!\A/! =~ phr.tag
         paragraph_post?()
         @xindent -= 2
         @xfile.puts(indent("</blockquote>", @xindent))
      elsif phr.border
         @xfile.puts(indent(%Q[<blockquote id="#{phr.arg}" class="border">], @xindent))
         @xindent += 2
      else
         @xfile.puts(indent(%Q[<blockquote id="#{phr.arg}">], @xindent))
         @xindent += 2
      end
   end

   def compile_pagenum(phr)
      idstr = compile_id(phr)
      @xfile.puts(indent(%Q[<span id="#{idstr}" epub:type="pagebreak" title="#{phr.cut_kana}"></span>], @xindent))
   end

   def compile_table_caption(phr)
      @xfile.puts(indent("<caption>", @xindent))
      print_caption(phr)
      @xfile.puts(indent("</caption>", @xindent))
   end

   def compile_table_tag(phr)
      if phr.border
         @xfile.puts(indent(%Q[<table border="1" id="#{phr.arg}">], @xindent))
         @xindent += 2
      elsif %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
      elsif %r!\s/! =~ phr.tag
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
      elsif 'table' == phr.tag
         @xfile.puts(indent(%Q[<table id="#{phr.arg}">], @xindent))
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

   def compile_image(phr)
      @img_list << "Images/#{phr.file}"
      @xfile.puts(indent(%Q[<img src="../Images/#{phr.file}" id="#{phr.arg}" alt="#{phr.alt}" />], @xindent))
   end

   def compile_image_caption(phr)
      @xfile.puts(indent("<figcaption>", @xindent))
      print_caption(phr)
      @xfile.puts(indent("</figcaption>", @xindent))
   end
   def print_caption(phr)
      @xindent = @xindent + 2
      print_sentence(phr)
      @xindent = @xindent - 2
   end

   def compile_imagegroup(phr)
      if phr.start?
         @xfile.puts(indent(%Q[<figure id="#{phr.arg}">], @xindent))
         @xindent = @xindent + 2
      else
         @xindent = @xindent - 2
         @xfile.puts(indent(%Q[</figure>], @xindent))
      end
   end

   def compile_list_tag_ulol(phr)
      if %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
         unless @ptag
            @xfile.puts(indent("<p>", @xindent - 2))
            @ptag = true
         end
      else
         if @ptag
            @xfile.puts(indent("</p>", @xindent - 2))
            @ptag = false
         end
         @xfile.puts(indent(%Q[<#{phr.tag} id="#{phr.arg}">], @xindent))
         @xindent += 2
         @header = true
      end
   end

   def compile_list_tag_dl(phr)
      if %r!\A/! =~ phr.tag
         @xindent -= 2
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
      elsif 'dl' == phr.tag
         @xfile.puts(indent(%Q[<#{phr.tag} id="#{phr.arg}">], @xindent))
         @xindent += 2
         @header = true
      else
         @xfile.puts(indent("<#{phr.tag}>", @xindent))
         @xindent += 2
         @header = true
      end
   end

   def smil_header
#      @sfile.puts <<EOT
#<?xml version="1.0" encoding="utf-8"?>
#<!DOCTYPE smil PUBLIC "-//W3C//DTD SMIL 3.0 Daisy//EN" "http://www.w3.org/2008/SMIL30/SMIL30Daisy.dtd">
#<smil xmlns="http://www.w3.org/ns/SMIL" version="3.0" baseProfile="Daisy" xmlns:xhtml="http://www.w3.org/1999/xhtml">
#  <head>
#  </head>
#  <body id="">
      @sfile.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<smil xmlns="http://www.w3.org/ns/SMIL" version="3.0"
      xmlns:epub="http://www.idpf.org/2007/ops">
  <body id="sm1">
EOT
      @indent = 2
   end

   def smil_footer
      @sfile.puts <<EOT
  </body>
</smil>
EOT
      @indent = 0
   end

   def compile_smil_customtest(phr)
      print_seq_pre(phr) unless @customTest
      compile_smil_text(phr)
      print_seq_post(phr) if  /-E/ =~ phr.arg
   end

   def compile_smil_list(phr)
      print_seq_pre(phr) unless @customTest
      compile_smil_text(phr)
      print_seq_post(phr) if /-E/ =~ phr.arg
   end

   def compile_smil_table(phr)
      compile_smil_text(phr)
   end

   def print_seq_pre(phr)
      id, type = get_custom_name(phr)
      ref = phr.ncxsrc.sub(/#.+$/, "") + "##{id}"
      @sfile.puts(indent(%Q[<seq id="sq#{id}" epub:textref="#{ref}" epub:type="#{type}">], @indent))
      @indent += 2
      @customTest = true
   end

   def get_custom_name(phr)
      if phr.instance_of?(Prodnote::Sentence)
         type = "annotation"
      elsif list_sentence?(phr)
         type = "list"
      else
         type = phr.namedowncase.sub(/::sentence/, "")
      end
      id = phr.arg.sub(/-.+/, "")
      return id, type
   end

   def print_seq_post(phr)
      @indent -= 2
      @sfile.puts(indent("</seq>", @indent))
      @customTest = false
   end

   def compile_smil_image(phr)
   end

   def tag_vih(args)
      if "rtl" == @meta.pageDirection
         return %Q[<span class="vih">#{args}</span>]
      elsif "ltr" == @meta.pageDirection
         return args
      end
   end

   private

   def compile_id(phr)
      if @daisy2
         idstr = "t#{phr.totalid}"
      else
         idstr = "t#{zerosuplement(phr.totalid, 7)}"
      end
      phr.ncxsrc = "#{PTK}#{zerosuplement(@chapcount, 5)}.xhtml##{idstr}"
      return idstr
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
      if /\A[yY]/ =~ r
         r.sub!(/\A[yY]/, "")
         tag = %Q[<span speak:ph="#{r}">#{k}</span>]
#        tag = %Q[<s ssml:ph="#{r}">#{k}</s>] #? <span ssml:ph> is not bound
      else
         tag = %Q!<ruby>#{k}<rp>（</rp><rt>#{r}</rt><rp>）</rp></ruby>!
      end
   end

   def tag_date(args)
      if "rtl" == @meta.pageDirection
         if @datevih
            return %Q[<span class="date">#{args}</span>]
         else
            return make_date_tag(args)
         end
      elsif "ltr" == @meta.pageDirection
         return args
      end
   end
   def make_date_tag(args)
      strs = args.split(/(\d+)/)
      tag = ""
      strs.each {|str|
         if /\d+/ =~ str
            if 2 < str.size
               ds = str.scan(/./)
               ds.each {|d|
                  tag += %Q[<span class="vih">#{d}</span>]
               }
            else
               tag += %Q[<span class="vih">#{str}</span>]
            end
         else
            tag += str
         end
      }
      tag
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

class TEXTDaisy4
   def compile_smil_headline(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts <<EOT
    <par id="phr#{phrnum}">
      <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
    </par>
EOT
      @indent = 4
   end

   def compile_smil_page(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts <<EOT
    <par id="phr#{phrnum}" epub:type="pagebreak">
      <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
    </par>
EOT
   end

   def compile_smil_text(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>], @indent + 2))
      @sfile.puts(indent(%Q[</par>], @indent))
   end
end

class AudioFullTextDaisy4
   def compile_smil_headline(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      src, cBegin, cEnd = set_par_audio(phr) if @daisy2
      @sfile.puts <<EOT
      <par id="phr#{phrnum}">
        <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
EOT
      if src
         @sfile.puts <<EOT
        <audio src="../Audios/#{src}" clipBegin="#{cBegin}" clipEnd="#{cEnd}" />
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
      @sfile.puts <<EOT
      <par id="phr#{phrnum}" epub:type="pagebreak">
        <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
EOT
      if src
         @sfile.puts <<EOT
        <audio src="../Audios/#{src}" clipBegin="#{cBegin}" clipEnd="#{cEnd}" />
EOT
      end
      @sfile.puts <<EOT
      </par>
EOT
   end

   def compile_smil_text(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      src, cBegin, cEnd = set_par_audio(phr) if @daisy2
      @sfile.puts(indent(%Q[<par id="phr#{phrnum}">], @indent))
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>], @indent + 2))
      if src
         @sfile.puts(indent(%Q[<audio src="../Audios/#{src}" clipBegin="#{cBegin}" clipEnd="#{cEnd}" />], @indent + 2))
      end
      @sfile.puts(indent(%Q[</par>], @indent))
   end
end
