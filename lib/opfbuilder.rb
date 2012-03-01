# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#

class TEXTDaisy

   def build_opf_meta(opffile)
      opffile.puts <<EOT
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

      print_contributor(opffile, "trl", "translator") unless @meta.translator.nil?
      print_contributor(opffile, "edt", "editor") unless @meta.editor.nil?
      print_contributor(opffile, "ill", "illustlator") unless @meta.illustlator.nil?
      print_contributor(opffile, "pht", "photographer") unless @meta.photographer.nil?

      opffile.puts <<EOT
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

   def build_opf_manifest_pre(opffile)
      opffile.puts <<EOT
  <manifest>
EOT
   end

   def build_opf_manifest_post(opffile)
      opffile.puts <<EOT
  </manifest>
EOT
   end

   def build_opf_etc_manifest(opffile)
      opffile.puts <<EOT
    <item id="ncx" href="#{@bookname}.ncx" media-type="application/x-dtbncx+xml" />
    <item id="opf" href="#{@bookname}.opf" media-type="text/xml" />
    <item id="misc1" href="#{@bookname}.xsl" media-type="application/xslt+xml" />
    <item id="resource" href="#{@bookname}.res" media-type="application/x-dtbresource+xml" />
    <item id="misc2" href="#{@bookname}.css" media-type="text/css" />
EOT
   end

   def build_opf_img_manifest(opffile, num, img)
      type = check_img_type(img)
      opffile.puts <<EOT
    <item id="misc#{num}" href="image/#{img}" media-type="#{type}" />
EOT
   end

   def build_opf_xml_smil_manifest(opffile, num, file, type)
      opffile.puts <<EOT
    <item id="misc#{num}" href="#{file}" media-type="#{type}" />
EOT
   end

   def build_opf_spine_pre(opffile)
      opffile.puts <<EOT
  <spine>
EOT
   end

   def build_opf_spine_post(opffile)
      opffile.puts <<EOT
  </spine>
EOT
   end

   def build_opf_spine(opffile, num)
      opffile.puts <<EOT
    <itemref idref="misc#{num}" />
EOT
   end

   def build_opf_package_post(opffile)
      opffile.puts <<EOT
</package>
EOT
   end

   private

   def print_contributor(opffile, rolestr, metastr)
      m = eval "@meta.#{metastr}"
      opffile.puts <<EOT
      <dc:Contributor role="#{rolestr}">#{m}</dc:Contributor>
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
