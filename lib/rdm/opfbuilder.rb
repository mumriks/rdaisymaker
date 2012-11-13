# encoding: utf-8
#
# Copyright (c) 2011, 2012 Kishida Atsushi
#

class Daisy

   def build_opf_manifest_pre
      @of.puts <<EOT
   <manifest>
EOT
   end

   def build_opf_manifest_post
      @of.puts <<EOT
   </manifest>
EOT
   end

   def build_opf_spine_pre
      @of.puts <<EOT
   <spine>
EOT
   end

   def build_opf_spine_post
      @of.puts <<EOT
   </spine>
EOT
   end

   def build_opf_package_post
      @of.puts <<EOT
</package>
EOT
   end

   def build_manifest_item(type, num, path)
      @of.puts <<EOT
      <item media-type="#{type}" id="#{num}" href="#{path}"/>
EOT
   end

   def check_file_type(img)
      extname = File.extname(img)
      if '.jpg' == extname
         type = "image/jpeg"
      elsif '.png' == extname
         type = "image/png"
      elsif '.svg' == extname
         type = "image/svg+xml"
      elsif '.mp4' == extname
         type = "audio/mpeg4-generic"
      elsif '.mp3' == extname
         type = "audio/mpeg"
      end
      type
   end
end

class Daisy3

   def build_opf_meta
      totalTime = makeTotalTime()
      @of.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE package PUBLIC "+//ISBN 0-9673008-1-9//DTD OEB 1.2 Package//EN" "oebpkg12.dtd">
<package unique-identifier="uid" xmlns="http://openebook.org/namespaces/oeb-package/1.0/">
   <metadata>
      <dc-metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
         <dc:Title>#{@meta.title}</dc:Title>
         <dc:Publisher>#{@meta.publisher}</dc:Publisher>
         <dc:Date>#{@meta.date}</dc:Date>
         <dc:Format>#{@meta.format}</dc:Format>
         <dc:Language>#{@meta.language}</dc:Language>
         <dc:Identifier id="uid">#{@meta.iUid}</dc:Identifier>
         <dc:Identifier scheme="ISBN">#{@meta.isbn}</dc:Identifier>
EOT

      printAuthor(@meta.author)
      [[@meta.translator, "trl"],
       [@meta.editor, "edt"],
       [@meta.illustlator, "ill"],
       [@meta.photographer, "pht"],
       [@contributor,]].each {|name, rolestr|
         printContributor(name, rolestr) if name
      }

      @of.puts <<EOT
      </dc-metadata>
      <x-metadata>
EOT
      [["sourceDate", @xmeta.sourceDate],
       ["sourceEdition", @xmeta.sourceEdition],
       ["sourcePublisher", @xmeta.sourcePublisher],
       ["sourceRights", @xmeta.sourceRights],
       ["sourceTitle", @xmeta.sourceTitle],
       ["narrator", @xmeta.narrator],
       ["producer", @xmeta.producer],
       ["producedDate", @xmeta.producedDate],
       ["revision", @xmeta.revision],
       ["revisionDate", @xmeta.revisionDate],
       ["revisionDescription", @xmeta.revisionDescription],
       ["audioFormat", @xmeta.audioFormat]].each {|word, name|
          printXmeta(word, name) if name
       }
      
      @of.puts <<EOT
         <meta name="dtb:multimediaType" content="#{@xmeta.multimediaType}" />
         <meta name="dtb:multimediaContent" content="#{@xmeta.multimediaContent}" />
         <meta name="dtb:totalTime" content="#{totalTime}" />
      </x-metadata>
   </metadata>
EOT
   end

   def build_opf_etc_manifest
      @of.puts <<EOT
      <item id="ncx" href="#{@bookname}.ncx" media-type="application/x-dtbncx+xml" />
      <item id="opf" href="#{@bookname}.opf" media-type="text/xml" />
      <item id="misc1" href="#{@bookname}.xsl" media-type="application/xslt+xml" />
      <item id="resource" href="#{@bookname}.res" media-type="application/x-dtbresource+xml" />
      <item id="misc2" href="#{@bookname}.css" media-type="text/css" />
EOT
   end

   def build_opf_spine(num)
      @of.puts <<EOT
      <itemref idref="#{num}" />
