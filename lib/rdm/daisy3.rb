# encoding: utf-8
# Copyright (c) 2011 Kishida Atsushi
#

class TEXTDaisy < Daisy3
   def initialize(values)
      super
      @xmeta.multimediaType = "textNCX"
      @xmeta.multimediaContent = "text"
      @xmeta.totalElapsedTime = "0:00:00.000"
      @meta.format = "ANSI/NISO Z39.86-2005"
      @sesame = false
   end
   attr_accessor :sesame, :add_yomi

   def build_cover(file)
      return
   end
   def build_daisy
      build_xml_smil()
   end
   def build_ncx
      build_text_ncx()
   end
   def build_opf
      build_text_opf()
   end
   def mk_temp(temp)
      @temp = temp
      FileUtils.mkdir_p("#{@temp}/#{@bookname}")
   end
   def copy_files
      FileUtils.cp_r("#{@temp}/#{@bookname}/", "./") unless "." == @temp
      dtdfile = %w(dtbook-2005-3.dtd dtbsmil-2005-2.dtd ncx-2005-1.dtd oeb12.ent oebpkg12.dtd resource-2005-1.dtd)
      dtdfile.each {|f|
         distpath = "#{@bookname}/#{f}"
         FileUtils.cp(File.join(BINDIR, "../doc/#{f}"), distpath)
      }
      [".css", ".res", ".xsl"].each {|ext|
        distpath = "#{@bookname}/#{@bookname}#{ext}"
        FileUtils.cp(File.join(BINDIR, "../doc/common#{ext}"), distpath)
      }
      FileUtils.cp(File.join(BINDIR, "../doc/boten2.png"), "#{@bookname}/boten2.png") if @sesame
   end
   def copy_image(image, dstname)
      unless File.exist?("#{@temp}/#{@bookname}/Images")
         Dir.mkdir("#{@temp}/#{@bookname}/Images")
      end
      FileUtils.cp(image, "#{@temp}/#{@bookname}/Images/#{dstname}")
   end

   def check_imagefile(image)
      return 'errmes2' unless File.exist?(image)
      extname = File.extname(image)
      basename = File.basename(image, ".*")
      return 'errmes3' unless /\.jpe*g|\.png/ =~ extname
      extname = '.jpg' if '.jpeg' == extname
      if /[^A-Za-z0-9]+/ =~ basename
         bn = basename.gsub(/[^A-Za-z0-9]+/, '')
         bn = bn + 'aa' if File.exist?("#{bn}#{extname}")
         while File.exist?("#{bn}#{extname}")
            bn = bn.succ
         end
         basename = bn
         puts "'#{image}' のファイル名を '#{basename}#{extname}' に変更しました。"
      end
      width, height = get_image_size(image)
      return 'errmes4' unless IMGHEIGHT >= height
      return 'errmes4' unless IMGWIDTH >= width
      copy_image(image, "#{basename}#{extname}")
      return "#{basename}#{extname}"
   end

   private

   def build_xml_smil
      @chapcount = 0
      @sectcount = 0
      self.book.each {|chapter|
         @level = 1
         @chapcount += 1
         @tnum = 0
         xmlfile = "#{@temp}/#{self.bookname}/#{PTK}#{self.zerosuplement(@chapcount, 5)}.xml"
         File.open(xmlfile, "w:UTF-8") {|xf|
            @xfile = xf
            xml_header()
            chapter.sections.each {|section|
               @sectcount += 1
               smilfile = "#{@temp}/#{self.bookname}/#{PTK}#{self.zerosuplement(@sectcount, 5)}.smil"
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

   def build_text_ncx
      collect_ncx_data()
      ncxfile = "#{@temp}/#{@bookname}/#{@bookname}.ncx"
      File.open(ncxfile, "w:UTF-8") {|nf|
         @nf = nf
         build_ncx_header()
         build_ncx_meta()
         build_ncx_navmap_pre()
         @headlines.each_with_index {|h, i|
            h.adjust_ncx
            build_ncx_navmap(h)
            unless @headlines[i + 1] == nil
               if h.args >= @headlines[i + 1].args
                  s = h.args
                  e = @headlines[i + 1].args
                  s.downto(e) {|l|
                     build_ncx_navmap_navpoint_post(l)
                  }
               end
            else
               build_ncx_navmap_navpoint_post(h.args)
            end
         }
         build_ncx_navmap_post()
         unless 0 == @pages.size
            build_ncx_pagelist_pre()
            @pages.each {|n|
               if /normal|front|special/ =~ n.namedowncase
                  self.build_ncx_pagelist(n)
               end
            }
            self.build_ncx_pagelist_post()
         end
         unless 0 == @ncxnotetype.size
            @ncxnotetype.each {|t|
               num = 1
               build_ncx_navlist_pre(t)
               @ncxnote.each {|n|
                  if t == n.namedowncase
                     build_ncx_navlist(n, num)
                     num += 1
                  end
               }
               build_ncx_navlist_post()
            }
         end
         build_ncx_post()
      }
   end

   def build_text_opf
      opffile = "#{@temp}/#{@bookname}/#{@bookname}.opf"
      File.open(opffile, "w:UTF-8") {|of|
         @of = of
         build_opf_meta()
         build_opf_manifest_pre()
         build_opf_etc_manifest()
         num = 3
         if 0 < @img_list.size
            @img_list.each {|img|
               type = check_img_type(img)
               build_manifest_item(type, "misc#{num}", "Images/#{img}")
               num = num + 1
            }
         end

         sectnum = 0
         chapnum = @book.size
         @book.each {|chapter|
            sectnum = sectnum + chapter.sections.size
         }
         chapnum.times {|c|
            xml = "#{PTK}#{self.zerosuplement(c + 1,5)}.xml"
            type = "application/x-dtbook+xml"
            build_manifest_item(type, "misc#{num}", xml)
            num = num + 1
         }

         spinenum = num
         sectnum.times {|s|
            smil = "#{PTK}#{self.zerosuplement(s + 1,5)}.smil"
            type = "application/smil"
            build_manifest_item(type, "misc#{num}", smil)
            num = num + 1
         }

         build_opf_manifest_post()

         build_opf_spine_pre()
         sectnum.times {|s|
            build_opf_spine("misc#{spinenum}")
            spinenum = spinenum + 1
         }
         build_opf_spine_post()

         build_opf_package_post()
      }
   end
end
