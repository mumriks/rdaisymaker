#!/usr/bin/env ruby
# encoding: utf-8
#
# copyright (c) 2011, 2012 Kishida Atsushi
#

class Tag
   attr_accessor :tag, :arg, :style

   def post
      @tag = "/#{$1}" if /(\w+)/ =~ @tag
      self
   end
   def null
      @tag = "#{$1} /" if /(\w+)/ =~ @tag
      self
   end

   def namedowncase
      "#{self.class}".downcase
   end

   def self.split_args(args)
      arg = args[0]
      caption = args[1] if args[1]
      return arg, caption
   end

   def self.valid_indent?(indent = nil)
      return true if indent.nil?
      unless "end" == indent.to_s
         unless /\A(?:x[1-9]?|-?[1-9])\z/ =~ indent.to_s
            return false
         end
      end
      return true
   end
end

class Headline < Tag
   def initialize(arg, indent = nil)
      @tag = "h#{arg}"
      @arg = arg
      @indent = indent.to_s unless indent.nil?
   end
   attr_accessor :indent, :style
   undef null

   def self.valid_args?(arg, indent = nil)
      return false unless '7' > arg.to_s
      if indent
         return false unless self.valid_indent?(indent)
      end
      return true
   end
   def compile_xml(daisy)
      daisy.compile_headline_tag(self)
   end
end

class Title < Headline
   def initialize(arg = nil)
      @tag = 'doctitle'
      @arg = arg
   end
   def compile_xml(daisy)
      daisy.compile_doctitle_tag(self)
   end
end

class Image < Tag
   def initialize(file, arg)
      @tag = 'img'
      @arg = arg
      @file = file
   end
   attr_accessor :file, :width, :height, :ref, :alt
   undef null, post

   def compile_xml(daisy)
      daisy.compile_image(self)
   end
   def compile_smil(daisy)
   end
end

class Table < Tag
   def initialize(arg, border = nil)
      @tag = 'table'
      @arg = arg
      @border = border
   end
   attr_accessor :border, :endId

   def compile_xml(daisy)
      daisy.compile_table_tag(self)
   end
end

class Tbody < Table
   def initialize
      @tag = 'tbody'
   end
end

class Tr < Table
   def initialize
      @tag = 'tr'
   end
end

class Th < Tr
   def initialize
      @tag = 'th'
   end
end

class Td < Tr
   def initialize(style = nil)
      @tag = 'td'
      @style = style
   end
end

class NoteGroup < Tag
   def self.valid_render?(render = nil)
      if /\A[rR]|\A[oO]/ =~ render.to_s
         return true
      elsif render.nil?
         return true
      else
         return false
      end
   end

   def self.set_render_str(render = nil)
      return 'required' if /\A[rR]/ =~ render.to_s or render.nil?
      return 'optional' if /\A[oO]/ =~ render.to_s
   end
end

class Footnote < NoteGroup
end
class FootnoteRef < NoteGroup
   def refStr_cut_brace
      @str.gsub(/[\[\(\)\]（）［］]/, "")
   end
end

class Note < Footnote
   def initialize(arg)
      @tag = 'note'
      @arg = arg
   end
   attr_accessor :navid, :ncxsrc, :ref

   def compile_xml(daisy)
      daisy.compile_note_tag(self)
   end
end

class Noteref < FootnoteRef
   def initialize(arg, str)
      @tag = 'noteref'
      @arg = arg
      @str = str
   end
   attr_accessor :str, :at, :noteArg
   def compile_xml(daisy)
   end
end

class Annotation < Footnote
   def initialize(arg)
      @tag = 'annotation'
      @arg = arg
   end
   attr_accessor :navid, :ncxsrc, :ref

   def compile_xml(daisy)
      daisy.compile_note_tag(self)
   end
end

class Annoref < FootnoteRef
   def initialize(arg, str)
      @tag = 'annoref'
      @arg = arg
      @str = str
   end
   attr_accessor :str, :at, :noteArg
   def compile_xml(daisy)
   end
end

