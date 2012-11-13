# encoding: utf-8
#
# Copyright (c) 2011, 2012 Kishida Atsushi
#

class Daisy
   def collect_ncx_data
      @headlines = []
      @pages = []
      navid = 0
      @depth = 0
      @totalPage = 0
      @maxPage = 0
      @ncxnotetype = []
      @ncxnote = []
      self.book.each {|chapter|
         chapter.sections.each {|section|
            section.phrases.each {|phr|
               if headlineSentence?(phr) or doctitleSentence?(phr)
                  navid += 1
                  phr.readid = navid
                  @headlines << phr
                  @depth = phr.arg.to_i if @depth < phr.arg.to_i
               elsif phr.kind_of?(Page)
                  navid += 1
                  phr.readid = navid
                  @pages << phr
                  @totalPage += 1
                  if phr.instance_of?(Normal)
                     @maxPage = phr.cut_kana.to_i if @maxPage < phr.cut_kana.to_i
                  end
               elsif phr.kind_of?(Footnote)
                  unless %r!/! =~ phr.tag
                     navid += 1
                     phr.navid = navid
                     @ncxnotetype << phr.namedowncase
                     @ncxnote << phr
                  end
               end
            }
         }
      }
      @ncxnotetype.uniq!
   end

   def headlineSentence?(phr)
      phr.instance_of?(Headline::Sentence)
   end
   def doctitleSentence?(phr)
      phr.instance_of?(Title::Sentence)
   end
end

class Daisy3

   def build_ncx_header
      @nf.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "ncx-2005-1.dtd">
<ncx version="2005-1" xml:lang="#{@meta.language}" xmlns="http://www.daisy.org/z3986/2005/ncx/">
  <head>
    <smilCustomTest id="normal" defaultState="#{@skippable.normal}" override="visible" bookStruct="PAGE_NUMBER" />
    <smilCustomTest id="front" defaultState="#{@skippable.front}" override="visible" bookStruct="PAGE_NUMBER" />
    <smilCustomTest id="special" defaultState="#{@skippable.special}" override="visible" bookStruct="PAGE_NUMBER" />
    <smilCustomTest id="note" defaultState="#{@skippable.note}" override="visible" bookStruct="NOTE" />
    <smilCustomTest id="noteref" defaultState="#{@skippable.noteref}" override="visible" bookStruct="NOTE_REFERENCE" />
    <smilCustomTest id="annotation" defaultState="#{@skippable.annotation}" override="visible" bookStruct="ANNOTATION" />
    <smilCustomTest id="linenum" defaultState="#{@skippable.linenum}" override="visible" bookStruct="LINE_NUMBER" />
    <smilCustomTest id="sidebar" defaultState="#{@skippable.sidebar}" override="visible" bookStruct="OPTIONAL_SIDEBAR" />
    <smilCustomTest id="prodnote" defaultState="#{@skippable.prodnote}" override="visible" bookStruct="OPTIONAL_PRODUCER_NOTE" />
EOT
   end

   def build_ncx_meta
      @nf.puts <<EOT
    <meta name="dtb:uid" content="#{@meta.iUid}" />
    <meta name="dtb:depth" content="#{@depth}" />
    <meta name="dtb:generator" content="#{GENERATOR}" />
    <meta name="dtb:totalPageCount" content="#{@totalPage}" />
    <meta name="dtb:maxPageNumber" content="#{@maxPage}" />
  </head>
  <docTitle>
    <text>#{@meta.title}</text>
  </docTitle>
EOT
      if @meta.author.kind_of?(Array)
         @meta.author.each {|a|
            print_docauthor(a)
         }
      else
         print_docauthor(@meta.author)
      end
   end

   def print_docauthor(name)
      @nf.puts <<EOT
  <docAuthor>
    <text>#{name}</text>
  </docAuthor>
EOT
   end

   def build_ncx_post
      @nf.puts <<EOT
</ncx>
EOT
   end

   def build_ncx_navmap_pre
      @nf.puts <<EOT
  <navMap>
EOT
   end

   def build_ncx_navmap_post
      @nf.puts <<EOT
  </navMap>
