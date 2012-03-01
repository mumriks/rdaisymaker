# encoding: utf-8
#
# Copyright (c) 2011, 2012 Kishida Atsushi
#

class TEXTDaisy

   def build_ncx_header(ncxfile)
      ncxfile.puts <<EOT
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

   def build_ncx_meta(ncxfile, depth, totalPage, maxPage)
      ncxfile.puts <<EOT
    <meta name="dtb:uid" content="#{@meta.iUid}" />
    <meta name="dtb:depth" content="#{depth}" />
    <meta name="dtb:generator" content="#{GENERATOR}" />
    <meta name="dtb:totalPageCount" content="#{totalPage}" />
    <meta name="dtb:maxPageNumber" content="#{maxPage}" />
  </head>
  <docTitle>
    <text>#{@meta.title}</text>
  </docTitle>
  <docAuthor>
    <text>#{@meta.author}</text>
  </docAuthor>
EOT
   end

   def build_ncx_post(ncxfile)
      ncxfile.puts <<EOT
</ncx>
EOT
   end

   def build_ncx_navmap_pre(ncxfile)
      ncxfile.puts <<EOT
  <navMap>
EOT
   end

   def build_ncx_navmap_post(ncxfile)
      ncxfile.puts <<EOT
  </navMap>
EOT
   end

   def build_ncx_navmap(ncxfile, phr)
      navid = "nav#{zerosuplement(phr.readid, 5)}"
      pIndent = 2 + phr.args * 2
      ncxfile.puts(indent(%Q[<navPoint id="#{navid}" playOrder="#{phr.readid}" class="level#{phr.args}">], pIndent))
      ncxfile.puts(indent(%Q[<navLabel>], pIndent + 2))
      ncxfile.puts(indent(%Q[<text>#{phr.phrase}</text>], pIndent + 4))
      ncxfile.puts(indent(%Q[</navLabel>], pIndent + 2))
      ncxfile.puts(indent(%Q[<content src="#{phr.ncxsrc}" />], pIndent + 2))
   end

   def build_ncx_navmap_navpoint_post(ncxfile, level)
      pIndent = 2 + level * 2
      ncxfile.puts(indent("</navPoint>", pIndent))
   end

   def build_ncx_pagelist_pre(ncxfile)
      ncxfile.puts <<EOT
  <pageList>
EOT
   end

   def build_ncx_pagelist_post(ncxfile)
      ncxfile.puts <<EOT
  </pageList>
EOT
   end

   def build_ncx_pagelist(ncxfile, phr)
      str = phr.cut_kana
      navid = "nav#{zerosuplement(phr.readid, 5)}"
      ncxfile.puts <<EOT
    <pageTarget id="#{navid}" type="#{phr.namedowncase}" class="#{phr.namedowncase}" playOrder="#{phr.readid}" value="#{str}">
      <navLabel>
        <text>#{str}</text>
      </navLabel>
      <content src="#{phr.ncxsrc}" />
    </pageTarget>
EOT
   end

   def build_ncx_navlist_pre(ncxfile, type)
      ncxfile.puts <<EOT
  <navList id="#{type}-navList" class="#{type}">
    <navLabel>
      <text>#{type}</text>
    </navLabel>
EOT
   end

   def build_ncx_navlist_post(ncxfile)
      ncxfile.puts <<EOT
  </navList>
EOT
   end

   def build_ncx_navlist(ncxfile, phr, num) # add 'num'
      navid = "nav#{zerosuplement(phr.readid, 5)}"
      ncxfile.puts <<EOT
    <navTarget id="#{navid}" class="#{phr.namedowncase}" playOrder="#{phr.readid}">
      <navLabel>
        <text>#{num}</text>
      </navLabel>
      <content src="#{phr.ncxsrc}" />
    </navTarget>
EOT
   end

   def collect_ncx_data
      @headlines = []
      @pages = []
      navid = 0
      @depth = 0
      @totalPage = 0
      @maxPage = 0
      @ncxnotetype = []
      @ncxnote = []
#      note = Hash.new(0)
#      noteref = {}
      self.book.each {|chapter|
         chapter.sections.each {|section|
            section.phrases.each {|phr|
               if phr.instance_of?(Headline)
                  navid += 1
                  phr.readid = navid
                  @headlines << phr
                  @depth = phr.args.to_i if @depth < phr.args.to_i
               elsif phr.kind_of?(Page)
                  navid += 1
                  phr.readid = navid
                  @pages << phr
                  @totalPage += 1
                  if phr.instance_of?(Normal)
                     @maxPage = phr.cut_kana.to_i if @maxPage < phr.cut_kana.to_i
                  end
=begin
               elsif phr.instance_of?(Noteref)
                  navid += 1
                  phr.readid = navid
                  note[phr.args] = navid + 1
                  navid = navid + 1
                  noteref[phr.args] = '1'
                  @ncxnotetype << phr.namedowncase
                  @ncxnote << phr
               elsif phr.instance_of?(Note)
                  unless noteref[phr.args] == nil
                     phr.readid = note[phr.args]
                     note[phr.args] += 1
                     @ncxnotetype << phr.namedowncase
                     @ncxnote << phr
                  else
                     navid += 1
                     phr.readid = navid
                     @ncxnotetype << phr.namedowncase
                     @ncxnote << phr
                  end
=end
=begin
               elsif phr.instance_of?(Noteref)
# not need Noteref ?
#                  navid += 1
#                  phr.readid = navid
#                  @ncxnotetype << phr.namedowncase
#                  @ncxnote << phr
                  p = phr
                  until p.child.nil?
                     navid += 1
                     p.child.readid = navid
#                     @ncxnotetype << p.child.namedowncase
#                     @ncxnote << p.child
                     p = p.child
                  end
#                  phr.child.readid = navid
# end of (not need Noteref ?)
=end
               elsif phr.kind_of?(NoteGroup) #phr.instance_of?(Note)
                  navid += 1
                  phr.readid = navid
                  @ncxnotetype << phr.namedowncase
                  @ncxnote << phr
=begin
               elsif prod?(phr) or anno?(phr) or side?(phr)
                  navid += 1
                  phr.readid = navid
                  @ncxnotetype << phr.namedowncase
                  @ncxnote << phr
=end
               end
            }
         }
      }
      @ncxnotetype = @ncxnotetype.uniq
   end

   private

   def prod?(phr)
      phr.instance_of?(Prodnote)
   end
   def anno?(phr)
      phr.instance_of?(Annotation)
   end
   def side?(phr)
      phr.instance_of?(Sidebar)
   end
end
