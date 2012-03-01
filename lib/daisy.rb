#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright (c) 2011 Kishida Atsushi
#

require 'date'

class Daisy
   def initialize(values)
      @meta = Meta.new(values)
      @xmeta = Xmeta.new(values)
      @skippable = Skippable.new
      @book = []
      @img_list = []
   end
   attr_reader :meta, :xmeta, :book, :skippable
   attr_accessor :img_list, :bookname

   def add_chapter(chapter)
      @book << chapter
   end
   def build_daisy
   end
   def build_ncx
   end
   def build_opf
   end
end

class TEXTDaisy < Daisy
   def initialize(values)
      super
      @xmeta.multimediaType = "textNCX"
      @xmeta.multimediaContent = "text"
      @xmeta.totalElapsedTime = "0:00:00.000"
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
   def copy_files
      dtdfile = %w(dtbook-2005-3.dtd dtbsmil-2005-2.dtd ncx-2005-1.dtd oeb12.ent oebpkg12.dtd resource-2005-1.dtd)
      dtdfile.each {|f|
         distpath = "#{@bookname}/#{f}"
         FileUtils.cp(File.join(BINDIR, "../doc/#{f}"), distpath)
      }
      [".css", ".res", ".xsl"].each {|ext|
        distpath = "#{@bookname}/#{@bookname}#{ext}"
        FileUtils.cp(File.join(BINDIR, "../doc/common#{ext}"), distpath)
      }
      Dir.mkdir("#{@bookname}/image")
      @img_list.each {|i|
         FileUtils.cp("#{i}", "#{@bookname}/image/#{i}")
      }
   end

   private

   def build_xml_smil
      @chapcount = 0
      @sectcount = 0
      self.book.each {|chapter|
         @level = 1
         @chapcount += 1
         @tnum = 0
         xmlfile = "#{self.bookname}/#{PTK}#{self.zerosuplement(@chapcount, 5)}.xml"
         @xm = File.open(xmlfile, "w")
         xml_header(@xm)
         chapter.sections.each {|section|
            @sectcount += 1
            smilfile = "#{self.bookname}/#{PTK}#{self.zerosuplement(@sectcount, 5)}.smil"
            sm = File.open(smilfile, "w")
            section.phrases.each {|phr|
               unless phr.instance_of?(ImageGroup)
                  phr.phrase = compile_daisy_ruby(phr.phrase)
                  phr.phrase = compile_inline_tag(phr.phrase)
               end
               phr.unify_period
               phr.compile_xml(self, @xm, @sectcount)
            }
            smil_header(sm)
            readphr = []
            section.phrases.each {|phr|
               unless phr.readid == nil
                  readphr << phr
               end
            }
            readphr.sort_by{|p| p.readid}.each {|phr|
               phr.compile_smil(self, sm, @xm)
            }
            smil_footer(sm)
         }
         xml_footer(@xm)
      }
   end
   def build_text_ncx
      collect_ncx_data()
      ncxfile = "#{@bookname}/#{@bookname}.ncx"
      nf = File.open(ncxfile, "w")
      build_ncx_header(nf)
      build_ncx_meta(nf, @depth, @totalPage, @maxPage)
      build_ncx_navmap_pre(nf)
      @headlines.each_with_index {|h, i|
         h.adjust_ncx
         build_ncx_navmap(nf, h)
         unless @headlines[i + 1] == nil
            if h.args >= @headlines[i + 1].args
               s = h.args
               e = @headlines[i + 1].args
               s.downto(e) {|l|
                  build_ncx_navmap_navpoint_post(nf, l)
               }
            end
         else
            build_ncx_navmap_navpoint_post(nf, h.args)
         end
      }
      build_ncx_navmap_post(nf)
      build_ncx_pagelist_pre(nf)
      @pages.each {|n|
         if /normal|front|special/ =~ n.namedowncase
            self.build_ncx_pagelist(nf, n)
         end
      }
      self.build_ncx_pagelist_post(nf)
      @ncxnotetype.each {|t|
         num = 1
         build_ncx_navlist_pre(nf, t)
         @ncxnote.each {|n|
            if t == n.namedowncase
#               build_ncx_navlist(nf, n)
               build_ncx_navlist(nf, n, num)
               num += 1
            end
         }
         build_ncx_navlist_post(nf)
      }
      build_ncx_post(nf)
   end
   def build_text_opf
      opffile = "#{@bookname}/#{@bookname}.opf"
      of = File.open(opffile, "w")
      build_opf_meta(of)
      build_opf_manifest_pre(of)
      build_opf_etc_manifest(of)
      num = 3
      if 0 < self.img_list.size
         self.img_list.each {|img|
            build_opf_img_manifest(of, num, img)
            num = num + 1
         }
      end

      sectnum = 0
      chapnum = self.book.size
      self.book.each {|chapter|
         sectnum = sectnum + chapter.sections.size
      }
      chapnum.times {|c|
         xml = "#{PTK}#{self.zerosuplement(c + 1,5)}.xml"
         type = "application/x-dtbook+xml"
         build_opf_xml_smil_manifest(of, num, xml, type)
         num = num + 1
      }

      spinenum = num
      sectnum.times {|s|
         smil = "#{PTK}#{self.zerosuplement(s + 1,5)}.smil"
         type = "application/smil"
         build_opf_xml_smil_manifest(of, num, smil, type)
         num = num + 1
      }

      build_opf_manifest_post(of)

      build_opf_spine_pre(of)
      sectnum.times {|s|
         build_opf_spine(of, spinenum)
         spinenum = spinenum + 1
      }
      build_opf_spine_post(of)

      build_opf_package_post(of)
   end
