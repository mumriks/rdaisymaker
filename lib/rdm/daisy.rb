#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright (c) 2011, 2012 Kishida Atsushi
#

require 'uuid'
require 'image_size'
require 'rdm/strict_exist'

class Daisy
   def initialize(values)
      @meta = Meta.new(values)
      @xmeta = Xmeta.new(values)
      @skippable = Skippable.new
      @book = []
      @img_list = []
   end
   attr_reader :meta, :xmeta, :book, :skippable
   attr_accessor :bookname, :temp, :img_list, :yomi, :hivColophon

   def add_chapter(chapter)
      @book << chapter
   end

   FT_IMAGE = /\.(?:jpe*g|png|svg)/
   FT_AUDIO = /\.(?:mp[34]|wav)/
   IMGWIDTH = 550
   IMGHEIGHT = 400
   ERRMES = {"errmes1" => "画像ファイルが指定されていません ",
             "errmes2" => "ファイルが見つかりません : ",
             "errmes3" => "サポートされていない画像タイプです : ",
             "errmes5" => "サポートされていない audio タイプです : "}
   LABEL_NOTE = '注釈'
   LABEL_PROD = '製作者注'
   LABEL_ANNO = 'アノテーション'
   LABEL_SIDE = 'サイドバー'

   def get_image_size(image)
      i_size = []
      File.open(image, "rb"){|img|
         i_size = ImageSize.new(img.read).get_size
      }
      return i_size[0], i_size[1]
   end

   def copy_image(image, dstname)
      FileUtils.mkdir_p(@i_path) unless File.exist?(@i_path)
      FileUtils.cp(image, "#{@i_path}/#{dstname}")
   end

   def check_strict_exist?(file)
      unless File.strict_exist?(file)
         disk_name = File.strict_exist_name?(file)
         return 'errmes2', file unless disk_name
         puts "'#{file}' の実際のファイル名は '#{disk_name}' です。"
         return nil, disk_name
      else
         return nil, file
      end
   end

   def check_imagefile(file)
      mes, disk_name = check_strict_exist?(file)
      return mes, disk_name unless mes.nil?
      extname = File.extname(disk_name)
      basename = File.basename(disk_name, ".*")
      return 'errmes3', file unless Daisy::FT_IMAGE =~ extname.downcase
      ext, extname = extname_unmatch?(extname)
      base, basename = basename_unmatch?(basename, extname)
      if ext or base
         puts "'#{disk_name}' のファイル名を '#{basename}#{extname}' に変更しました。"
      end
      copy_image(file, "#{basename}#{extname}")
      width, height = get_image_size(file)
      imgSize = big_image?(width, height)
      imgSizeSwitch = big_image_switch?(width, height)
      return 'errmes4', "#{basename}#{extname}" if imgSize and imgSizeSwitch
      return nil, "#{basename}#{extname}"
   end

   def check_meta
      er = 0
      if @meta.title.nil? or "" == @meta.title
         puts "meta:title が設定されていません。"
         er -= 1
      end
      if @meta.publisher.nil? or "" == @meta.publisher
         puts "meta:publisher が設定されていません。"
         er -= 1
      end
      if @meta.author.nil? or "" == @meta.author
         puts "meta:author が設定されていません。"
         er -= 1
      end
      if @xmeta.sourceDate.nil? or "" == @xmeta.sourceDate
         puts "xmeta:sourceDate が設定されていません。"
      end
      if @xmeta.sourcePublisher.nil? or "" == @xmeta.sourcePublisher
         puts "xmeta:sourcePublisher が設定されていません。"
      end
      raise "図書の作成を中止します" if 0 > er
   end

   private

   def big_image?(width, height)
      return true if IMGWIDTH < width and IMGHEIGHT < height
      return false
   end

   def big_image_switch?(width, height)
      return true if IMGWIDTH < height and IMGHEIGHT < width
      return false
   end

   def extname_unmatch?(extname)
      unless Daisy::FT_IMAGE =~ extname
         unless Daisy::FT_AUDIO =~ extname
            return true, extname.downcase
         end
      end
      extname = '.jpg' if '.jpeg' == extname
      return false, extname
   end

   def basename_unmatch?(basename, extname)
      if /[^A-Za-z0-9._-]+/ =~ basename
         bn = basename.gsub(/[^A-Za-z0-9._-]+/, '')
         bn = bn + 'aa' if File.exist?("#{bn}#{extname}")
         while File.exist?("#{bn}#{extname}")
            bn = bn.succ
         end
         return true, bn
      end
      return false, basename
   end
