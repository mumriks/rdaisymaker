# encoding: utf-8
# Copyright (c) 2011, 2012 Kishida Atsushi

class RDM
   def list_pre(phr0, args)
      type, enum, id = nil, nil, nil
      @nCount += 1
      if 0 < args.size
         if /\A([1aAiI])\z/ =~ args[0]
            enum = $1; type = 'ol'; id = "ol#{@nCount}"
            return Ol.new(id, type, enum), type, id
         end
         print_error(list_arg_error)
      elsif /^:[\s　]+/ =~ phr0
         type = 'dl'; enum = ':'; id = "dl#{@nCount}"
         return Dl.new(id, type, enum), type, id
      else
         type = 'ul'; enum = '*'; id = "ul#{@nCount}"
         return Ul.new(id, type, enum), type, id
      end
   end

   def make_li(phr, id = nil)
      objs = []
      objs << Li.new
      if id
         @first_sentence = make_sentence(phr, "Li::Sentence", id)
         objs << @first_sentence
      else
         objs << make_sentence(phr, "Li::Sentence")
      end
      objs << Li.new.post
      return objs
   end

   def make_dt(phr, id = nil)
      objs = []
      objs << Dt.new
      if id
         @first_sentence = make_sentence(phr, "Dt::Sentence", id)
         objs << @first_sentence
      else
         objs << make_sentence(phr, "Dt::Sentence")
      end
      objs << Dt.new.post
      return objs
   end

   def make_dd(phr, id = nil)
      objs = []
      if id
         objs << make_sentence(phr, "Dd::Sentence", "end")
      else
         objs << make_sentence(phr, "Dd::Sentence")
      end
      objs << Dd.new.post
      return objs
   end

   def list_arg_error
      "リストオプションは[1aAiI]のいずれかの文字で指定してください"
   end

   def not_data_in_list
      mes = "リストデータがありません。#{File.basename(@file)} line:#{@lineno}"
      print_error(mes)
   end

   def not_dt_data(phr)
      mes = "用語リストのタイトルがありません。#{File.basename(@file)} line:#{@lineno}#{phr}\n"
      print_error(mes)
   end

   def not_dd_data(phr)
      mes = "用語リストのデータがありません。#{File.basename(@file)} line:#{@lineno}#{phr}\n"
      print_error(mes)
   end

   def valid_syntax_at_list?(phr)
      phr.flatten!
      mes = "リスト内では使用できないタグです。\n#{File.basename(@file)} line:#{@lineno} : #{phr[0].class}\n"
      print_error(mes)
   end
end
