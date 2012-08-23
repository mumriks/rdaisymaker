#!/usr/bin/env ruby
# encoding: utf-8
#
# copyright (c) 2011 Kishida Atsushi
#

class Phrase
   def initialize(phrase, args = nil)
      @phrase = phrase
      @args = args
   end
   attr_accessor :phrase, :args, :readid, :totalid

   def unify_period
      kana = TEXTDaisy::KANA
      kanji = TEXTDaisy::KANJI
      zenkigou = TEXTDaisy::ZENKIGOU
      unless @phrase.nil?
         unless /\A[!-~\s]+\z/ =~ @phrase
            @phrase.gsub!(/(#{kana}|#{kanji}|#{zenkigou})(\.)/){$1 + "。"}
            @phrase.gsub!(/(#{kana}|#{kanji}|#{zenkigou})(．)/){$1 + "。"}
            @phrase.gsub!(/(#{kana}|#{kanji}|#{zenkigou})(,)/){$1 + "、"}
            @phrase.gsub!(/(#{kana}|#{kanji}|#{zenkigou})(，)/){$1 + "、"}
         end
      end
   end
   def namedowncase
      "#{self.class}".downcase
   end
end

class Headline < Phrase
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :ncxsrc, :indent

   def compile_xml(daisy)
      daisy.compile_headline(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_headline(self)
   end
   def valid_args?
      return false unless 7 > @args
      true
   end
   def adjust_ncx
      cut_ruby()
      cut_xml_tag()
      cut_front_space()
   end

   private
   def cut_ruby
      rubyreg = Regexp.new(%Q!<span class="(?:rp|rt)">[^<]+<\/span>!)
      @phrase.gsub!(rubyreg, "") if rubyreg =~ @phrase
   end
   def cut_xml_tag
      @phrase.gsub!(/<[^<]+>/, "") if /<[^<]+>/ =~ @phrase
   end
   def cut_front_space
      @phrase.gsub!(/\A[\s　]+/, "") if /\A[\s　]+/ =~ @phrase
   end
end

class Sent < Phrase
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :ncxsrc

   def compile_xml(daisy)
      daisy.compile_text(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_text(self)
   end
end

class Caption < Phrase
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :ncxsrc, :ref

   def compile_xml(daisy)
      daisy.compile_caption(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_text(self)
   end
end

class Paragraph < Phrase
   def initialize(phrase, args = nil)
      super
   end

   def compile_xml(daisy)
      daisy.compile_paragraph()
   end
   def compile_smil(daisy)
   end
end

class PhraseTag < Phrase
   def initialize(phrase, args = nil)
      super
      if args.instance_of?(Array)
         split_args if args.size == 2
         set_args if args.size == 1
      end
   end
   attr_accessor :caption

   private

   def split_args
      @caption = args[1]
      @args = args[0]
   end
   def set_args
      @args = args[0]
   end
end

class Image < PhraseTag
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :width, :height, :ref

   def compile_xml(daisy)
      daisy.compile_image(self)
   end
   def compile_smil(daisy)
#      daisy.compile_smil_image(self)
   end
end

class Table < PhraseTag
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :row, :colmn, :num, :tag

   def set_table(num, row, column, tag)
      @num = num
      @row = row
      @column = column
      @tag = tag
   end
   def get_table
      return @num, @row, @column
   end
   def compile_xml(daisy)
      daisy.compile_table(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_table(self)
   end
end

class Page < Phrase
   def initialize(phrase, args = nil)
      super
      page_kata!()
   end
   attr_accessor :ncxsrc

   def page_kata!
      @phrase.sub!(/ぺーじ/, "ページ")
   end
   def page_hira!
      @phrase.sub!(/ページ/, "ぺーじ")
   end
   def cut_kana!
      @phrase.sub!(/ぺーじ|ページ/, "")
   end
   def cut_kana
      @phrase.sub(/ぺーじ|ページ/, "")
   end
   def compile_xml(daisy)
      daisy.compile_pagenum(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Normal < Page
   def initialize(phrase, args = nil)
      super
   end
end

class Front < Page
   def initialize(phrase, args = nil)
      super
      @phrase.sub!(/\A[fF]:/, '')
   end
end

class Special < Page
   def initialize(phrase, args = nil)
      super
      @phrase.sub!(/\A[sS]:/, '')
   end
end

class NoteGroup < PhraseTag
end

class Note < NoteGroup
   def initialize(phrase, args = nil)
      super
      valid_caption?
   end
   attr_accessor :child, :ncxsrc, :sectnum, :noteref

   def cut_brace
      @noteref.gsub!(/[()]/, "")
   end

   def valid_caption?
      unless @caption.nil?
         STDERR.puts "キャプションには対応していません //footnote[#{@args}]"
         exit 1
      end
   end
   def compile_xml(daisy)
      daisy.compile_note(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Notes < Note
   def initialize(phrase, args = nil)
      super
      @notes = []
   end
   attr_accessor :notes
end

class Noteref < Phrase
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :child, :ncxsrc, :sectnum, :noteref

   def compile_xml(daisy)
      daisy.compile_noteref(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Annotation < NoteGroup
   def initialize(phrase, args = nil)
      super
      valid_caption?
   end
   attr_accessor :child, :ncxsrc, :sectnum, :annoref

   def valid_caption?
      unless @caption.nil?
         STDERR.puts "キャプションには対応していません //annotation[#{@args}]"
         exit 1
      end
   end
   def compile_xml(daisy)
      daisy.compile_note(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Annotations < Annotation
   def initialize(phrase, args = nil)
      super
#      @annotations = []
      @notes = []
   end
   attr_accessor :notes #:annotations
end

class Annoref < Phrase
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :child, :ncxsrc, :sectnum, :annoref

   def compile_xml(daisy)
      daisy.compile_noteref(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Prodnote < NoteGroup
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :render, :ncxsrc, :group, :ref, :sectnum

   def valid_render?
      case @args
      when /\Ar/
         @render = 'required'
      when /\Ao/
         @render = 'optional'
      when nil
         @render = 'optional'
      else
         return false
      end
   end
   def compile_xml(daisy)
      daisy.compile_prodnote(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Sidebar < NoteGroup
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :render, :ncxsrc

   def valid_render?
      case @args
      when /\Ar/
         @render = 'required'
      when /\Ao/
         @render = 'optional'
      else
         return false
      end
   end
   def compile_xml(daisy)
      daisy.compile_sidebar(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Linenum < PhraseTag
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :ncxsrc

   def compile_xml(daisy)
   end
   def compile_smil(daisy)
   end
end

class Quote < PhraseTag
   def initialize
      @lines = []
   end
   def add_lines(phrase)
      p = Sent.new(phrase)
      @lines << p
   end
   attr_accessor :lines, :border
   attr_accessor :ncxsrc

   def compile_xml(daisy)
      daisy.compile_quote(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_text(self)
   end
end

class ImageGroup < Phrase
   def initialize(args)
      @args = args
      @start = false
   end
   attr_accessor :args

   def start
      @start = true
   end
   def finish
      @start = false
   end
   def start?
      @start
   end
   def compile_xml(daisy)
      daisy.compile_imagegroup(self)
   end
   def compile_smil(daisy)
   end
end

class Indent < Phrase
   def initialize(args)
      @args = args
      valid_args?()
   end
   def compile_xml(daisy)
      daisy.compile_indent(@args)
   end
   def compile_smil(daisy)
   end

   private

   def valid_args?
      unless "end" == @args
         unless /x[1-9]?|-?[1-9]/ =~ @args
            mes = "インデント指定できるのは、1 から 9 の数字ひともじ、
もしくは、頭に x をつけて 1 から 9 までの数字ひともじです。"
            STDERR.puts mes
            exit 1
         end
      end
   end
end

class List < PhraseTag
   def initialize(phrase)
      super
   end
   attr_accessor :ncxsrc, :type, :enum, :dl

   def set_type(dltag, type, enum)
      @type = type
      @enum = enum
      @dl = dltag
   end
   def cut_headmark
      if 'ul' == @type
         reg = Regexp.new("^[*・]\s+")
      elsif '1' == @enum
         reg = Regexp.new("^[0-9]+\.?\s+")
      elsif 'a' == @enum
         reg = Regexp.new("^[a-z]+\.?\s+")
      elsif 'A' == @enum
         reg = Regexp.new("^[A-Z]+\.?\s+")
      elsif 'i' == @enum
         reg = Regexp.new("^[ivxｉｖｘⅰ-ⅻ]+\.?\s+")
      elsif 'I' == @enum
         reg = Regexp.new("^[IVXＩＶＸⅠ-Ⅻ]+\.?\s+")
      elsif /dt/ =~ @dl
         reg = Regexp.new("^:\s+")
      end
      @phrase.sub!(reg, "") if reg
   end
   def compile_xml(daisy)
      daisy.compile_list(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_text(self)
   end
end
