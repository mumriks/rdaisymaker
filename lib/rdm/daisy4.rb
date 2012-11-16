# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#
class TEXTDaisy4 < Daisy4
   def initialize(values)
      super
      @xmeta.multimediaType = "textstream"
      @xmeta.multimediaContent = "text"
      @meta.format = "EPUB3"
   end
end
class AudioFullTextDaisy4 < Daisy4
   def initialize(values)
      super
      @xmeta.multimediaType = "audioFullText"
      @xmeta.multimediaContent = "audio,text"
      @meta.format = "EPUB3"
      @audio_list = []
   end
   attr_accessor :audio_list

   def copy_audio_file(file, dstname)
      Dir.mkdir(@a_path) unless File.exist?(@a_path)
      FileUtils.cp(file, "#{@a_path}/#{dstname}")
      @audio_list << "#{@a_path}/#{dstname}"
   end

   def check_audio_file(file)
      disk_name = check_strict_exist?(file)
      extname = File.extname(disk_name)
      basename = File.basename(disk_name, ".*")
      return 'errmes5', file unless Daisy::FT_AUDIO =~ extname.downcase
      ext, extname = extname_unmatch?(extname)
      base, basename = basename_unmatch?(basename, extname)
      if ext or base
         puts "'#{disk_name}' のファイル名を '#{basename}#{extname}' に変更しました。"
      end
      copy_audio_file(file, "#{basename}#{extname}")
      return nil, "#{basename}#{extname}"
   end
end

class Daisy4
   attr_accessor :datevih, :i_path, :a_path

   def build_cover(file)
      File.open("#{@c_path}/cover.xhtml", "w:UTF-8") {|xf|
         @xfile = xf
         File.open(file, "r:UTF-8") {|f|
            f.each_line {|line|
               mes, @cover_image = check_imagefile(line.chomp)
               if /errmes[1-3]/ =~ mes
                  print_error("[cover]#{Daisy::ERRMES[mes]} #{@cover_image}")
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
      build_text_nav()
      build_text_opf()
   end

   def mk_temp(temp)
      @temp = temp
      @m_path = "#{@temp}/#{@bookname}/META-INF"
      @i_path = "#{@temp}/#{@bookname}/Publication/Images"
      @s_path = "#{@temp}/#{@bookname}/Publication/Styles"
      @c_path = "#{@temp}/#{@bookname}/Publication/Content"
      @p_path = "#{@temp}/#{@bookname}/Publication"
      @a_path = "#{@temp}/#{@bookname}/Publication/Audios"
      [@m_path, @s_path, @c_path, @a_path].each {|path|
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

   private

   def build_xhtml_smil
      chapcount = 0
      @sectcount = 0
      index = 0
      @m_indent = false
      self.book.each {|chapter|
         @@start_level, @@befour_level, @@level = nil, nil, nil
         chapcount += 1
         xhtmlfile = "#{@c_path}/#{PTK}#{self.zerosuplement(chapcount, 5)}.xhtml"
         File.open(xhtmlfile, "w:UTF-8") {|xf|
            @xfile = xf
            xml_header()
            chapter.sections.each {|section|
               @sectcount += 1
               smilfile = "#{@c_path}/#{PTK}#{self.zerosuplement(@sectcount, 5)}.smil"
               File.open(smilfile, "w:UTF-8") {|sf|
                  @sfile = sf
                  section.phrases.each {|phr|
                     if phr.kind_of?(Phrase)
                        unless phr.phrase.kind_of?(Array)
                           phr.phrase = compile_daisy_ruby(phr.phrase)
                           phr.phrase = compile_inline_tag(phr.phrase)
                           phr.unify_period
                        end
                     end
                     phr.compile_xml(self)
                  }
                  smil_header()
                if @daisy2
                     readphr = {}
                     section.phrases.each {|phr|
                        if phr.kind_of?(Phrase)
                           readphr[phr.readid] = phr unless phr.readid.nil?
                        end
                     }
                     pars = []
                     @seqs[index].item.each {|par|
                        pars << par if par.text.instance_of?(Smil::Text)
                     }
                     pars.each {|p|
                        phr = readphr[p.text.id]
                        phr.compile_smil(self) unless phr.nil?
                     }
                else
                  readphr = []
                  section.phrases.each {|phr|
                     if phr.kind_of?(Phrase)
                        readphr << phr unless phr.readid == nil
                     end
                  }
                  readphr.sort_by{|p| p.readid}.each {|phr|
                     phr.compile_smil(self)
                  }
                end
                  smil_footer()
               }
               index += 1
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
         level = 0; section = 0
         indent = 6
         @headlines.each_with_index {|h, i|
            if 0 == i
               build_nav_section_root_pre(indent + 3)
               build_nav_headline(h, indent + 6)
               level = h.arg
               indent += 6
            elsif level < h.arg
               build_nav_section_root_pre(indent + 3)
               build_nav_headline(h, indent + 6)
               level = h.arg
               indent += 6
            elsif level == h.arg
               build_nav_list_post(indent)
               build_nav_headline(h, indent)
            elsif level > h.arg
               (level - h.arg).times {|l|
                  build_nav_list_post(indent)
                  build_nav_section_root_post(indent - 3)
                  indent -= 6
               }
               indent += 3
               build_nav_list_post(indent - 3)
               build_nav_headline(h, indent - 3)
               level = h.arg
               indent -= 3
            end
            if @headlines[i + 1].nil?
               (level).times {|l|
                  build_nav_list_post(indent)
                  build_nav_section_root_post(indent - 3)
                  indent -= 3
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
            type = check_file_type(@cover_image)
            idstr = "cover#{File.extname(@cover_image)}"
            build_cover_item(type, idstr, "Images/#{@cover_image}")
         end
         @img_list.uniq!
         if 0 < @img_list.size
            @img_list.each {|img|
               type = check_file_type(img)
               build_manifest_item(type, "item_#{num}", "#{img}")
               num = num + 1
            }
         end
         @audio_list.uniq! if @audio_list
         if @audio_list and 0 < @audio_list.size
            @audio_list.each {|audio_file|
               type = check_file_type(audio_file)
               build_manifest_item(type, "misc#{num}", "#{audio_file}")
               num += 1
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
          "Publication/Styles/*", "Publication/*",
          "Publication/Audios/*"].each {|dir|
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
      jarfile = find_epubcheck()
      puts "EPUB3 をチェックします・・・"
      exec "java -jar #{jarfile} #{@bookname}.epub"
   end

   def find_epubcheck
      epubjar = Dir.glob(File.join(BINDIR, "../lib/rdm/epubcheck/epubcheck-3*"))
      if 0 == epubjar.size
         print_error("epubcheckファイルが見つかりません")
      elsif 1 < epubjar.size
         print_error("複数のepubcheckファイルがあります。ひとつにしてください")
      elsif 1 == epubjar.size
         return File.expand_path(epubjar[0])
      end
   end

end