end

class Daisy3 < Daisy
   require 'rdm/daisy3'
   require 'rdm/daisy3compiler'
end

class Daisy4 < Daisy
   require 'rdm/daisy4'
   require 'rdm/daisy4compiler'
   require 'zip/zipfilesystem'
end

class Meta
   def initialize(values)
      @title = values["title"].nil? ? nil : values["title"]
      @publisher = values["publisher"].nil? ? nil : values["publisher"]
      @date = values["date"].nil? ? "#{Date.today}" : values["date"]
      @isbn = values["isbn"].nil? ? "No ISBN" : values["isbn"]
      @author = values["author"].nil? ? nil : values["author"]
      @translator = values["trl"].nil? ? nil : values["trl"]
      @editor = values["edt"].nil? ? nil : values["edt"]
      @illustlator = values["ill"].nil? ? nil :values["ill"]
      @photographer = values["pht"].nil? ? nil :values["pht"]
      @language = values["language"].nil? ? "ja" : values["language"]
      @pageDirection = values["pagedirection"].nil? ? "ltr" : values["pagedirection"]
      @iUid = UUID.create
      check()
   end
   attr_accessor :title, :publisher, :date, :language, :iUid, :isbn, :author,
                 :translator, :editor, :illustlator, :photographer, :format,
                 :pageDirection, :refmark
   attr_accessor :rights, :type, :subject, :coverage, :relation,
                 :description

   private

   def check
      page_direction?()
      ref_mark()
   end

   def page_direction?
      if "ja" == @language
         unless /rtl|ltr/ =~ @pageDirection
            page_direction_set()
         end
      elsif /en/ =~ @language
         unless "ltr" == @pageDirection
            page_direction_set()
         end
      end
   end
   def page_direction_set
      @pageDirection = "ltr"
      puts "ページ送り方向を「左から右（ltr）」に設定します。"
   end
   def ref_mark
      @refmark = "注" if "ja" == @language
      @refmark = "" if /en/ =~ @language
   end
end

class Xmeta
   def initialize(values)
      @sourceDate = values["sourceDate"].nil? ? nil : values["sourceDate"]
      @sourcePublisher = values["sourcePublisher"].nil? ? nil : values["sourcePublisher"]
      @sourceEdition = values["sourceEdition"].nil? ? nil : values["sourceEdition"]
      @sourceRights = values["sourceRights"].nil? ? nil : values["sourceRights"]
      @sourceTitle = values["sourceTitle"].nil? ? nil : values["sourceTitle"]
      @narrator = values["narrator"].nil? ? nil : values["narrator"]
      @producer = values["producer"].nil? ? nil : values["producer"]
      @producedDate = values["producedDate"].nil? ? nil : values["producedDate"]
      @revision = values["revision"].nil? ? nil : values["revision"]
      @revisionDate = values["revisionDate"].nil? ? nil : values["revisionDate"]
      @revisionDescription = values["revisionDescription"].nil? ? nil : values["revisionDescription"]
      @audioFormat = values["audioFormat"].nil? ? nil : values["audioFormat"]
      @multimediaType = ""
      @multimediaContent = ""
      @totalElapsedTime = ""
   end
   attr_accessor :sourceDate, :sourcePublisher, :sourceEdition,
                 :sourceRights, :sourceTitle, :producer, :producedDate,
                 :narrator, :revision, :revisionDate, :revisionDescription,
                 :multimediaType, :multimediaContent, :totalElapsedTime,
                 :totalTime, :audioFormat
end

class Skippable
   def initialize
      @normal = "true"
      @front = "true"
      @special = "true"
      @note = "true"
      @noteref = "true"
      @annotation = "true"
      @annoref = "true"
      @linenum = "true"
      @sidebar = "true"
      @prodnote = "true"
   end
   attr_accessor :normal, :front, :special, :note, :noteref, :annotation, :linenum, :sidebar, :prodnote , :annoref
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
