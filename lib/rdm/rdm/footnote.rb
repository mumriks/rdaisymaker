# encoding: utf-8
# Copyright (c) 2011, 2012 Kishida Atsushi

class RDM
   def make_note_sentence(phr, args, num, type)
      if PARAGRAPH =~ phr
         @paCount += 1
      else
         make_paragraph()
         ns = make_sentence(phr, "#{type}::Sentence", "#{args[0]}-#{num}")
         @first_sentence = ns if @first_sentence.nil?
         @skipChainList << [args[0], Skip.new(@file, @lineno, ns)]
         return ns
      end
      return nil
   end

   def make_render_note_sentence(phr, args, num, type)
      if PARAGRAPH =~ phr
         @paCount += 1
      else
         objs = []
         make_paragraph()
         if args[1] and @first_sentence.nil?
            objs << sidebar_caption(args[1])
         end
         @nCount += 1
         ns = make_sentence(phr, "#{type}::Sentence", "#{args[0]}-#{num}")
         @first_sentence = ns if @first_sentence.nil?
         objs << ns
         return objs
      end
      return nil
   end

   def make_note_pre(args, type)
      case type
      when 'Prodnote', 'Sidebar'
         return render_note_pre(args, type)
      when 'Quote'
         return quote_pre(args)
      else
         return footnote_pre(args, type)
      end
   end

   def render_note_pre(args, type)
      @nCount += 1
      if eval "#{type}.valid_render?(args[0])"
         return eval %Q!#{type}.new("ps#{@nCount}", args[0])!
      else
         print_error(render_mes(args[0]))
      end
   end

   def quote_pre(args)
      @nCount += 1
      unless Quote.valid_border?(args[0])
         puts "Quoteタグのborder指定が間違っているようです。borderなしで作成します：\n#{File.basename(@file)} line:#{@lineno}"
         return Quote.new("qt#{@nCount}")
      end
      return Quote.new("qt#{@nCount}" ,args[0])
   end

   def footnote_pre(args, type)
      n = eval "#{type}.new(args[0])"
      @tagids[args[0]] << ["#{File.basename(@file)} - line:#{@lineno}", n]
      @skip_list[n.arg] << Skip.new(@file, @lineno, n)
      return n
   end

   def sidebar_caption(caption)
      @nCount += 1
      sc = make_sentence(caption, 'Sidebar::Caption', "sc#{@nCount}")
      @first_sentence = sc if @first_sentence.nil?
      return sc
   end

   def no_sentence_in_note(type, args)
      type = 'footnote' if type == 'Note'
      mes = "注釈本文がありません : //#{type.downcase}#{args}
#{File.basename(@file)} line:#{@lineno}"
      print_error(mes)
   end

   def check_phrase_size(type, phr)
      mes = "#{type}は、できるだけひとつのフレーズにしてください：\n#{File.basename(@file)} line:#{@lineno}"
      puts mes if 1 < phr.size and "Quote" != type
      return phr.size
   end

   def render_mes(render)
      "render の指定が違っているようです : [#{render}]\n#{File.basename(@file)} line:#{@lineno}"
   end

   def valid_syntax_at_note?(phr)
      return true
      phr.flatten!
      if phr[0].instance_of?(Indent)
         return true
      elsif phr[0].instance_of?(Image)
         return true
      elsif phr[0].kind_of?(List)
         return true
      elsif phr[0].instance_of?(Quote)
         return true
      else
         mes = "\n#{File.basename(@file)} line:#{@lineno}"
         print_error(mes)
      end
   end
end
