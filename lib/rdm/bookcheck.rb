# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#
require 'rexml/document'

class BookCheck
end
class BookCheck::Daisy2
   VER = '0.1.0'
   def initialize(daisy)
      @daisy = daisy
      get_master_smil_data()
      @entries = Entries.new
      @srcNames = SrcNames.new(daisy)
      @errors = BookCheck::Error::Daisy2.new
      get_ncc()
      check()
   end
   attr_reader :entries, :srcNames, :errors

   def get_master_smil_data
      master = REXML::Document.new(File.open("master.smil"))
      @daisy.get_smil_data(master.elements["/smil/body"])
   end

   def get_ncc
      ncc = REXML::Document.new(File.open("ncc.html"))
      @daisy.get_ncc_data(ncc.root)
   end

   def check
      check_ncc()
      check_files_exist()
      print_other_files()
      @errors.print
   end

   def check_ncc
      daisy2_format?()
      equal_toc?()
      valid_pages?()
      equal_ncc_files?()
   end

   def daisy2_format?
      @errors.set_format unless "Daisy 2.02" == @daisy.format.capitalize
   end

   def equal_toc?
      @errors.set_toc unless @daisy.toc_items.to_i == @daisy.ncc.size
   end

   def valid_pages?
      pages = collect_pages()
      equal_front?(pages)
      equal_normal?(pages)
      equal_special?(pages)
   end

   def collect_pages
      @daisy.ncc.find_all{|n| n.instance_of?(Ncc::Page) }
   end

   def equal_front?(pages)
      front = pages.find_all{|p| "page-front" == p.tagClass.downcase }
      @errors.set_page("front") unless front.size == @daisy.pageFront.to_i
   end

   def equal_normal?(pages)
      normal = pages.find_all{|p| "page-normal" == p.tagClass.downcase }
      @errors.set_page("normal") unless normal.size == @daisy.pageNormal.to_i
   end

   def equal_special?(pages)
      special = pages.find_all{|p| "page-special" == p.tagClass.downcase }
      @errors.set_page("special") unless special.size == @daisy.pageSpecial.to_i
   end

   def equal_ncc_files?
      subDirsFiles = within_sub_dirs?
      currentFiles = @entries.currentSize
      result_full = (currentFiles + subDirsFiles) <=> @daisy.files.to_i
      result_current = currentFiles <=> @daisy.files.to_i
      if 0 > result_full
         @errors.set_ncc_files(1, @daisy.files, currentFiles, subDirsFiles)
      elsif 0 < result_full
         if 0 > result_current
            @errors.set_ncc_files(2, @daisy.files, currentFiles, subDirsFiles)
         elsif 0 < result_current
            @errors.set_ncc_files(3, @daisy.files, currentFiles, subDirsFiles)
         elsif 0 == result_current
            @errors.set_ncc_files(4, @daisy.files, currentFiles, subDirsFiles)
         end
      end
   end

   def within_sub_dirs?
      sub_dir = 0
      sub_dir += @entries.subDirImage.size unless @entries.subDirImage.nil?
      sub_dir += @entries.subDirAudio.size unless @entries.subDirAudio.nil?
      sub_dir += @entries.subDirOther.size unless @entries.subDirOther.nil?
      return sub_dir
   end

   def check_files_exist
      cHtmls, cSmils, cCsss = set_current_files()
      cAudio = set_current_audio()
      cImage = set_current_image()
      [[@srcNames.srcHtmls + ["ncc.html"], cHtmls],
       [@srcNames.srcSmils + ["master.smil"], cSmils],
       [@srcNames.srcCsss, cCsss],
       [@srcNames.srcAudios, cAudio],
       [@srcNames.srcImages, cImage]].each {|src, current|
         exist_file?(src, current)
      }
   end

   def set_current_files
      unless @entries.subDirOther.nil?
         htmls = @entries.currentHtmls + @entries.subDirOther
         smils = @entries.currentSmils + @entries.subDirOther
         csss = @entries.currentCsss + @entries.subDirOther
         return htmls, smils, csss
      end
      return @entries.currentHtmls, @entries.currentSmils,
             @entries.currentCsss
   end

   def set_current_audio
      unless @entries.subDirAudio.nil?
         return @entries.currentAudios + @entries.subDirAudio
      end
      return @entries.currentAudios
   end

   def set_current_image
      unless @entries.subDirImage.nil?
         return @entries.currentImages + @entries.subDirImage
      end
      return @entries.currentImages
   end

   def exist_file?(src, current)
      src.each {|s|
         unless current.find {|c| 0 == ( s <=> c ) }
            unless File.strict_exist?(s)
               if File.strict_exist_name?(s)
                  @errors.set_exist(1, [s, File.strict_exist_name?(s)])
               else
                  @errors.set_exist(-1, s)
               end
            end
         end
      }
      current.each {|c|
         unless src.find{|s| File.fnmatch(c, s, File::FNM_CASEFOLD)}
            @errors.set_exist(0, c)
         end
      }
   end

   def print_other_files
      unless @entries.currentOthers.empty?
         puts "　次のファイルは図書とは直接関連がありません"
         @entries.currentOthers.each {|o| puts "　　#{o}" }
      end
   end

   def self.version
      puts "BookCheck::Daisy2 ver.#{VER}"
   end
