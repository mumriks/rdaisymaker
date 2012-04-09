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

   def check_img_type(img)
      extname = File.extname(img)
      if '.jpg' == extname
         type = "image/jpeg"
      elsif '.png' == extname
         type = "image/png"
      end
      type
   end
end

class TEXTDaisy

   def build_opf_meta
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
         <dc:Creator role="author">#{@meta.author}</dc:Creator>
EOT

      print_contributor("trl", "translator") unless @meta.translator.nil?
      print_contributor("edt", "editor") unless @meta.editor.nil?
      print_contributor("ill", "illustlator") unless @meta.illustlator.nil?
      print_contributor("pht", "photographer") unless @meta.photographer.nil?

      @of.puts <<EOT
      </dc-metadata>
      <x-metadata>
         <meta name="dtb:sourceDate" content="#{@xmeta.sourceDate}" />
         <meta name="dtb:sourcePublisher" content="#{@xmeta.sourcePublisher}" />
         <meta name="dtb:multimediaType" content="#{@xmeta.multimediaType}" />
         <meta name="dtb:multimediaContent" content="#{@xmeta.multimediaContent}" />
         <meta name="dtb:totalTime" content="#{@xmeta.totalElapsedTime}" />
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

   def print_contributor(rolestr, metastr)
      m = eval "@meta.#{metastr}"
      @of.puts <<EOT
         <dc:Contributor role="#{rolestr}">#{m}</dc:Contributor>
EOT
   end
end

class TEXTDaisy4

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
      @of.puts <<EOT
   <opf:metadata xmlns:opf="http://www.idpf.org/2007/opf">
      <dc:identifier id="pub-id">urn:uuid:#{@meta.iUid}</dc:identifier>
      <dc:title id="title">#{@meta.title}</dc:title>
      <dc:language>#{@meta.language}</dc:language>
      <dc:date id="date">#{@xmeta.sourceDate}</dc:date>
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
            print_contributor(roleid, name, r)
            roleid += 1
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
      <item media-type="application/xhtml+xml" id="navi" href="toc.xhtml" properties="nav" />
      <item media-type="text/css" id="horizontal" href="Styles/#{@bookname}_horizontal.css"/>
      <item media-type="text/css" id="vertical" href="Styles/#{@bookname}_vertical.css"/>
EOT
   end
#      <item media-type="text/css" id="css" href="Styles/#{@bookname}.css"/>

   def build_cover_page_manifest
      @of.puts <<EOT
      <item media-type="application/xhtml+xml" id="cover_page" href="Content/cover.xhtml" />
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

   def build_opf_spine(num, ref)
      @of.puts <<EOT
      <itemref idref="#{num}" id="#{ref}"/>
EOT
   end
end
