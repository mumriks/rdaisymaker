# encoding: utf-8
# Copyright (c) 2011 Kishida Atsushi
#

class TEXTDaisy < Daisy3
   def initialize(values)
      super
      @xmeta.multimediaType = "textNCX"
      @xmeta.multimediaContent = "text"
      @xmeta.totalElapsedTime = @xmeta.totalTime = "0:00:00.000"
      @meta.format = "ANSI/NISO Z39.86-2005"
      @sesame = false
   end
end

class AudioFullTextDaisy3 < Daisy3
   def initialize(values = nil)
      super
      @xmeta.multimediaType = "audioFullText"
      @xmeta.multimediaContent = "audio,text"
      @meta.format = "ANSI/NISO Z39.86-2005"
      @sesame = false
      @audio_list = []
   end
   attr_accessor :audio_list

   def copy_audio_file(file, dstname)
      unless File.exist?(@a_path)
         Dir.mkdir(@a_path)
      end
      FileUtils.cp(file, "#{@a_path}/#{dstname}")
      @audio_list << "Audios/#{dstname}"
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

class TEXT < TEXTDaisy
end

class Daisy3
   attr_accessor :sesame, :yomi, :i_path, :a_path
   def build_cover(file)
      return
   end

   def build_daisy
      build_xml_smil()
      build_text_ncx()
      build_text_opf()
   end

   def mk_temp(temp)
      @temp = temp
      FileUtils.mkdir_p("#{@temp}/#{@bookname}")
      @i_path = "#{@temp}/#{@bookname}/Images"
      @a_path = "#{@temp}/#{@bookname}/Audios"
   end

   def copy_files
      FileUtils.cp_r("#{@temp}/#{@bookname}/", "./") unless "." == @temp
      dtdfile = %w(dtbook-2005-3.dtd dtbsmil-2005-2.dtd ncx-2005-1.dtd oeb12.ent oebpkg12.dtd resource-2005-1.dtd)
      dtdfile.each {|f|
         distpath = "#{@bookname}/#{f}"
         FileUtils.cp(File.join(BINDIR, "../doc/#{f}"), distpath)
      }
      if @sesame
         fnames = {".css" => "common2.css", ".res" => "common.res",
                   ".xsl" => "common2.xsl"}
         FileUtils.cp(File.join(BINDIR, "../doc/boten2.png"), "#{@bookname}/boten2.png")
      else
         fnames = {".css" => "common.css", ".res" => "common.res",
                   ".xsl" => "common.xsl"}
      end
      [".css", ".res", ".xsl"].each {|ext|
        distpath = "#{@bookname}/#{@bookname}#{ext}"
        FileUtils.cp(File.join(BINDIR, "../doc/#{fnames[ext]}"), distpath)
      }
   end

   def build_xml_smil
      @chapcount = 0
      @sectcount = 0
      index = 0
      customTest = false
      self.book.each {|chapter|
         @@start_level, @@befour_level, @@level = nil, nil, nil
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
                        phr.compile_smil(self)
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
               if h.arg >= @headlines[i + 1].arg
                  s = h.arg
                  e = @headlines[i + 1].arg
                  s.downto(e) {|l|
                     build_ncx_navmap_navpoint_post(l)
                  }
               end
            else
               build_ncx_navmap_navpoint_post(h.arg)
            end
            @harg = h.arg
         }
         build_ncx_navmap_navpoint_downto_post(@harg)
         build_ncx_navmap_post()
         unless 0 == @pages.size
            build_ncx_pagelist_pre()
            ['front', 'normal', 'special'].each {|t|
               @pages.each {|pg|
                  build_ncx_pagelist(pg) if t == pg.namedowncase
               }
            }
            build_ncx_pagelist_post()
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
         @img_list.uniq!
         if 0 < @img_list.size
            @img_list.each {|img|
               type = check_file_type(img)
               build_manifest_item(type, "misc#{num}", "#{img}")
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