end

class Entries
   def initialize
      collect_entries()
   end
   attr_reader :currentHtmls, :currentSmils, :currentCsss,
               :currentAudios, :currentImages, :currentOthers,
               :subDirImage, :subDirAudio, :subDirOther

   def currentSize
      @currentHtmls.size + @currentSmils.size + @currentCsss.size + @currentAudios.size + @currentImages.size
   end

   def subDirSize
      @subDirImage.size + @subDirAudio.size + @subDirOther.size
   end

   def collect_entries
      @@currentDir = Dir.pwd
      collect_sub_dirs_files()
      collect_current_files()
   end

   def collect_sub_dirs_files
      @@sub_dirs = Dir.entries(@@currentDir).find_all{|f|
                                 File.directory?(f) and /\A\.\.?\z/ !~ f }
      check_sub_dirs_files()
   end

   def check_sub_dirs_files
      @@sub_dirs.each {|sd|
         sd_files = Dir.entries(sd).find_all{|f| File.file?("#{sd}/#{f}")}
         type = set_sub_dirs_files(sd_files)
         case type
         when 'audio'
            @subDirAudio = add_sub_dir_name(sd_files, sd)
         when 'image'
            @subDirImage = add_sub_dir_name(sd_files, sd)
         when 'other'
            @subDirOther = add_sub_dir_name(sd_files, sd)
         end
      }
   end

   def add_sub_dir_name(sd_files, sd)
      sd_files.collect! {|f| f = "#{sd}/#{f}"}
   end

   def set_sub_dirs_files(sd_files)
      audio, image, other = 0, 0, 0
      sd_files.each {|f|
         case File.extname(f).downcase
         when Daisy::FT_AUDIO
            audio += 1
         when Daisy::FT_IMAGE
            image += 1
         else
            other += 1
         end
      }
      type = {"#{audio}" => 'audio', "#{image}" => 'image',
              "#{other}" => 'other'}
      return type["#{[audio, image, other].max}"]
   end

   def collect_current_files
      @@current_entries = Dir.entries(@@currentDir).find_all{|f|
                 File.file?(f) and '.yaml' != File.extname(f).downcase }
      @currentSmils = collect_smil_files()
      @currentHtmls = collect_html_files()
      @currentAudios = collect_audio_files()
      @currentImages = collect_image_files()
      @currentCsss = collect_css_files()
      @currentOthers = @@current_entries - @currentSmils - @currentHtmls - @currentAudios - @currentImages - @currentCsss
   end

   def collect_smil_files
      @@current_entries.find_all{|e| /\.smil/ =~ File.extname(e).downcase }
   end

   def collect_html_files
      @@current_entries.find_all{|e| /\.html/ =~ File.extname(e).downcase }
   end

   def collect_audio_files
      @@current_entries.find_all{|e|
                              Daisy::FT_AUDIO =~ File.extname(e).downcase }
   end

   def collect_image_files
      @@current_entries.find_all{|e|
                              Daisy::FT_IMAGE =~ File.extname(e).downcase }
   end

   def collect_css_files
      @@current_entries.find_all{|e| /\.css/ =~ File.extname(e).downcase }
   end
end

