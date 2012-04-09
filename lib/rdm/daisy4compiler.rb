# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#

require 'rdm/compiler'

class TEXTDaisy4

   def cover_page(image)
      @xfile.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops"
      lang="#{@meta.language}" xml:lang="#{@meta.language}">
    <head>
      <title>#{@meta.title}</title>
      <link rel="alternate stylesheet" href="../Styles/#{@bookname}_horizontal.css" type="text/css" class="horizontal" title="horizontal layout"/>
      <link rel="stylesheet" href="../Styles/#{@bookname}_vertical.css" type="text/css" class="vertical" title="vertical layout"/>
    </head>
    <body class="cover" epub:type="cover">
       <div>
          <img src="../Images/#{image}" alt="画像：表紙" class="cover-image" id="coverimg"/>
       </div>
    </body>
</html>
EOT
#      <link href="../Styles/#{@bookname}.css" rel="stylesheet" type="text/css" />
   end

   def xml_header
      @table_id = 0
      @xfile.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops"
      xmlns:speak="http://www.w3.org/2001/10/synthesis"
      lang="#{@meta.language}" xml:lang="#{@meta.language}">
    <head>
      <title>#{@meta.title}</title>
      <link rel="alternate stylesheet" href="../Styles/#{@bookname}_horizontal.css" type="text/css" class="horizontal" title="horizontal layout"/>
      <link rel="stylesheet" href="../Styles/#{@bookname}_vertical.css" type="text/css" class="vertical" title="vertical layout"/>
    </head>
    <body>
EOT
#      <link href="../Styles/#{@bookname}.css" rel="stylesheet" type="text/css" />
=begin
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="#{@meta.language}" xml:lang="#{@meta.language}">
  <speak version="1.1"
         xmlns="http://www.w3.org/2001/10/synthesis"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.w3.org/2001/10/synthesis
                   http://www.w3.org/TR/speech-synthesis11/synthesis.xsd"
         xml:lang="#{@meta.language}">
    <head>
      <title>#{@meta.title}</title>
      <link href="../Styles/#{@bookname}.css" rel="stylesheet" type="text/css" />
    </head>
    <body>
=end
      @xindent = 4
   end

   def xml_footer
      if @normal_print
         @xindent = @xindent - 2
         @xfile.puts(indent("</p>", @xindent))
         @normal_print = false
      end
      @level.downto(1) {|num|
         @xindent -= 2
         @xfile.puts(indent("</section>", @xindent))
      }
      @xfile.puts <<EOT
   </body>
</html>
EOT
   end

   def print_phrase(phr, idstr)
      @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent))
      if /\A</ =~ phr.phrase
         @xfile.puts(indent("<span>", @xindent + 2))
         @xfile.puts(indent("#{phr.phrase}", @xindent + 4))
         @xfile.puts(indent("</span>", @xindent + 2))
      else
         @xfile.puts(indent("<span>#{phr.phrase}</span>", @xindent + 2))
      end
      @xfile.puts(indent("</span>", @xindent))
   end

   def compile_headline(phr)
      befour_level = @level
      @level = phr.args
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml#s#{idstr}"
      if @level == 1
         @xindent = @xindent + 2
      elsif befour_level >= @level
         befour_level.downto(@level) {|num|
            @xindent = @xindent - 2
            @xfile.puts(indent("</section>", @xindent))
         }
      end
      @xfile.puts(indent(%Q[<section id="s#{idstr}">], @xindent))
      @xfile.puts(indent("<h#{phr.args}>", @xindent + 2))
      @xindent = @xindent + 4
      print_phrase(phr, idstr)
      @xindent = @xindent - 2
      @xfile.puts(indent("</h#{phr.args}>", @xindent))
   end

   def compile_noteref(phr)