EOT
   end

   def build_ncx_navmap(phr)
      navid = "nav#{zerosuplement(phr.readid, 5)}"
      pIndent = 2 + phr.arg * 2
      @nf.puts(indent(%Q[<navPoint id="#{navid}" playOrder="#{phr.readid}" class="level#{phr.arg}">], pIndent))
      @nf.puts(indent(%Q[<navLabel>], pIndent + 2))
      @nf.puts(indent(%Q[<text>#{phr.phrase}</text>], pIndent + 4))
      @nf.puts(indent(%Q[</navLabel>], pIndent + 2))
      @nf.puts(indent(%Q[<content src="#{phr.ncxsrc}" />], pIndent + 2))
   end

   def build_ncx_navmap_navpoint_post(level)
      pIndent = 2 + level * 2
      @nf.puts(indent("</navPoint>", pIndent))
   end

   def build_ncx_navmap_navpoint_downto_post(level)
      if 1 < level
         (level - 1).downto(1) {|l|
            pIndent = 2 + l * 2
            @nf.puts(indent("</navPoint>", pIndent))
         }
      end
   end

   def build_ncx_pagelist_pre
      @nf.puts <<EOT
  <pageList>
EOT
   end

   def build_ncx_pagelist_post
      @nf.puts <<EOT
  </pageList>
EOT
   end

   def build_ncx_pagelist(phr)
      str = phr.cut_kana
      navid = "nav#{zerosuplement(phr.readid, 5)}"
      @nf.puts <<EOT
    <pageTarget id="#{navid}" type="#{phr.namedowncase}" class="#{phr.namedowncase}" playOrder="#{phr.readid}" value="#{str}">
      <navLabel>
        <text>#{str}</text>
      </navLabel>
      <content src="#{phr.ncxsrc}" />
    </pageTarget>
EOT
   end

   def build_ncx_navlist_pre(type)
      label = set_navLabel(type)
      @nf.puts <<EOT
  <navList id="#{type}-navList" class="#{type}">
    <navLabel>
      <text>#{label}</text>
    </navLabel>
EOT
   end

   def set_navLabel(type)
      return LABEL_NOTE if 'note' == type
      return LABEL_PROD if 'prodnote' == type
      return LABEL_ANNO if 'annotation' == type
      return LABEL_SIDE if 'sidebar' == type
   end

   def build_ncx_navlist_post
      @nf.puts <<EOT
  </navList>
EOT
   end

   def build_ncx_navlist(phr, num)
      navid = "nav#{zerosuplement(phr.navid, 5)}"
      ncxsrc = phr.ncxsrc.ncxsrc
      num = phr.ref if note_with_ref?(phr)
      if phr.ncxsrc.instance_of?(Sidebar::Caption)
         num = phr.ncxsrc.phrase
      end
      @nf.puts <<EOT
    <navTarget id="#{navid}" class="#{phr.namedowncase}" playOrder="#{phr.navid}">
      <navLabel>
        <text>#{num}</text>
      </navLabel>
      <content src="#{ncxsrc}" />
    </navTarget>
EOT
   end

end

class Daisy4

   def build_nav_header
      stylesheetStr = alternate_stylesheet("nav")
      @nf.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops" lang="#{@meta.language}" xml:lang="#{@meta.language}">
   <head>
      <title>目次</title>
#{stylesheetStr}
   </head>

   <body>
EOT
   end

   def build_nav_footer
      @nf.puts <<EOT
   </body>
</html>
EOT
   end

   def build_nav_pre
      @nf.puts <<EOT
      <nav epub:type="toc" id="toc">
         <h1>目次</h1>
EOT
   end

   def build_nav_pagelist_pre
      @nf.puts <<EOT
      <nav epub:type="page-list" style="display:none" id="page-list">
EOT
   end

   def build_nav_post
      @nf.puts <<EOT
      </nav>
EOT
   end

   def build_nav_section_root_pre(num)
      @nf.puts(indent("<ol>", num))
   end

   def build_nav_section_root_post(num)
      @nf.puts(indent("</ol>", num))
   end

   def build_nav_headline(phr, num)
      build_nav_list_pre(num)
      build_nav_item(phr, num + 3)
   end

   def build_nav_list_pre(num)
      @nf.puts(indent("<li>", num))
   end

   def build_nav_list_post(num)
      @nf.puts(indent("</li>", num))
   end

   def make_uri_navid(phr)
      navid = "phr#{zerosuplement(phr.readid, 5)}"
      uri = "Content/#{phr.ncxsrc}"
      return uri, navid
   end

   def build_nav_item(phr, num)
      uri, navid = make_uri_navid(phr)
      if "" == phr.phrase
         @nf.puts(indent(%Q[<a href="#{uri}" id="#{navid}">　</a>], num))
      else
         @nf.puts(indent(%Q[<a href="#{uri}" id="#{navid}">#{phr.phrase}</a>], num))
      end
   end

   def build_nav_item_page(phr, num)
      uri, navid = make_uri_navid(phr)
      @nf.puts(indent(%Q[<a href="#{uri}" id="#{navid}">#{phr.cut_kana}</a>], num))
   end
end
