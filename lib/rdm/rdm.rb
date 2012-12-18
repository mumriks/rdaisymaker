# encoding: utf-8
# Copyright (c) 2011, 2012 Kishida Atsushi
#
require 'rdm/rdm/noteref'
require 'rdm/rdm/table'
require 'rdm/rdm/image'
require 'rdm/rdm/footnote'
require 'rdm/rdm/list'

class RDM
   def initialize
      ti = Hash.new {|ti, key| ti[key] = []}
      @tagids = ti
      s = Hash.new {|s, key| s[key] = []}
      @skip_list = s
      @skipChainList = []
      @ref = Array.new(2)
      @noterefNum = 0
      @file = nil
      @lineno = 1
      @skippable = []
      @first_sentence = nil
      @imgcount = 0
      @imgids = ''
      @big_image = []
      @theader = {}
      @nCount = 0
   end
   attr_accessor :tagids, :skip_list, :skipChainList,
                 :ref, :noterefNum, :file, :lineno, :first_sentence,
                 :imgcount, :imgids, :big_image, :theader,
                 :nCount, :skippable

   def check_same_args?
      @tagids.each {|key, t|
         if t.size != 1
            tagstr = ""
            t.each {|path, obj|
               tagstr = tagstr + "//#{obj.namedowncase}[#{key}]\n#{path}\n"
            }
            mes = "異なるタグで同じ識別子を使っているようです :\n" + tagstr
            print_error(mes)
         end
      }
   end

   def valid_syntax_at_poem?(array)
      case array[0][0].class.to_s
      when 'Sidebar', 'Image', 'Imagegroup', 'Linegroup'
         return true
      else
         mes = "#{array[0][0].class} は poem に含められません：\n #{File.basename(@file)} line: #{@lineno}"
         print_error(mes)
      end
   end

   def valid_syntax_at_linegroup?(array)
      case array[0][0].class.to_s
      when 'Linegroup', 'Image', 'Imagegroup', 'Prodnote', 'Note', 'Noteref', 'Annoref', 'Annotation', 'Quote', 'Paragraph'
         return true
      else
         mes = "#{array[0][0].class} は linegroup に含められません：\n #{File.basename(@file)} line: #{@lineno}"
         print_error(mes)
      end
   end

   def note?(obj)
      obj.instance_of?(Note)
   end
   def noteref?(obj)
      obj.instance_of?(Noteref)
   end
   def noteS?(obj)
      obj.instance_of?(Note::Sentence)
   end
   def noterefS?(obj)
      obj.instance_of?(Noteref::Sentence)
   end
   def annotationS?(obj)
      obj.instance_of?(Annotation::Sentence)
   end
   def annorefS?(obj)
      obj.instance_of?(Annoref::Sentence)
   end
   def annotation?(obj)
      obj.instance_of?(Annotation)
   end
   def annoref?(obj)
      obj.instance_of?(Annoref)
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
