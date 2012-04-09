#!/usr/bin/env ruby
# encoding: utf-8
#
# copyright (c) 2011 Kishida Atsushi
#

class Phrase
   def initialize(phrase, args = nil)
      @phrase = phrase
      @args = args
      @yomi = ""
      split_yomi($1) if %r!//{([^{]+)}! =~ @phrase
   end
   attr_accessor :phrase, :args, :readid, :totalid, :yomi

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
   def split_yomi(str)
      @yomi = str
      @phrase = @phrase.sub(%r!//{[^{]+}!, "")
   end
end

class Headline < Phrase
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :ncxsrc

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
#   IMGWIDTH = 550
#   IMGHEIGHT = 400

   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :width, :height, :ref

#   def valid_image?
#      return 'errmes1' if @phrase.nil?
##      Dir.mkdir("image") unless File.exist?("image")
#      check_imagefile()
#   end
   def compile_xml(daisy)
      daisy.compile_image(self)
   end
   def compile_smil(daisy)
#      daisy.compile_smil_image(self)
   end

   private
=begin
   def check_imagefile
      return 'errmes2' unless File.exist?(@phrase)
      extname = File.extname(@phrase)
      basename = File.basename(@phrase, ".*")
      return 'errmes3' unless /\.jpe*g|\.png/ =~ extname
      extname = '.jpg' if '.jpeg' == extname
      if /[^A-Za-z0-9]+/ =~ basename
         bn = basename.gsub(/[^A-Za-z0-9]+/, '')
         bn = bn + 'aa' if File.exist?("#{bn}#{extname}")
         while File.exist?("#{bn}#{extname}")
            bn = bn.succ
         end
         basename = bn
         puts "'#{@phrase}' のファイル名を '#{basename}#{extname}' に変更しました。"
      end
      FileUtils.cp(@phrase, "image/#{basename}#{extname}")
      @phrase = "#{basename}#{extname}"
      check_imagesize()
   end
   def check_imagesize
      @width, @height = get_image_size()
      return 'errmes4' unless IMGWIDTH >= @width or IMGHEIGHT >= @height
   end
   def get_image_size
      i_size = []
      File.open("image/#{@phrase}", "rb"){|img|
         i_size = ImageSize.new(img.read).get_size
      }
      return i_size[0], i_size[1]
   end
=end
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

class Note < NoteGroup #PhraseTag
   def initialize(phrase, args = nil)
      super
      valid_caption?
   end
   attr_accessor :child, :ncxsrc

   def valid_caption?
      unless @caption.nil?
#         STDERR.puts "Caption is not required. //footnote[#{@args}]"
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
   attr_accessor :child, :ncxsrc

   def compile_xml(daisy)
      daisy.compile_noteref(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Annotation < NoteGroup #PhraseTag
   def initialize(phrase, args = nil)
      super
      valid_caption?
   end
   attr_accessor :child, :ncxsrc

   def valid_caption?
      unless @caption.nil?
#         STDERR.puts "Caption is not required. //annotation[#{@args}]"
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
   attr_accessor :child, :ncxsrc

   def compile_xml(daisy)
      daisy.compile_noteref(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_customtest(self)
   end
end

class Prodnote < NoteGroup #PhraseTag
   def initialize(phrase, args = nil)
      super
   end
   attr_accessor :render, :ncxsrc, :group, :ref

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

class Sidebar < NoteGroup #PhraseTag
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
   attr_accessor :lines #, :totalid, :readid
#   def initialize(phrase, args = nil)
#      super
#   end
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
