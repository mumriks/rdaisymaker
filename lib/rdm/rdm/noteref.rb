# encoding: utf-8
# Copyright (c) 2011, 2012 Kishida Atsushi
#

class RDM
   def make_sentence(phrase, tag = nil, arg = nil)
      restore = analyze_noteref(phrase)
      refs = collect_ref_same_sentence(restore)
      if refs.empty?
         return Sentence.new(restore[0]) if tag.nil?
         return eval "#{tag}.new(restore[0], arg)"
      elsif 1 == refs.size
         rs = eval "#{refs[0].class}::Sentence.new(restore)"
         refs[0].at = rs
         @skip_list[refs[0].arg] << Skip.new(@file, @lineno, refs[0])
         @skipChainList << [refs[0].arg, Skip.new(@file, @lineno, rs)]
         return rs
      else
         rs = eval "#{refs[0].class}::Sentence.new(restore)"
         refs.each {|ref|
            ref.at = rs
            @skip_list[ref.arg] << Skip.new(@file, @lineno, ref)
            @skipChainList << [ref.arg, Skip.new(@file, @lineno, rs)]
         }
         return rs
      end
   end

   def collect_ref_same_sentence(restore)
      refs = []
      restore.each {|x|
         refs << x if x.instance_of?(Noteref)
         refs << x if x.instance_of?(Annoref)
      }
      return refs.flatten
   end

   def analyze_noteref(phrase)
      refStr = []
      while /@<[af]n>{[^}]+}/ =~ phrase
         ref_str, post_str = split_noteref_phrase(phrase)
         refStr << ref_str.flatten
         phrase = post_str
      end
      refStr << phrase unless "" == phrase
      return refStr.flatten
   end

   def split_noteref_phrase(phrase)
      m = /@<([af])n>{([^}]+)}/.match(phrase)
      mark = $1
      argstr = $2.split(/,/)
      pre_str = m.pre_match if m.pre_match
      post_str = m.post_match if m.post_match
      ref = make_noteref_object(mark, argstr[0], argstr[1])
      if ref.nil?
         return pre_str, post_str
      else
         return [pre_str, ref], post_str
      end
   end

   def make_noteref_object(mark, arg, ref_str)
      if mark
         unless /\A[a-zA-Z0-9_-]+\z/ =~ arg
            ref_tag = "@<#{mark}n>{#{arg}}" if ref_str.nil?
            ref_tag = "@<#{mark}n>{#{arg},#{ref_str}}}" unless ref_str.nil?
            ref_error(ref_tag)
         end
         ref_str = set_noteref_str(ref_str)
         rs = Annoref.new(arg, ref_str) if 'a' == mark
         rs = Noteref.new(arg, ref_str) if 'f' == mark
         set_skippable(mark)
         return rs
      else
         return nil
      end
   end

   def set_noteref_str(ref_str)
      if ref_str.nil?
         @noterefNum += 1
         @ref[1] = true
         return "(#{@meta.refmark}#{@noterefNum})"
      else
         @ref[0] = true
         return ref_str
      end
   end


   def set_skippable(mark)
      @skippable << 'noteref' if "f" == mark
      @skippable << 'annoref' if "a" == mark
   end

   def ref_error(reftag)
      mes = "引数の文法が違うようです : #{reftag}\n#{File.basename(@file)} line:#{@lineno}"
      print_error(mes)
   end

   def collect_key_arg
      args = []
      @skipChainList.reverse_each {|key, skip|
         args << key
      }
      return args.uniq
   end

   def check_note_ref_key_order
      nrefs, arefs, notes, annos = [], [], [], []
      @skipChainList.each {|key, skip|
         nrefs << [key, skip] if noterefS?(skip.obj)
         arefs << [key, skip] if annorefS?(skip.obj)
         notes << [key, skip] if noteS?(skip.obj)
         annos << [key, skip] if annotationS?(skip.obj)
      }
      check_key_order(nrefs, notes, "note") unless nrefs.nil?
      check_key_order(arefs, annos, "anno") unless arefs.nil?
   end

   MES = "注釈番号と注釈の登場順序がおかしい可能性があります。\n"

   def check_key_order(refs, notes, type)
      ir = 0; i = 0
      (refs.size - 1).times {
         refBefour = refs[ir][0]; refAfter = refs[ir + 1][0]
         befour = notes.index(notes.assoc(refBefour))
         after = notes.index(notes.assoc(refAfter))
         if befour > after
            r1 = "file: #{refs[ir][1].file}, line: #{refs[ir][1].lineno}, #{type}ref: #{refs[ir][0]}　と　"
            r2 = "file: #{refs[ir + 1][1].file}, line: #{refs[ir + 1][1].lineno}, #{type}ref: #{refs[ir + 1][0]}\n"
            n1 = "file: #{notes[befour][1].file}, line: #{notes[befour][1].lineno}, #{type}: #{notes[befour][0]}　と　"
            n2 = "file: #{notes[after][1].file}, line: #{notes[after][1].lineno}, #{type}: #{notes[after][0]}"
            puts MES + r1 + r2 + n1 + n2
         end
         ir += 1; i += 1
      }
   end

   def collect_key(key)
      msgs = ""
      @skip_list[key].each {|skip|
         msgs += "file: #{skip.file}, line: #{skip.lineno}\n"
      }
      return msgs
   end

   def check_note_ref_order
      @skip_list.each {|key, skip|
         ref = 0
         note = 0
         skip.each_with_index {|s, i|
            @sf = s.file
            @sl = s.lineno
            @so = s.obj
            ref = i if noteref?(s.obj)
            note = i if note?(s.obj)
            ref = i if annoref?(s.obj)
            note = i if annotation?(s.obj)
         }
         if ref > note
            msgs = collect_key(key)
            mes = "注釈と注釈番号の順序が反対のようです : [#{key}]\n#{msgs}"
            print_error(mes)
         end
      }
   end

   def collect_ref(key)
      msgs = ""
      @skip_list[key].each {|skip|
         if noterefS?(skip.obj)
            msgs += "file: #{skip.file}, line: #{skip.lineno}\n"
         elsif annorefS?(skip.obj)
            msgs += "file: #{skip.file}, line: #{skip.lineno}\n"
         end
      }
      return msgs
   end

   def collect_base(key)
      msgs = ""
      @skip_list[key].each {|skip|
         if note?(skip.obj)
            msgs += "file: #{skip.file}, line: #{skip.lineno}\n"
         elsif annotation?(skip.obj)
            msgs += "file: #{skip.file}, line: #{skip.lineno}\n"
         end
      }
      return msgs
   end

   def check_note_ref_pare
      @skip_list.each {|key, skip|
         ref = 0
         note = 0
         skip.each {|s|
            @sf = s.file
            @sl = s.lineno
            @so = s.obj
           if noteref?(s.obj) or annoref?(s.obj)
              ref += 1; @r = s.obj
           elsif note?(s.obj) or annotation?(s.obj)
              note += 1; @n = s.obj
           end
         }
         unless ref == 0
            if ref > 1
               msgs = collect_ref(key)
               mes = "同じ識別子を持った注釈番号が複数あるようです [#{key}]\n#{msgs}"
               print_error(mes)
            elsif note > 1
               msgs = collect_base(key)
               mes = "同じ識別子を持った注釈が複数あるようです [#{key}]\n#{msgs}"
               print_error(mes)
            elsif ref > note
               mes = "注釈番号 [#{key}] に対応する注釈が見つかりません
file: #{@sf} line: #{@sl}\n"
               print_error(mes)
            elsif ref < note
               mes = "注釈番号 [#{key}] に対応する注釈が複数あるようです
file: #{@sf} line: #{@sl}\n"
               print_error(mes)
            end
         end
         if @r
            @r.noteArg = @n.arg
            @n.ref = @r.refStr_cut_brace
         end
         @r, @n = nil, nil
      }
   end

   def set_note_ref_chain
      child = nil
      last = nil
      args = collect_key_arg()
      args.each_with_index {|arg, i|
         @skipChainList.reverse_each {|key, skip|
            if arg == key
               if noteS?(skip.obj) or annotationS?(skip.obj)
                  if child
                     skip.obj.child = child
                  else
                     last = skip.obj
                  end
                  child = skip.obj
               elsif noterefS?(skip.obj) or annorefS?(skip.obj)
                  if skip.obj.child
                     last.child = skip.obj.child
                  end
                  skip.obj.child = child if child
                  child = nil
               end
            end
         }
         child = nil
      }
   end

   def skippable_check
      unless @skip_list.nil?
         check_note_ref_pare()
         check_note_ref_order()
         check_note_ref_key_order()
      end
   end

   def refNum_unity?(file)
      if @ref[0] && @ref[1]
         mes "注釈番号の指定で、有りと無しが混在しています。#{file.chomp}"
         print_error(mes)
      end
   end
end
