#!/usr/bin/env ruby
# encoding: utf-8
#
# copyright (c) 2011, 2012 Kishida Atsushi
#

require 'rdm/tag'

class Phrase
   def initialize(phrase, arg = nil)
      @phrase = Phrase::exchange_entity(phrase)
      @arg = arg
   end
   attr_accessor :phrase, :arg, :readid, :totalid

   def unify_period
      period = {"." => "。", "．" => "。", "," => "、", "，" => "、"}
      new_str = ""
      exch = false
      unless @phrase.nil?
         unless /\A[!-~\s]+\z/ =~ @phrase
            strs = @phrase.split(/([\.,．，])/)
            strs.each {|s|
               unless /\A[\.,．，]\z/ =~ s
                  unless /[!-~ａ-ｚＡ-Ｚ０-９]$/ =~ s
                     exch = true
                  end
                  new_str = new_str + s
               end
               if /[\.,．，]/ =~ s
                  if exch
                     s = period[s]
                     exch = false
                  end
                  new_str = new_str + s
               end
            }
            @phrase = new_str
         end
      end
   end

   def namedowncase
      "#{self.class}".downcase
   end

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
   def self.exchange_entity(str)
      case str
      when /&copy;/
         str.gsub!(/&copy;/, "(c)")
      end
      return str
   end

   def cut_headmark
      case @arg
      when 'ul'
         reg = Regexp.new("^[*・]\s+")
      when '1'
         reg = Regexp.new("^[0-9]+\.?\s+")
      when 'a'
         reg = Regexp.new("^[a-z]+\.?\s+")
      when 'A'
         reg = Regexp.new("^[A-Z]+\.?\s+")
      when 'i'
         reg = Regexp.new("^[ivxｉｖｘⅰ-ⅻ]+\.?\s+")
      when 'I'
         reg = Regexp.new("^[IVXＩＶＸⅠ-Ⅻ]+\.?\s+")
      when ':'
         reg = Regexp.new("^:\s+")
      end
      @phrase.sub!(reg, "") if reg
   end
end

class Sentence < Phrase
   attr_accessor :ncxsrc

   def compile_xml(daisy)
      daisy.compile_text(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_text(self)
   end
end

class Caption < Phrase
   attr_accessor :ncxsrc, :ref

   def compile_xml(daisy)
      daisy.compile_caption(self)
   end
   def compile_smil(daisy)
      daisy.compile_smil_text(self)
   end
end

class Page < Phrase
   def initialize(phrase)
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
      daisy.compile_smil_page(self)
   end
end

class Normal < Page
end

class Front < Page
   def initialize(phrase)
      super
      @phrase.sub!(/\A[fF]:/, '')
   end
end

class Special < Page
   def initialize(phrase)
      super
      @phrase.sub!(/\A[sS]:/, '')
   end
end

class Headline < Tag
   class Sentence < Phrase
      attr_accessor :ncxsrc
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_headline(self)
      end

      def adjust_ncx
         cut_ruby()
         cut_xml_tag()
         cut_front_space()
      end
   end
end

class Title < Headline
   class Sentence < Phrase
      attr_accessor :ncxsrc
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_headline(self)
      end

      def adjust_ncx
         cut_ruby()
         cut_xml_tag()
         cut_front_space()
      end
   end
end

class Note < Footnote
   class Sentence < Phrase
      attr_accessor :ncxsrc, :child
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_customtest(self)
      end
   end
end

class Noteref < FootnoteRef
   class Sentence < Phrase
      attr_accessor :ncxsrc, :child
      def compile_xml(daisy)
         daisy.compile_noteref_sentence(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_text(self)
      end
   end
end

class Annotation < Footnote
   class Sentence < Phrase
      attr_accessor :ncxsrc, :child
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_customtest(self)
      end
   end
end

class Annoref < FootnoteRef
   class Sentence < Phrase
      attr_accessor :ncxsrc, :child
      def compile_xml(daisy)
         daisy.compile_noteref_sentence(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_text(self)
      end
   end
end

class Prodnote < Footnote
   class Sentence < Phrase
      attr_accessor :ncxsrc, :child, :ref
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_customtest(self)
      end
   end
end

class Sidebar < Footnote
   class Sentence < Phrase
      attr_accessor :ncxsrc, :child
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_customtest(self)
      end
   end
   class Caption < Phrase
      attr_accessor :ncxsrc, :child
      def compile_xml(daisy)
         daisy.compile_sidebar_caption(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_customtest(self)
      end
   end
end

class Quote < Tag
   class Sentence < Phrase
      attr_accessor :ncxsrc
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_text(self)
      end
   end
end

class Table < Tag
   class Sentence < Phrase
      attr_accessor :ncxsrc, :endcell
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_table(self)
      end
   end
   class Caption < Phrase
      attr_accessor :ncxsrc, :ref, :endcell
      def compile_xml(daisy)
         daisy.compile_table_caption(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_table(self)
      end
   end
end

class Li < List
   class Sentence < Phrase
      def initialize(phrase, arg = nil)
         super
         cut_headmark()
      end
      attr_accessor :ncxsrc
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_list(self)
      end
   end
end

class Dt < Dl
   class Sentence < Phrase
      def initialize(phrase, arg = nil)
         super
         cut_headmark()
      end
      attr_accessor :ncxsrc
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_list(self)
      end
   end
end

class Dd < Dl
   class Sentence < Phrase
      def initialize(phrase, arg = nil)
         super
      end
      attr_accessor :ncxsrc
      def compile_xml(daisy)
         daisy.compile_text(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_list(self)
      end
   end
end

class Image
   class Caption < Phrase
      def initialize(phrase, arg = nil)
         super
      end
      attr_accessor :ncxsrc, :ref
      def compile_xml(daisy)
         daisy.compile_image_caption(self)
      end
      def compile_smil(daisy)
         daisy.compile_smil_text(self)
      end
   end
end
