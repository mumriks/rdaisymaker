#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright (c) 2011, 2012 Kishida Atsushi
#

require 'uuid'
require 'image_size'

class Daisy
   def initialize(values)
      @meta = Meta.new(values)
      @xmeta = Xmeta.new(values)
      @skippable = Skippable.new
      @book = []
      @img_list = []
   end
   attr_reader :meta, :xmeta, :book, :skippable
   attr_accessor :bookname, :temp, :img_list

   def add_chapter(chapter)
      @book << chapter
   end
   def build_daisy
   end
   def build_ncx
   end
   def build_opf
   end

   IMGWIDTH = 550
   IMGHEIGHT = 400

   def get_image_size(image)
      i_size = []
      File.open(image, "rb"){|img|
         i_size = ImageSize.new(img.read).get_size
      }
      return i_size[0], i_size[1]
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
      @title = values["title"].nil? ? "名のない本" : values["title"]
      @publisher = values["publisher"].nil? ? "デイジー" : values["publisher"]
      @date = values["date"].nil? ? "#{Date.today}" : values["date"]
      @isbn = values["isbn"].nil? ? "No ISBN" : values["isbn"]
      @author = values["author"].nil? ? "名のない著者" : values["author"]
      @translator = values["trl"].nil? ? nil : values["trl"]
      @editor = values["edt"].nil? ? nil : values["edt"]
      @illustlator = values["ill"].nil? ? nil :values["ill"]
      @photographer = values["pht"].nil? ? nil :values["pht"]
      @language = values["language"].nil? ? "ja" : values["language"]
      @pageDirection = values["pagedirection"].nil? ? "ltr" : values["pagedirection"]
      @iUid = UUID.create
      check()
   end
   attr_reader :title, :publisher, :date, :language, :iUid, :isbn, :author, :translator, :editor, :illustlator, :photographer
   attr_accessor :format, :pageDirection

   def check
      page_direction?()
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