end

class Meta
   def initialize(values)
      @title = values["title"].nil? ? "名のない本" : values["title"]
      @publisher = values["publisher"].nil? ? "デイジー" : values["publisher"]
      @date = values["date"].nil? ? "#{Date.today}" : values["date"]
      @isbn = values["isbn"].nil? ? "No ISBN" : values["isbn"]
      @author = values["author"].nil? ? "名のない著者" : values["author"]
      @translator = values["trl"].nil? ? nil : values["trl"]
      @editor = values["edt"].nil? ? nil : values["edt"]
      @illustlator = values["ill"].nil? ? nil :values["ill"]
      @photographer = values["pht"].nil? ? nil :values["pht"]
      @format = "ANSI/NISO Z39.86-2005"
      @language = "ja"
      todaytime = DateTime.now.to_s
      @iUid = todaytime.gsub(/\D/, '')[0..13]
   end
   attr_reader :title, :publisher, :date, :format, :language, :iUid, :isbn, :author, :translator, :editor, :illustlator, :photographer
end

class Xmeta
   def initialize(values)
      @sourceDate = values["sourceDate"].nil? ? "" : values["sourceDate"]
      @sourcePublisher = values["sourcePublisher"].nil? ? "" : values["sourcePublisher"]
      @multimediaType = ""
      @multimediaContent = ""
      @totalElapsedTime = ""
   end
   attr_reader :sourceDate, :sourcePublisher
   attr_accessor :multimediaType, :multimediaContent, :totalElapsedTime
end

class Skippable
   def initialize
      @normal = "true"
      @front = "true"
      @special = "true"
      @note = "true"
      @noteref = "true"
      @annotation = "true"
#      @annoref = "true"
      @linenum = "true"
      @sidebar = "true"
      @prodnote = "true"
   end
   attr_accessor :normal, :front, :special, :note, :noteref, :annotation, :linenum, :sidebar, :prodnote #, :annoref
end

class Chapter
   def initialize
      @sections = []
   end
   attr_reader :sections

   def add_section(section)
      @sections << section
   end
end

class Section
   def initialize
      @phrases = []
   end
   attr_reader :phrases

   def add_phrase(phrase)
      @phrases << phrase
   end
end

class Skip
   def initialize(file, lineno, obj)
      @file = File.basename(file)
      @lineno = lineno
      @obj = obj
   end
   attr_reader :file, :lineno, :obj
end
