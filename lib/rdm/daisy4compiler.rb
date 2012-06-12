# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#

require 'rdm/compiler'

class TEXTDaisy4

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

=begin
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
=end

   def print_phrase(phr, idstr)
      @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent))
      if /\A</ =~ phr.phrase
         @xfile.puts(indent("<span>", @xindent + 2))
         @xfile.puts(indent("#{phr.phrase}", @xindent + 4))
         @xfile.puts(indent("</span>", @xindent + 2))
      else
         @xfile.puts(indent(%Q[<span>#{phr.phrase}</span>], @xindent + 2))
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
      phr.phrase.sub!(/^[\s　]+/, "")
      @xfile.puts(indent(%Q[<section id="s#{idstr}">], @xindent))
      if phr.indent
         @xfile.puts(indent(%Q[<h#{phr.args} class="indent_#{phr.indent}">], @xindent + 2))
      else
         @xfile.puts(indent("<h#{phr.args}>", @xindent + 4))
      end
      @xindent = @xindent + 6
      print_phrase(phr, idstr)
      @xindent = @xindent - 4
      @xfile.puts(indent("</h#{phr.args}>", @xindent + 2))
   end

   def compile_noteref(phr)
      check_paragraph()
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
=begin
      @xfile.puts(indent(%Q[<a rel="note" epub:type="#{phr.namedowncase}" id="#{idstr}" href="##{idstr.succ}">], @xindent))
      if /\A</ =~ phr.phrase
         @xfile.puts(indent("<span>", @xindent + 2))
         phrase = phr.phrase.sub(/^[\s　]+/, "")
         @xfile.puts(indent("#{phrase}", @xindent + 4))
         @xfile.puts(indent("</span>", @xindent + 2))
      else
         @xfile.puts(indent("<span>#{phr.phrase}</span>", @xindent + 2))
      end
      @xfile.puts(indent("</a>", @xindent))
=end
      phr.phrase.gsub!(/epub:type=""/, %Q[epub:type="#{phr.namedowncase}"])
      phr.phrase.sub!(/id=""/, %Q[id="#{idstr}-ref"])
      phr.phrase.sub!(/href="#"/, %Q[href="##{idstr.succ}"])
      phrase = phr.phrase.sub(/^[\s　]+/, "")
      if /\A</ =~ phrase
         @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent))
         @xfile.puts(indent(phrase, @xindent + 2))
         @xfile.puts(indent("</span>", @xindent))
      else
         @xfile.puts(indent(%Q[<span id="#{idstr}">#{phrase}</span>], @xindent))      end

      @normal_print = true
   end

   def compile_note(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<aside id="fn#{idstr}" epub:type="#{phr.namedowncase}">], @xindent))
      @xfile.puts(indent("<p>", @xindent + 2))
      phrase = check_refstr(phr)
      if /\A</ =~ phrase #phr.phrase
         @xfile.puts(indent(%Q[<span id="#{idstr}">], @xindent + 4))
         @xfile.puts(indent("#{phrase}", @xindent + 6))
         @xfile.puts(indent("</span>", @xindent + 4))
      else
#         @xfile.puts(indent(%Q[<span id="#{idstr}">#{phr.phrase}</span>], @xindent + 4))
         @xfile.puts(indent(%Q[<span id="#{idstr}">#{phrase}</span>], @xindent + 4))
      end
      @xfile.puts(indent("</p>", @xindent + 2))
      @xfile.puts(indent("</aside>", @xindent))
   end

   def check_refstr(phr)
      phrase = phr.phrase.sub(/^[\s　]+/, "")
      unless phr.noteref.nil?
         phr.cut_brace
         phrase = "#{phr.noteref}:#{phrase} 注、終わり。"
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
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      @xfile.puts(indent(%Q[<aside id="si#{idstr}">], @xindent))
#      @xfile.puts(indent(%Q[<hd>#{phr.caption}</hd>], @xindent + 2)) unless phr.caption.nil?
      @xfile.puts(indent(%Q[<header>#{phr.caption}</header>], @xindent + 2)) unless phr.caption.nil?
      phr.phrase.each_line {|p|
         @xfile.puts(indent("<p>", @xindent + 2))
         phrase = p.sub(/^[\s　]+/, "")
         @xfile.puts(indent(%Q[<span id="#{idstr}">#{phrase}</span>], @xindent + 4))
         @xfile.puts(indent("</p>", @xindent + 2))
      }
      @xfile.puts(indent("</aside>", @xindent))
   end

   def compile_text(phr)
      phr.phrase.sub!(/^[\s　]+/, "") if @paragraph_print
      check_paragraph()
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      print_phrase(phr, idstr)
      @normal_print = true
   end

   def compile_quote(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      if /\Ab/ =~ phr.border
         @xfile.puts(indent(%Q[<blockquote id="#{idstr}" class="border">], @xindent))
      else
         @xfile.puts(indent(%Q[<blockquote id="#{idstr}">], @xindent))
      end
      phr.lines.each {|sent|
         phrase = sent.phrase.sub(/^[\s　]+/, "")
         if /^<span class="(x?[1-9])">/ =~ phrase
            num = $1
            phrase.sub!(/<span class=".+">/, "")
            phrase.sub!("</span>", "")
            @xfile.puts(indent(%Q[<p class="indent_#{num}">], @xindent + 2))
         else
            @xfile.puts(indent("<p>", @xindent + 2))
         end
         @xfile.puts(indent("<span>#{phrase}</span>", @xindent + 4))
         @xfile.puts(indent("</p>", @xindent + 2))
      }
      @xfile.puts(indent("</blockquote>", @xindent))
   end

   def compile_pagenum(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      str = phr.cut_kana
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

   def compile_list(phr)
      chapnum, idstr = compile_id(phr)
      phr.ncxsrc = "#{PTK}#{chapnum}.xhtml##{idstr}"
      if "begin" == phr.args
         @xfile.puts(indent("<#{phr.type}>", @xindent))
      end
      @xindent += 4
      if '' == phr.dl
         @xfile.puts(indent("<li>", @xindent - 2))
         print_phrase(phr, idstr)
         @xfile.puts(indent("</li>", @xindent - 2))
      elsif 'dt' == phr.dl
         if phr.args.nil?
            @xfile.puts(indent("</dd>", @xindent - 2))
         end
         @xfile.puts(indent("<dt>", @xindent - 2))
         print_phrase(phr, idstr)
      elsif 'dd0' == phr.dl
         @xfile.puts(indent("</dt>", @xindent - 2))
         @xfile.puts(indent("<dd>", @xindent - 2))
         print_phrase(phr, idstr)
      elsif /dd[1-9]+/ =~ phr.dl
         @xfile.puts(indent("<br />", @xindent - 2))
         print_phrase(phr, idstr)
      end
      @xindent -= 4
      if "end" == phr.args
         if 'dl' == phr.type
            @xfile.puts(indent("</dd>", @xindent + 2))
         end
         @xfile.puts(indent("</#{phr.type}>", @xindent))
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

   def tag_vih(args)
      if "rtl" == @meta.pageDirection
         return %Q[<span class="vih">#{args}</span>]
      elsif "ltr" == @meta.pageDirection
         return args
      end
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
      @xfile.puts(indent(%Q[<aside id="an#{idstr}" class="figanno">], @xindent))
      prodnote_print(phr, idstr)
   end

   def prodnote_print(phr, idstr)
      @xfile.puts(indent("<p>", @xindent + 2))
      phrase = phr.phrase.sub(/^[\s　]+/, "")
      @xfile.puts(indent(%Q[<span id="#{idstr}">#{phrase}</span>], @xindent + 4))
      @xfile.puts(indent("</p>", @xindent + 2))
      @xfile.puts(indent(%Q[</aside>], @xindent))
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
#      if /#{KATA}+/ =~ r
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
