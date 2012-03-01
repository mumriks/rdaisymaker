# encoding: utf-8
# mecab-ruby の文字コードを補完
# Copyright (c) 2012 Kishida Atsushi
#
require 'MeCab'

module MeCab
   class Model
=begin
      def dictionary_info
      end
      def createTagger
      end
      def createLattice
      end
      def swap
      end
=end
   end

   class Tagger
      def parseEx(arg)
         $enc = arg.encoding if arg.instance_of?(String)
         result = self.parse(arg)
         result.force_encoding($enc) if arg.instance_of?(String)
      end
      def parseToNodeEx(arg)
         $enc = arg.encoding if arg.instance_of?(String)
         result = self.parseToNode(arg)
      end
=begin
      def parseNBest(num, str, l)
      end
      def parseNBestInit
      end
      def nextNode
      end
      def next
      end
      def formatNode
      end
      def set_request_type
      end
      def request_type
      end
      def partial
      end
      def set_partial
      end
      def lattice_level
      end
      def set_lattice_level
      end
      def all_morphs
      end
      def set_all_morphs
      end
      def set_theta
      end
      def theta
      end
      def dictionary_info
      end
      def what
      end
      def parseToString
      end
=end
   end

   class Lattice
      def set_sentenceEx(arg)
         $enc = arg.encoding if arg.instance_of?(String)
         set_sentence(arg)
      end
      def toStringEx
         self.toString.force_encoding($enc)
      end
=begin
      def clear; end
      def is_available; end
      def bos_node; end
      def eos_node; end
      def end_nodes; end
      def begin_nodes; end
      def sentence; end
      def size; end
      def set_Z; end
      def Z; end
      def set_theta; end
      def theta; end
      def next; end
      def request_type; end
      def has_request_tyep; end
      def set_request_type; end
      def add_request_type; end
      def remove_request_type; end
      def toString; end
      def enumNBestAsString; end
      def what; end
      def set_what; end
      def set_sentence; end
=end
   end

   class Node
      def surfaceEx
         self.surface.force_encoding($enc)
      end
      def featureEx
         fex = self.feature.force_encoding($enc)
         fexa = fex.split(/,/)
         @pos = fexa[0]
         @pos1 = fexa[1]
         @pos2 = fexa[2]
         @pos3 = fexa[3]
         @dec1 = fexa[4]
         @dec2 = fexa[5]
         @root = fexa[6]
         @reading = fexa[7]
         @sound = fexa[8]
         fex
      end
      attr_reader :pos, :pos1, :pos2, :pos3, :dec1, :dec2, :root, :reading, :sound
=begin
      def prev; end
      def next; end
      def enext; end
      def bnext; end
      def rpath; end
      def lpath; end
      def feature; end
      def id; end
      def length; end
      def rlength; end
      def rcAttr; end
      def lcAttr; end
      def posid; end       # not use
      def char_type; end
      def stat; end
      def isbest; end
      def alpha; end
      def beta; end
      def prob=; end
      def prob; end
      def wcost; end
      def cost; end
=end
   end
end