# <a rel="note" epub:type="#{phr.namedowncase}" id="#{idstr}" href="##{idstr.succ}">#{phr.phrase}</a>
      check_paragraph()
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<a rel="note" epub:type="#{phr.namedowncase}" id="#{idstr}" href="##{idstr.succ}">], @xindent))
      if /\A</ =~ phr.phrase
         @xfile.puts(indent("<span>", @xindent + 2))
         @xfile.puts(indent("#{phr.phrase}", @xindent + 4))
         @xfile.puts(indent("</span>", @xindent + 2))
      else
         @xfile.puts(indent("<span>#{phr.phrase}</span>", @xindent + 2))
      end
      @xfile.puts(indent("</a>", @xindent))
      @normal_print = true
   end

   def compile_note(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<aside id="fn#{idstr}">], @xindent))
      @xfile.puts(indent("<p>", @xindent + 2))
      if /\A</ =~ phr.phrase
         @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent + 4))
         @xfile.puts(indent("#{phr.phrase}", @xindent + 6))
         @xfile.puts(indent("</span>", @xindent + 4))
      else
         @xfile.puts(indent(%Q[<span id="#{idstr}">#{phr.phrase}</span>], @xindent + 4))
      end
      @xfile.puts(indent("</p>", @xindent + 2))
      @xfile.puts(indent("</aside>", @xindent))
   end

   def compile_prodnote(phr)
      if phr.group.nil?
         compile_prodnote_normal(phr)
      else
         compile_prodnote_group(phr)
      end
   end

   def compile_sidebar(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<aside id="si#{idstr}">], @xindent))
#      @xfile.puts(indent(%Q[<hd>#{phr.caption}</hd>], @xindent + 2)) unless phr.caption.nil?
      @xfile.puts(indent(%Q[<header>#{phr.caption}</header>], @xindent + 2)) unless phr.caption.nil?
      phr.phrase.each_line {|p|
         @xfile.puts(indent("<p>", @xindent + 2))
         @xfile.puts(indent(%Q[<span id="#{idstr}">#{p}</span>], @xindent + 4))
         @xfile.puts(indent("</p>", @xindent + 2))
      }
      @xfile.puts(indent("</aside>", @xindent))
   end

   def compile_text(phr)
      check_paragraph()
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      print_phrase(phr, idstr)
      @normal_print = true
   end

   def compile_quote(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<blockquote id="#{idstr}">], @xindent))
      phr.lines.each {|sent|
         @xfile.puts(indent("<p>", @xindent + 2))
         @xfile.puts(indent("<span>#{sent.phrase}</span>", @xindent + 4))
         @xfile.puts(indent("</p>", @xindent + 2))
      }
      @xfile.puts(indent("</blockquote>", @xindent))
   end

   def compile_pagenum(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      str = phr.cut_kana
#      @xfile.puts(indent(%Q[<span xmlns:epub="http://www.idpf.org/2007/ops" id="#{idstr}" epub:type="pagebreak" title="#{str}"></span>], @xindent))
      @xfile.puts(indent(%Q[<span id="#{idstr}" epub:type="pagebreak" title="#{str}"></span>], @xindent))
   end

   def compile_table(phr)
      chapnum, idstr = compile_id(phr)
#      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      tabref = compile_table_id(phr.args)
      num, row, column = phr.get_table
      if phr.phrase == "" and phr.caption != nil
         @xfile.puts(indent(%Q[<section id="">], @xindent))
         @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent + 2))
         @xfile.puts(indent(%Q[<span>#{phr.caption}</span>], @xindent + 4))
         @xfile.puts(indent("</span>", @xindent + 2))
      elsif 1 == num
         @xfile.puts(indent(%Q[<section id="">], @xindent)) if phr.caption.nil?
#         "<tr>", @xindent + 2
#         %Q[<#{phr.tag}>], @xindent + 4
         print_phrase(phr, idstr)
#         %Q[</#{phr.tag}>], @xindent + 4
      elsif row * column == num
         print_phrase(phr, idstr)
         @xfile.puts(indent("</section>", @xindent))
#         @xfile.puts(indent("</tr>", @xindent + 2))
#         @xfile.puts(indent("</table>", @xindent))
      elsif num % column == 0 && num < row * column
         print_phrase(phr, idstr)
#         @xfile.puts(indent("</tr>", @xindent + 2))
      elsif num % column == 1
#         @xfile.puts(indent("<tr>", @xindent + 2))
         print_phrase(phr, idstr)
      else
         print_phrase(phr, idstr)
      end
   end

   def compile_image(phr)
      @img_list << phr.phrase
      @xfile.puts(indent(%Q[<img src="../Images/#{phr.phrase}" id="#{phr.args}" alt="#{phr.caption}"/>], @xindent))
   end

   def compile_caption(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent("<figcaption>", @xindent))
      @xindent = @xindent + 2
      print_phrase(phr, idstr)
      @xindent = @xindent - 2
      @xfile.puts(indent("</figcaption>", @xindent))
   end

   def compile_imagegroup(phr)
      if phr.start?
         @xfile.puts(indent(%Q[<figure id="#{phr.args}">], @xindent))
         @xindent = @xindent + 2
      else
         @xindent = @xindent - 2
         @xfile.puts(indent(%Q[</figure>], @xindent))
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
#      @seq = Hash.new(0)
   end

   def smil_footer
      @sfile.puts <<EOT
  </body>
</smil>
EOT
=begin
    </seq>
  </body>
</smil>
=end
      @indent = 0
   end

   def compile_smil_headline(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
#      @seq["seq"] += 1
      @sfile.puts <<EOT
      <par id="phr#{phrnum}">
        <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
      </par>
EOT
=begin
    <seq id="seq#{@seq["seq"]}">
      <par id="phr#{phrnum}">
        <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
      </par>
=end
      @indent = 6
   end

   def compile_smil_customtest(phr)
      if phr.kind_of?(Page)
         compile_smil_pagenum(phr)
      elsif phr.kind_of?(NoteGroup)
         compile_smil_notegroup(phr)
      end
   end

   def compile_smil_pagenum(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      @sfile.puts <<EOT
      <par id="phr#{phrnum}" epub:type="pagebreak">
         <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
      </par>
EOT
#      <par id="phr#{phrnum}" xmlns:epub="http://www.idpf.org/2007/ops" epub:type="pagebreak">
   end

   def compile_smil_notegroup(phr)
      xmlfilename, phrnum, tnum = set_smil_num(phr)
      if phr.instance_of?(Prodnote)
         phrType = "annotation"
      else
         phrType = phr.namedowncase
      end
      @sfile.puts <<EOT
      <par id="phr#{phrnum}" epub:type="#{phrType}">
         <text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>
      </par>
EOT
#      <par id="phr#{phrnum}" xmlns:epub="http://www.idpf.org/2007/ops" epub:type="#{phrType}">
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
      @sfile.puts(indent(%Q[<text src="#{xmlfilename}#t#{tnum}" id="phr#{phrnum}_text"/>], @indent + 2))
      @sfile.puts(indent(%Q[</par>], @indent))
   end

   def compile_smil_image(phr)
   end

   private

   def compile_id(phr)
      id = zerosuplement(phr.totalid, 7)
      idstr = "t#{id}"
      chapnum = zerosuplement(@chapcount, 5)
      return chapnum, idstr
   end

   def compile_prodnote_normal(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<aside id="an#{idstr}">], @xindent))
      prodnote_print(phr, idstr)
   end

   def compile_prodnote_group(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<aside id="an#{idstr}">], @xindent))
      prodnote_print(phr, idstr)
   end

   def prodnote_print(phr, idstr)
      @xfile.puts(indent("<p>", @xindent + 2))
      @xfile.puts(indent(%Q[<span id="#{idstr}">#{phr.phrase}</span>], @xindent + 4))
      @xfile.puts(indent("</p>", @xindent + 2))
      @xfile.puts(indent(%Q[</aside>], @xindent))
   end

end