class SrcNames
   def initialize(daisy)
      @daisy = daisy
      @srcHtmls = []
      @srcSmils = []
      @srcAudios = []
      @srcCsss = []
      @srcImages = []
      collect_filename_in_src()
   end
   attr_reader :srcHtmls, :srcSmils, :srcAudios, :srcCsss, :srcImages

   def collect_filename_in_src
      collect_smil_files_in_src()
      collect_seqs_in_smil_files()
      collect_html_files_in_src()
      collect_audio_files_in_src()
      collect_css_and_image_files_in_src()
   end

   def collect_html_files_in_src
      @daisy.masterSmils.each {|s|
         smil = REXML::Document.new(File.open(s.src))
         get_html_files(smil.elements["/smil/body"])
      }
   end

   def get_html_files(body)
      body.each_element {|e|
         case e.name
         when 'seq', 'par'
            get_html_files(e) if e.has_elements?
         when 'text'
            @srcHtmls << $1 if /\A(.+\.html)/.match(e.attributes["src"].downcase)
         end
      }
      @srcHtmls.uniq!
   end

   def collect_audio_files_in_src
      @daisy.seqs.each {|s|
         s.item.each {|par|
            @srcAudios << par.audio.src if par.audio
         }
      }
      @srcAudios.uniq!
   end

   def collect_css_and_image_files_in_src
      htmls = @srcHtmls + ["ncc.html"]
      htmls.each {|h|
         doc = REXML::Document.new(File.open(h))
         @srcCsss << @daisy.get_css_files(doc.elements["/html/head"])
         @srcImages << @daisy.get_image_files(doc.elements["/html/body"])
      }
      @srcCsss.flatten!.uniq!
      @srcImages.flatten!.uniq!
   end

   def collect_smil_files_in_src
      @srcSmils = @daisy.masterSmils.map{|m| m.src}
   end

   def collect_seqs_in_smil_files
      @daisy.masterSmils.each {|s|
         smil = REXML::Document.new(File.open(s.src))
         @daisy.get_smil_data(smil.elements["/smil/body"])
      }
   end
end

class BookCheck::Error
end

class BookCheck::Error::Daisy2
   def initialize
      @page = {}
      @ncc_files, @exist = [], []
      @@err_level = 0
   end
   attr_reader :format, :toc, :page, :ncc_files, :exist

   def print
      format_error() if @format
      toc_error() if @toc
      page_error() unless @page.empty?
      ncc_files_error() unless @ncc_files.empty?
      file_exist_error() unless @exist.empty?
      if 4 < @@err_level
         raise "\n　処理を終了します"
      elsif 0 < @@err_level
         puts "\n　処理は継続します"
      else
         puts "\n　問題はありませんでした"
      end
      puts
   end

   def format_error
      @@err_level += 10
      puts "[エラー] Daisy 2.02 ではない図書のようです"
   end

   def toc_error
      @err_level += 1
      puts "[注意] toc アイテム数が合いません"
   end

   def page_error
      @@err_level += 1
      ['front', 'normal', 'special'].each {|type|
         if @page[type]
            puts "[注意] #{type}のページ数が合いません"
         end
      }
   end

   def ncc_files_error
      case @ncc_files[0]
      when 1
         mes = "[注意] ncc:filesの値が使用ファイル数を超えています。"
      when 2
         mes = "[注意] ncc:filesの値がカレントファイル数とも、サブフォルダファイル数を加えた数とも合いません。"
      when 3
         mes = "[注意] ncc:filesの値が使用ファイル数よりも小さいです。"
      when 4
         mes = "[注意] ncc:filesの値がサブフォルダの分を含んでいません。"
      end
      if mes
         @@err_level += 1
         puts mes
         puts "　ncc:files : #{@ncc_files[1]}　　カレント: #{@ncc_files[2]}　　サブフォルダ: #{@ncc_files[3]}"
      end
   end

   def file_exist_error
      capital_small = @exist.find_all {|num, file| 0 < num }
      not_found = @exist.find_all {|num, file| 0 > num }
      not_use = @exist.find_all {|num, file| 0 == num }
      capital_small_mismatch(capital_small) unless capital_small.empty?
      not_found_file(not_found) unless not_found.empty?
      not_use_file(not_use) unless not_use.empty?
   end

   def capital_small_mismatch(capital_small)
      @@err_level += 1
      puts "[注意] 次のファイルは実際のファイル名と厳密に同じではありません"
      capital_small.each {|num, file|
         puts "　　HTML内：#{file[0]}"
         puts "　　実際　：#{file[1]}"
         puts
      }
   end

   def not_found_file(not_found)
      @@err_level += 10
      puts "[エラー] 次のファイルが見つかりません"
      not_found.each {|num, file|
         puts "　　#{file}"
      }
   end

   def not_use_file(not_use)
      @@err_level += 1
      puts "[注意] 次のファイルは使用されていません"
      not_use.each {|num, file|
         puts "　　#{file}"
      }
   end

   def set_format
      @format = true
   end

   def set_toc
      @toc = true
   end

   def set_page(type)
      case type
      when 'front'
         @page["front"] = true
      when 'normal'
         @page["normal"] = true
      when 'special'
         @page["special"] = true
      end
   end

   def set_ncc_files(num, nccFiles, current, sub)
      @ncc_files = [num, nccFiles, current, sub]
   end

   def set_exist(num, name)
      @exist << [num, name]
   end
end