class Prodnote < Footnote
   def initialize(arg, render = nil)
      @tag = 'prodnote'
      @arg = arg
      @render = NoteGroup.set_render_str(render)
   end
   attr_accessor :render, :ref, :group, :navid, :ncxsrc

   def compile_xml(daisy)
      daisy.compile_note_render_tag(self)
   end
end

class Sidebar < Footnote
   def initialize(arg, render = nil)
      @tag = 'sidebar'
      @arg = arg
      @render = NoteGroup.set_render_str(render)
   end
   attr_accessor :render, :navid, :ncxsrc

   def compile_xml(daisy)
      daisy.compile_note_render_tag(self)
   end
end

class Linenum < Footnote
   def initialize(arg)
      @tag = ''
      @arg = arg
   end
   attr_accessor :navid, :ncxsrc

   def compile_xml(daisy)
   end
   def compile_smil(daisy)
   end
end

class Indent < Tag
   def initialize(indent)
      @indent = indent.to_s
      @terminal = indent_finish?()
   end
   attr_accessor :indent, :terminal

   def post
      @indent = '0'
      @terminal = true
      return self
   end

   def compile_xml(daisy)
      daisy.compile_indent(self)
   end

   private

   def indent_finish?
      return true if '0' == @indent
      return false
   end
end

class Quote < Tag
   def initialize(arg, border = nil)
      @tag = 'blockquote'
      @arg = arg
      @border = true if border and "" != border
   end
   attr_accessor :border

   def self.valid_border?(border)
      return true if border.nil? or "" == border
      return true if /\A[bB]/ =~ border
      return false
   end
   def compile_xml(daisy)
      daisy.compile_quote_tag(self)
   end

   class Indent < Tag
      def initialize(indent)
         @indent = indent.to_s
         @terminal = indent_finish?()
      end
      attr_accessor :indent, :terminal

      def post
         @indent = '0'
         @terminal = true
         return self
      end

      def compile_xml(daisy)
         daisy.compile_quote_indent(self)
      end

      private

      def indent_finish?
         return true if '0' == @indent
         return false
      end
   end
end

class ImageGroup < Tag
   def initialize(arg)
      @tag = 'imggroup'
      @arg = arg
      @start = false
   end

   def start
      @start = true
      self
   end
   def finish
      @start = false
      self
   end
   def start?;  @start;          end

   def compile_xml(daisy)
      daisy.compile_imagegroup(self)
   end
end

class List < Tag
   def initialize(arg, type, enum)
      @arg = arg
      @type = type
      @enum = enum
   end
   attr_accessor :type, :enum, :ncxsrc

end

class Li < List
   def initialize
      @tag = 'li'
   end
   def compile_xml(daisy)
      daisy.compile_list_tag_dl(self)
   end
end

class Ul < List
   def initialize(arg, type, enum)
      super
      @tag = 'ul'
   end
   def compile_xml(daisy)
      daisy.compile_list_tag_ulol(self)
   end
end

class Ol < List
   def initialize(arg, type, enum)
      super
      @tag = 'ol'
   end
   def compile_xml(daisy)
      daisy.compile_list_tag_ulol(self)
   end
end

class Dl < List
   def initialize(arg, type, enum)
      super
      @tag = 'dl'
   end
   def compile_xml(daisy)
      daisy.compile_list_tag_dl(self)
   end
end

class Dt < Dl
   def initialize
      @tag = 'dt'
   end
   def compile_xml(daisy)
      daisy.compile_list_tag_dl(self)
   end
end

class Dd < Dl
   def initialize
      @tag = 'dd'
   end
   def compile_xml(daisy)
      daisy.compile_list_tag_dl(self)
   end
end

class Paragraph < Tag
   def initialize(arg = nil)
      @tag = 'p'
      @arg = arg
   end

   def compile_xml(daisy)
      daisy.compile_paragraph(self)
   end
end

class Div < Tag
   def initialize
      @tag = 'div'
   end
   def compile_xml(daisy)
      daisy.compile_plain_tag(self)
   end
end

class Break < Tag
   def initialize
      @tag = "br"
   end

   def compile_xml(daisy)
      daisy.compile_plain_tag(self)
   end
end