EOT
   end

   private

   def makeTotalTime
      if @daisy2 and 'audioFullText' == @xmeta.multimediaType
         totalTime = calc_totalTime()
      else
         totalTime = @xmeta.totalTime
      end
      return totalTime
   end

   def printAuthor(name)
      if name.kind_of?(Array)
         name.each {|a| creatorWithRole(a, "author") }
      else
         creatorWithRole(name, "author")
      end
   end

   def creatorWithRole(name, rolestr)
      @of.puts <<EOT
         <dc:Creator role="#{rolestr}">#{name}</dc:Creator>
EOT
   end

   def printContributor(name, rolestr = nil)
      if name.kind_of?(Array)
         name.each {|am|
            contributorWithRole(am, rolestr)
         }
      else
         contributorWithRole(name, rolestr)
      end
   end

   def contributorWithRole(name, rolestr)
      if rolestr.nil?
         @of.puts <<EOT
         <dc:Contributor>#{name}</dc:Contributor>
EOT
      else
         @of.puts <<EOT
         <dc:Contributor role="#{rolestr}">#{name}</dc:Contributor>
EOT
      end
   end

   def printXmeta(name, content)
      @of.puts <<EOT
         <meta name="dtb:#{name}" content="#{content}" />
EOT
   end

end

class Daisy4

   def build_opf_header
      @of.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf"
         xmlns:dc="http://purl.org/dc/elements/1.1/"
         unique-identifier="pub-id" version="3.0">
EOT
   end

   def build_opf_meta
      t = Time.now
      modifiedDate = %Q[#{t.strftime("%Y-%m-%dT%H:%M:%SZ")}]
      date = @xmeta.sourceDate #
      date = @meta.date if date.nil? #
      @of.puts <<EOT
   <opf:metadata xmlns:opf="http://www.idpf.org/2007/opf">
      <dc:identifier id="pub-id">urn:uuid:#{@meta.iUid}</dc:identifier>
      <dc:title id="title">#{@meta.title}</dc:title>
      <dc:language>#{@meta.language}</dc:language>
      <dc:date id="date">#{date}</dc:date>
      <dc:format>#{@meta.format}</dc:format>
EOT
      roleid = 1
      [["author","aut"],
       ["translator", "trl"],
       ["editor","edt"],
       ["illustlator","ill"],
       ["photographer","pht"]].each {|role, r|
         name = eval("@meta.#{role}")
         unless name.nil?
           if name.kind_of?(Array)
              name.each {|n|
                 print_contributor(roleid, n, r)
                 roleid += 1
              }
           else
            print_contributor(roleid, name, r)
            roleid += 1
           end
         end
      }
      @of.puts <<EOT
      <dc:publisher>#{@meta.publisher}</dc:publisher>
      <meta property="dcterms:modified">#{modifiedDate}</meta>
      <opf:meta name="dcterms:modified" content="#{modifiedDate}"/>
   </opf:metadata>
EOT
   end

   def print_contributor(id, name, role)
      @of.puts <<EOT
      <dc:creator id="creator#{id}">#{name}</dc:creator>
      <meta refines="#creator#{id}" property="role" scheme="marc:relators">#{role}</meta>
      <meta refines="#creator#{id}" property="display-seq">#{id}</meta>
EOT
   end

   def build_nav_manifest
      @of.puts <<EOT
      <item media-type="application/xhtml+xml" id="nav" href="toc.xhtml" properties="nav" />
      <item media-type="text/css" id="horizontal" href="Styles/horizontal.css"/>
      <item media-type="text/css" id="vertical" href="Styles/vertical.css"/>
EOT
   end

   def build_cover_page_manifest
      @of.puts <<EOT
      <item media-type="application/xhtml+xml" id="cover_page" href="Content/cover.xhtml" />
      <item media-type="text/css" id="cover_horizontal" href="Styles/cover_horizontal.css"/>
      <item media-type="text/css" id="cover_vertical" href="Styles/cover_vertical.css"/>
EOT
   end

   def build_cover_item(type, idstr, file)
      @of.puts <<EOT
      <item media-type="#{type}" id="#{idstr}" href="#{file}" properties="cover-image" />
EOT
   end

   def build_manifest_item(type, num, path)
      @of.puts <<EOT
      <item media-type="#{type}" id="#{num}" href="#{path}"/>
EOT
   end

   def build_opf_spine_pre
      @of.puts <<EOT
   <spine page-progression-direction="#{@meta.pageDirection}">
EOT
   end

   def build_opf_spine(num, ref)
      @of.puts <<EOT
      <itemref idref="#{num}" id="#{ref}"/>
EOT
   end
end
