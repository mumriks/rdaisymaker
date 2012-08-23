# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#

class TEXTDaisy4 < Daisy4

   JAR = File.join(BINDIR, "../lib/rdm/epubcheck/epubcheck-3.0b5.jar")

   def initialize(values)
      super
      @xmeta.multimediaType = "textstream"
      @meta.format = "EPUB3"
   end
   attr_accessor :datevih

   def build_cover(file)
      em = {"errmes1" => "[cover]画像ファイルが指定されていません",
            "errmes2" => "[cover]そのファイルは見つかりません : ",
            "errmes3" => "[cover]サポートされていない画像タイプです : ",
            "errmes4" => "[cover]画像が大きすぎるようです"}

      File.open("#{@c_path}/cover.xhtml", "w:UTF-8") {|xf|
         @xfile = xf
         File.open(file, "r:UTF-8") {|f|
            f.each_line {|line|
               mes, @cover_image = check_imagefile(line.chomp)
               if /errmes[1-3]/ =~ mes
                  print_error("#{em[mes]} #{@cover_image}")
               end
               File.rename("#{@i_path}/#{line.chomp}", "#{@i_path}/#{@cover_image}")
               cover_page(@cover_image)
               return
            }
         }
      }
   end
   def build_daisy
      build_xhtml_smil()
   end
   def build_ncx
      build_text_nav()
   end
   def build_opf
      build_text_opf()
   end
   def mk_temp(temp)
      @temp = temp
      @m_path = "#{@temp}/#{@bookname}/META-INF"
      @i_path = "#{@temp}/#{@bookname}/Publication/Images"
      @s_path = "#{@temp}/#{@bookname}/Publication/Styles"
      @c_path = "#{@temp}/#{@bookname}/Publication/Content"
      @p_path = "#{@temp}/#{@bookname}/Publication"
      [@m_path, @s_path, @c_path].each {|path|
         FileUtils.mkdir_p(path)
      }
   end
   def copy_files
      ["horizontal", "vertical"].each {|type|
         distpath = "#{@s_path}/#{type}.css"
         srcpath = File.join(BINDIR, "../doc/#{type}.css")
         FileUtils.cp(srcpath, distpath)
      }
      if File.exist?("#{@c_path}/cover.xhtml")
         ["horizontal", "vertical"].each {|type|
            distpath = "#{@s_path}/cover_#{type}.css"
            FileUtils.cp(File.join(BINDIR, "../doc/cover_#{type}.css"), distpath)
         }
      end
      build_other_file()
      build_epub3()
   end
   def copy_image(image, dstname)
      FileUtils.mkdir_p(@i_path) unless File.exist?(@i_path)
      FileUtils.cp(image, "#{@i_path}/#{dstname}")
   end
   def check_imagefile(image)
      return 'errmes2', image unless File.exist?(image)
      basename = File.basename(image, ".*")
      extname = File.extname(image)
      return 'errmes3', image unless /\.jpe*g|\.png/ =~ extname
      extname = '.jpg' if '.jpeg' == extname
      width, height = get_image_size(image)
      copy_image(image, "#{basename}#{extname}")
      return 'errmes4',image unless IMGHEIGHT >= height
      return 'errmes4',image unless IMGWIDTH >= width
      return nil, "#{basename}#{extname}"
   end

   private

   def build_xhtml_smil
      @chapcount = 0
      @sectcount = 0
      @m_indent = false
      self.book.each {|chapter|
         @level = 1
         @chapcount += 1
         @tnum = 0
         xhtmlfile = "#{@c_path}/#{PTK}#{self.zerosuplement(@chapcount, 5)}.xhtml"
         File.open(xhtmlfile, "w:UTF-8") {|xf|
            @xfile = xf
            xml_header()
            chapter.sections.each {|section|
               @sectcount += 1
               smilfile = "#{@c_path}/#{PTK}#{self.zerosuplement(@sectcount, 5)}.smil"
               File.open(smilfile, "w:UTF-8") {|sf|
                  @sfile = sf
                  section.phrases.each {|phr|
                     unless phr.instance_of?(ImageGroup) or phr.instance_of?(Quote)
                        phr.phrase = compile_daisy_ruby(phr.phrase)
                        phr.phrase = compile_inline_tag(phr.phrase)
                     end
                     phr.unify_period
                     phr.compile_xml(self)
                  }
                  smil_header()
                  readphr = []
                  section.phrases.each {|phr|
                     unless phr.readid == nil
                        readphr << phr
                     end
                  }
                  readphr.sort_by{|p| p.readid}.each {|phr|
                     phr.compile_smil(self)
                  }
                  smil_footer()
               }
            }
            xml_footer()
         }
      }
   end

   def build_text_nav
      collect_ncx_data()
      navfile = "#{@p_path}/toc.xhtml"
      File.open(navfile, "w:UTF-8") {|nf|
         @nf = nf
         build_nav_header()
         build_nav_pre()
         level = 0
         indent = 6
         @headlines.each_with_index {|h, i|
            h.adjust_ncx
            if 0 == i
               build_nav_section_root_pre(indent + 3)
               build_nav_headline(h, indent + 6)
               level = h.args
               indent += 6
            elsif level < h.args
               build_nav_section_root_pre(indent + 3)
               build_nav_headline(h, indent + 6)
               level = h.args
               indent += 6
            elsif level == h.args
               build_nav_list_post(indent)
               build_nav_headline(h, indent)
            elsif level > h.args
               build_nav_list_post(indent)
               build_nav_section_root_post(indent - 3)
               build_nav_list_post(indent - 6)
               build_nav_headline(h, indent - 6)
               level = h.args
               indent -= 6
            end
            if @headlines[i + 1].nil?
               (level).times {|l|
                  build_nav_list_post(indent)
                  build_nav_section_root_post(indent - 3)
                  indent -= 6
               }
            end
         }
         build_nav_post()
         indent = 6
         unless 0 == @pages.size
            build_nav_pagelist_pre()
            build_nav_section_root_pre(indent + 3)
            indent += 6
            @pages.each {|n|
               if /normal|front|special/ =~ n.namedowncase
                  build_nav_list_pre(indent)
                  build_nav_item_page(n, indent + 3)
                  build_nav_list_post(indent)
               end
            }
            build_nav_section_root_post(indent - 3)
            build_nav_post()
         end
         build_nav_footer()
      }
   end

   def build_text_opf
      opffile = "#{@p_path}/package.opf"
      File.open(opffile, "w:UTF-8") {|of|
         @of = of
         build_opf_header()
         build_opf_meta()
         build_opf_manifest_pre()
         build_nav_manifest()
         if File.exist?("#{@c_path}/cover.xhtml")
            build_cover_page_manifest()
         end

         num = 1
         sectnum = 0
         chapnum = @book.size
         @book.each {|chapter|
            sectnum = sectnum + chapter.sections.size
         }
         spinenum = num
         chapnum.times {|c|
            xhtml = "Content/#{PTK}#{zerosuplement(c + 1,5)}.xhtml"
            type = "application/xhtml+xml"
            build_manifest_item(type, "item_#{num}", xhtml)
            num = num + 1
         }
         sectnum.times {|s|
            smil = "Content/#{PTK}#{zerosuplement(s + 1,5)}.smil"
            type = "application/smil+xml"
            build_manifest_item(type, "item_#{num}", smil)
            num = num + 1
         }

         unless @cover_image.nil?
            type = check_img_type(@cover_image)
            idstr = "cover#{File.extname(@cover_image)}"
            build_cover_item(type, idstr, "Images/#{@cover_image}")
         end
         if 0 < @img_list.size
            @img_list.each {|img|
               type = check_img_type(img)
               build_manifest_item(type, "item_#{num}", "Images/#{img}")
               num = num + 1
            }
         end

         build_opf_manifest_post()

         build_opf_spine_pre()
         chapnum.times {|c|
            build_opf_spine("item_#{spinenum}", "itemref_#{c + 1}")
            spinenum = spinenum + 1
         }
         build_opf_spine_post()

         build_opf_package_post()
      }
   end

   def build_other_file
      build_container()
   end
   def build_mimetype
      mimetype = "#{@temp}/#{@bookname}/mimetype"
      File.open(mimetype, "w:UTF-8"){|f|
         f.print("application/epub+zip")
      }
   end
   def build_container
      container = "#{@m_path}/container.xml"
      File.open(container, "w:UTF-8"){|f|
         f.puts <<EOT
<?xml version="1.0" encoding="utf-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
   <rootfiles>
      <rootfile full-path="Publication/package.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
EOT
      }
   end

   def build_epub3
      basedir = Dir.pwd
      Dir.chdir("#{@temp}/#{@bookname}")
      Zip::ZipOutputStream.open("#{@bookname}.epub") {|zos|
         zos.put_next_entry("mimetype","","", 0, 0)
         zos.print "application/epub+zip"
      }

      Zip::ZipFile.open("#{@bookname}.epub", Zip::ZipFile::CREATE) {|zf|
         zf.add("META-INF/container.xml", "META-INF/container.xml")
         ["Publication/Images/*", "Publication/Content/*",
          "Publication/Styles/*", "Publication/*"].each {|dir|
            Dir.glob(dir).each {|path|
               unless File.directory?(path)
                  zf.add(path, path)
               end
            }
         }
      }
      Dir.chdir(basedir)
      FileUtils.mv("#{@temp}/#{@bookname}/#{@bookname}.epub", "#{@bookname}.epub")
      epub3check()
   end
   def epub3check
      if File.exist?(JAR)
         puts "EPUB3 をチェックします・・・"
         exec "java -jar #{JAR} #{@bookname}.epub"
      else
         puts "EPUB3 CHECK プログラムがみつかりません。"
      end
   end

   def print_error(errmes)
      raise errmes.encode("SJIS")
      exit 1
   end

end
