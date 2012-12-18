# encoding: utf-8
# Copyright (c) 2012 Kishida Atsushi
#

module Daisy2
   def initialize(values = nil)
      super
      @ncc = []
      @masterSmils = []
      @seqs = []
      @audios = {}
      @big_image = []
      @daisy2 = true
   end
   attr_accessor :char_set, :set_info, :toc_items, :depth, :files,
                 :generator, :kbyte_size, :identifier, :contributor,
                 :maxPageNormal, :format, :pageNormal,
                 :pageFront, :pageSpecial, :footnotes, :prodNotes, :sidebars
   attr_accessor :ncc, :masterSmils, :seqs, :audios

   @@sectcount = 0
   @@narrator = nil
   @@narrator_id = nil
   @@modify = []
   @@id = 1
   @@sect = nil
   @@paCount = 0
   @@paClass = nil

   def image_too_big?
      unless 0 == @big_image.size
         puts "次の画像は推奨サイズ(#{Daisy::IMGWIDTH}x#{Daisy::IMGHEIGHT})よりも大きいです。"
         @big_image.uniq.each {|img|
            width, height = get_image_size(img)
            puts "#{img} (#{width} x #{height})"
         }
      end
   end
   @@note, @@uol = nil, nil

   def get_ncc_data(root)
      get_ncc_meta(root.elements["/html/head"])
      get_ncc_body(root.elements["/html/body"])
   end

   def get_css_files(head)
      csss = []
      head.each_element {|e|
         if 'link' == e.name and 'stylesheet' == e.attributes["rel"]
            csss << e.attributes["href"] if e.attributes["href"]
         end
      }
      return csss
   end

   def get_image_files(body)
      @@images = []
      get_element(body) if body.has_elements?
      return @@images
   end

   def get_element(elm)
      elm.each_element {|e|
         if  'img' == e.name
            @@images << e.attributes["src"]
            next
         end
         get_element(e) if e.has_elements?
      }
   end

   def get_smil_data(body)
      body.each_element {|e|
         case e.name
         when 'ref'
            get_master_smil(e)
         when 'seq'
            if e.attributes["dur"]
               @@seq = Smil::Seq.new(e.attributes["dur"])
               @seqs << @@seq
            end
            get_smil_data(e) if e.has_elements?
         when 'par'
            @@par = Smil::Par.new(e.attributes["endsync"])
            @@seq.item << @@par if @@seq
            get_smil_data(e) if e.has_elements?
         when 'text'
            src = e.attributes["src"]
            id = e.attributes["id"]
            if @@narrator_id == id
               @@seq.item.delete(@@par)
               next
            end
            @@par.text = Smil::Text.new(src, id)
         when 'audio'
            src = e.attributes["src"]
            clipBegin = e.attributes["clip-begin"]
            clipEnd = e.attributes["clip-end"]
            id = e.attributes["id"]
            @@par.audio = Smil::Audio.new(src, clipBegin, clipEnd, id) if @@par
            @audios[@@par.text.id] = @@par.audio unless @@par.text.nil?
         else
            get_smil_data(e) if e.has_elements?
         end
      }
   end

   def new_chapter
      @@chapter = Chapter.new
      self.add_chapter(@@chapter)
      @@level = 0
   end

   def new_section
      @@sect = Section.new
      @@chapter.add_section(@@sect)
      @@sectcount += 1
   end

   def make_paragraph
      if 0 < @@paCount
         p = Paragraph.new(@@paCount)
         p.style = @@paClass
         @@sect.add_phrase(p) if @@sect
         @@paCount = 0
      end
   end

   def get_doc(body)
      body.each_element {|e|
         case e.name
         when 'div', 'DIV'
            @@paCount += 1
            get_doc(e) if e.has_elements?
         when 'p', 'P'
            @@narrator = true if /narrator|NARRATOR/ == e.attributes["class"]
            @@paCount += 1
            @@paClass = e.attributes["class"]
            if /note|NOTE/ =~ @@paClass
               @skippable.note = 'false'
               @@note = Note.new("nt#{@@id}")
               @@sect.add_phrase(@@note)
               get_doc(e) if e.has_elements?
               @@sect.phrases[@@sect.phrases.size - 1].child = nil
               @@sect.phrases[@@sect.phrases.size - 1].arg = "#{@@sect.phrases[@@sect.phrases.size - 1].arg}-E"

               @@sect.add_phrase(@@note.dup.post)
               @@id += 1
            else
               get_doc(e) if e.has_elements?
            end
         when /[hH][1-6]/
            make_paragraph()
            @@sect.add_phrase(Paragraph.new(1)) if @@sect
            args = $1.to_i if /([1-6])/.match(e.name)
            new_chapter() if 1 == args and 1 == @@level
            @@level = args
            if /title|TITLE/ =~ e.attributes["class"]
               @@h = Title.new(args)
               @@temp = ["Title", e.attributes["id"]]
            else
               @@h = Headline.new(args)
               @@temp = ["Headline", e.attributes["id"]]
            end
            new_section()
            @@sect.add_phrase(@@h)
            other_elements?(e)
            @@sect.add_phrase(@@h.dup.post)
         when 'a', 'A'
            make_paragraph()
            if @@temp
               if @@temp.kind_of?(Page)
                  if 'textNCX' == @xmeta.multimediaType
                     @@temp.phrase =  e.text.succ
                  else
                     @@temp.phrase =  e.text
                  end
               else
                   @@modify << e.text
               end
            else
               puts "anothor a"
            end
            get_doc(e) if e.has_elements?
         when 'span', 'SPAN'
            make_paragraph()
            if @@narrator
               if /\A朗読/ =~ e.text and self.instance_of?(TEXTDaisy)
                  @@narrator_id = e.attributes["id"]
                  @@narrator = false
                  next
               else
                  @@sect.add_phrase(Indent.new("x1"))
               end
            end
            case e.attributes["class"]
            when 'underline', 'UNDERLINE'
               @@modify << "@<u>{#{e.text}}"
            when /\A(?:page|PAGE)-(front|normal|special|FRONT|NORMAL|SPECIAL)/
               eval "@skippable.#{$1} = 'false'"
               page = $1.capitalize
               @@temp = eval(%Q!#{page}.new("")!)
               @@temp.readid = @@temp.totalid = e.attributes["id"]
               @@sect.add_phrase(@@temp)
               other_elements?(e)
            else
               if /note|NOTE/ =~ @@paClass
                  @@temp = ["Note", e.attributes["id"]]
               else
                  @@temp = ["", e.attributes["id"]]
               end
               other_elements?(e)
               if @@narrator
                  @@sect.add_phrase(Indent.new("0"))
                  @@narrator = false
               end
            end
         when 'img', 'IMG'
            make_paragraph()
            mes, image = check_imagefile(e.attributes["src"])
            if /errmes[1-3]/ =~ mes
               print_err(Daisy::ERRMES["#{mes}"] + e.attributes["src"])
            elsif 'errmes4' == mes
               @big_image << e.attributes["src"]
            end
            i = Image.new(image, "img-#{@@id}")
            width, height = get_image_size(e.attributes["src"])
            i.width = width; i.height = height
            i.alt = e.attributes["alt"]
            @@sect.add_phrase(i)
            @@id += 1
            get_doc(e) if e.has_elements?
         when 'br', 'BR'
           @@paCount += 1
         when 'table', 'TABLE'
            make_paragraph()
            t = Table.new("tb#{@@id}", e.attributes["border"])
            @@sect.add_phrase(t)
            get_doc(e) if e.has_elements?
            @@sect.add_phrase(t.dup.post)
            @@id += 1
         when 'tbody', 'TBODY'
            get_table_data(e)
            @@first_td.endcell = @@td
            @@first_td.arg = "tb#{@@id}"
         when 'ul', 'ol'
            make_paragraph()
            tag = e.name.capitalize
            @@uol = eval %Q!#{tag}.new("li#{@@id}", 'ul', '*')!
            @@sect.add_phrase(@@uol)
            get_doc(e) if e.has_elements?
            @@sect.phrases[@@sect.phrases.size - 2].arg = "#{@@sect.phrases[@@sect.phrases.size - 2].arg}-E"
            @@sect.add_phrase(@@uol.dup.post)
            @@id += 1
         when 'li'
            @@li = Li.new
            @@li.arg = @@id
            @@li.arg = e.attributes["id"] if e.attributes["id"]
            @@sect.add_phrase(@@li)
            get_list_data(e)
            @@sect.add_phrase(@@li.dup.post)
         when 'ruby', 'RUBY'
            e.each_child {|r|
               next if "\n" == r.to_s
               case r.name
               when 'rb', 'RB'
                  @@kanji = r.text
               when 'rt', 'RT'
                  @@ruby = r.text
               end
            }
            @@modify << "@<ruby>{#{@@kanji},#{@@ruby}}"
         when 'strong', 'b', 'STRONG', 'B'
            @@modify << "@<b>{#{e.text}}"
         when 'em', 'i', 'EM', 'I'
            @@modify << "@<i>{#{e.text}}"
         else
            get_doc(e) if e.has_elements?
         end
      }
   end

   def calc_totalTime
      times = []
      @seqs.each {|s|
         times << read_time_in_this_smil(s.dur)
      }
      return time_add_time(times)
   end

   private

   def other_elements?(elm)
      if elm.has_elements?
         get_doc(elm)
         if @@temp.kind_of?(Page)
            get_doc(elm)
         else
            make_sentence(restore_doc(elm))
         end
      else
         if @@temp.kind_of?(Page)
            if 'textNCX' == @xmeta.multimediaType
               @@temp.phrase = elm.text.succ
            else
               @@temp.phrase = elm.text
            end
         else
             make_sentence(elm.text)
         end
      end
      @@temp = nil
   end

   def make_sentence(phrase)
      return if /\A\s*\z/ =~ phrase
      if "" == @@temp[0] or @@temp.nil?
         s = eval "Sentence.new(phrase, @@temp[1])"
      elsif "Headline" == @@temp[0] or "Title" == @@temp[0]
         s = eval "#{@@temp[0]}::Sentence.new(phrase, @@level)"
         s.set_navstr()
      else
         arg = @@temp[1]
         arg = "nt#{@@id}" if 'Note' == @@temp[0]
         arg = "li#{@@id}" if 'Li' == @@temp[0]
         s = eval "#{@@temp[0]}::Sentence.new(phrase, arg)"
         s.child = true if 'Note' == @@temp[0]
      end
      s.readid = s.totalid = @@temp[1]
      @@sect.add_phrase(s)
      if @@note
         @@note.ncxsrc = s if @@note.ncxsrc.nil?
      end
      if s.instance_of?(Li::Sentence) and @@uol
         @@uol.ncxsrc = s if @@uol.ncxsrc.nil?
      end
   end

   def restore_doc(elm)
      docs = elm.texts
      str = ""
      i = j = 0
      elm.children.each {|c|
         if c.instance_of?(REXML::Text)
            str << docs[i].to_s
            i += 1
         else
            str << @@modify[j].to_s
            j += 1
         end
      }
      @@modify = []
      return str
   end

   def get_table_data(tbody)
      @@num = 0
      tbody.each_element {|tr|
         @@sect.add_phrase(Tr.new)
         tr.each_element {|td|
            @@num += 1
            if td.has_elements?
              if th?(td.name)
                 thd = Th.new
                 @@sect.add_phrase(thd)
              elsif td?(td.name)
                 thd = Td.new
                 @@sect.add_phrase(thd)
              end
              if /nowrap|NOWRAP/ =~ td.attributes["class"]
                 thd.style = td.attributes["class"]
              end
               get_td_data(td)
               @@sect.add_phrase(Th.new.post) if th?(td.name)
               @@sect.add_phrase(Td.new.post) if td?(td.name)
            else
               t = Th.new.null if th?(td.name)
               t = Td.new.null if td?(td.name)
               @@sect.add_phrase(t)
               @@first_td = t if 1 == @@num
            end
         }
         @@sect.add_phrase(Tr.new.post)
      }
   end

   def th?(name)
      /\A[Tt][Hh]\z/ =~ name
   end
   def td?(name)
      /\A[Tt][Dd]\z/ =~ name
   end

   def get_td_data(td)
      td.each_child {|e|
         next if /\A\s*\Z/ =~ e.to_s
         case e.name
         when 'span'
            if e.has_elements?
               @@temp = ["Table", e.attributes["id"]]
               other_elements?(e)
            else
               @@td = Table::Sentence.new(e.text, e.attributes["id"])
               @@td.readid = @@td.totalid = @@td.arg
               @@sect.add_phrase(@@td)
            end
         when 'ruby'
            e.each_child {|r|
               next if "\n" == r.to_s
               case r.name
               when 'rb'
                  kanji = r.text
               when 'rt'
                  ruby = r.text
               end
            }
            @@modify << "@<ruby>{#{kanji},#{ruby}}"
         when 'br'
           if "span" == e.parent.name
              @@modify << "<br />"
           elsif "td" == e.parent.name
              @@sect.add_phrase(Break.new.null)
           end
         else
            get_td_data(e) if e.has_elements?
         end
      }
      @@first_td = @@td if 1 == @@num
   end

   def get_list_data(elm)
      elm.each_child {|e|
        if e.instance_of?(REXML::Text)
         next if /\A\s*\Z/ =~ e.to_s
            @@id += 1
            @@ld = Li::Sentence.new(e.to_s, "li#{@@id}")
            @@ld.readid = @@ld.totalid = @@li.arg
            @@sect.add_phrase(@@ld)
            if @@uol
               @@uol.ncxsrc = @@ld if @@uol.ncxsrc.nil?
            end
            next
        end
         case e.name
         when 'span'
            if e.has_elements?
               @@temp = ["Li", e.attributes["id"]]
               other_elements?(e)
            else
               @@ld = Li::Sentence.new(e.text, "li#{@@id}")
               @@ld.readid = @@ld.totalid = e.attributes["id"]
               @@sect.add_phrase(@@ld)
               if @@uol
                  @@uol.ncxsrc = @@ld if @@uol.ncxsrc.nil?
               end
            end
         when 'ruby'
            e.each_child {|r|
               next if "\n" == r.to_s
               case r.name
               when 'rb'
                  kanji = r.text
               when 'rt'
                  ruby = r.text
               end
            }
            @@modify << "@<ruby>{#{kanji},#{ruby}}"
         when 'br'
           @@sect.add_phrase(Break.new.null)
         else
            get_list_data(e) if e.has_elements?
         end
      }
   end

   def get_ncc_meta(elm)
      elm.each_element {|e|
         get_ncc_meta(e) if e.has_elements?
         unless e.attributes["name"].nil?
            case e.attributes["name"]
            when "dc:title"
               @meta.title = many_contents?(@meta.title, e)
            when "dc:creator"
               @meta.author = many_contents?(@meta.author, e)
            when "dc:contributor"
               @contributor = many_contents?(@contributor, e)
            when "dc:coverage"
               @meta.coverage = many_contents?(@meta.coverage, e)
            when "dc:date"
               @meta.date = e.attributes["content"]
            when "dc:format"
               @format = e.attributes["content"]
            when "dc:identifier"
               @identifier = e.attributes["content"]
            when "dc:language"
               @meta.language = e.attributes["content"]
            when "dc:publisher"
               @meta.publisher = many_contents?(@meta.publisher, e)
            when "dc:description"
               @meta.description = e.attributes["content"]
            when "dc:relation"
               @meta.relation = e.attributes["content"]
            when "dc:rights"
               @meta.rights = many_contens?(@meta.rights, e)
            when "dc:subject"
               @meta.subject = many_contents?(@meta.subject, e)
            when "dc:type"
               @meta.type = e.attributes["content"]
            when "dc:source"
               @meta.isbn = e.attributes["content"]
            when "ncc:sourceDate"
               @xmeta.sourceDate = e.attributes["content"]
            when "ncc:sourceEdition"
               @xmeta.sourceEdition = e.attributes["content"]
            when "ncc:sourcePublisher"
               @xmeta.sourcePublisher = e.attributes["content"]
            when "ncc:sourceRights"
               @xmeta.sourceRights = e.attributes["content"]
            when "ncc:sourceTitle"
               @xmeta.sourceTitle = e.attributes["content"]
            when "ncc:charset"
               @char_set = e.attributes["content"]
            when "ncc:setInfo"
               @set_info = e.attributes["content"]
            when "ncc:tocItems"
               @toc_items = e.attributes["content"]
            when "ncc:totalTime"
               @xmeta.totalTime = e.attributes["content"]
            when "ncc:depth"
               @depth = e.attributes["content"]
            when "ncc:narrator"
               @xmeta.narrator = many_contents?(@xmeta.narrator, e)
            when "ncc:files"
               @files = e.attributes["content"]
            when "ncc:generator"
               @generator = e.attributes["content"]
            when "ncc:kByteSize"
               @kbyte_size = e.attributes["content"]
            when "ncc:producer"
               @xmeta.producer = many_contents?(@xmeta.producer, e)
            when "ncc:revision"
               @xmeta.revision = e.attributes["content"]
            when "ncc:revisionDate"
               @xmeta.revisionDate = e.attributes["content"]
            when "ncc:producedDate"
               @xmeta.producedDate = e.attributes["content"]
            when "ncc:footnotes"
               @footnotes = e.attributes["content"]
               @skippable.note = "false" if "0" < @footnotes
            when "ncc:pageFront"
               @pageFront = e.attributes["content"]
               @skippable.front = "false" if "0" < @pageFront
            when "ncc:pageNormal"
               @pageNormal = e.attributes["content"]
               @skippable.normal = "false" if "0" < @pageNormal
            when "ncc:pageSpecial"
               @pageSpecial = e.attributes["content"]
               @skippable.special = "false" if "0" < @pageSpecial
            when "ncc:prodNotes"
               @prodNotes = e.attributes["content"]
               @skippable.prodnote = "false" if "0" < @prodNotes
            when "ncc:sidebars"
               @sidebars = e.attributes["content"]
               @skippable.sidebar = "false" if "0" < @sidebars
            when "ncc:maxPageNormal"
               @maxPageNormal = e.attributes["content"]
            end
         end
      }
   end

   def many_contents?(instance, element)
      if instance.nil?
         return element.attributes["content"]
      elsif instance.kind_of?(Array)
         return instance << element.attributes["content"]
      else
         array_i = ["#{instance}"]
         return array_i << element.attributes["content"]
      end
   end

   def get_ncc_body(elm)
      elm.each_element {|e|
         case e.name
         when /h[1-6]/
            @@nhp = Ncc::Headline.new
            get_first_data(@@nhp, e)
         when "span"
            @@nhp = Ncc::Page.new
            get_first_data(@@nhp, e)
         when "a"
            get_second_data(@@nhp, e)
            add_ncc(@@nhp)
         end
         get_ncc_body(e) if e.has_elements?
      }
   end

   def get_first_data(obj, elm)
      obj.tag = elm.name
      obj.tagClass = elm.attributes["class"]
      obj.id = elm.attributes["id"]
   end

   def get_second_data(obj, elm)
      obj.ref = elm.attributes["href"]
      obj.text = elm.text
   end

   def add_ncc(ncc)
      @ncc << ncc
   end

   def get_master_smil(elm)
      title = elm.attributes["title"]
      src = elm.attributes["src"]
      id = elm.attributes["id"]
      @masterSmils << Smil::Ref.new(title, src, id)
   end

   def print_err(mes)
      raise mes.encode("SJIS")
   end

   def time_add_time(times)
      hstr, mstr, sstr, msstr = [], [], [], []
      times.each {|t|
         if /\A(\d+):(\d\d):(\d\d)\.(\d\d\d)\z/ =~ t
            hstr << $1; mstr << $2; sstr << $3; msstr << $4
         end
      }
      h, m, s, ms = 0, 0, 0, 0
      msstr.each {|x| ms = ms + x.to_i }
      sstr.each {|x| s = s + x.to_i }
      mstr.each {|x| m = m + x.to_i }
      hstr.each {|x| h = h + x.to_i }
      if 999 < ms
         msa = ms.divmod(1000)
         s2 = msa[0]; ms = msa[1]
         s = s + s2
      end
      if ms.nil?
         ms = ".000"
      else
         zero = "0" * (3 - ms.to_s.size)
         ms = ".#{zero}#{ms}"
      end
      if 59 < s
         sa = s.divmod(60)
         m2 = sa[0]; s = sa[1]
         m = m + m2
      end
      if s.nil?
         s = "00"
      elsif 1 == s.to_s.size
         s = "0#{s}"
      end
      if 59 < m
         ma = m.divmod(60)
         h2 = ma[0]; m = ma[1]
         h = h + h2
      end
      if m.nil?
         m = "00"
      elsif 1 == m.to_s.size
         m = "0#{m}"
      end
      return "#{h}:#{m}:#{s}#{ms}"
   end

   def set_par_audio(phr)
      if @audios[phr.readid]
         src = @audios[phr.readid].src.sub(/npt=/, "")
         cBegin = @audios[phr.readid].clipBegin.sub(/npt=/, "")
         cEnd = @audios[phr.readid].clipEnd.sub(/npt=/, "")
         return src, cBegin, cEnd
      end
   end

   def read_time_in_this_smil(timeValue)
      if /\A\d+:\d\d:\d\d\.\d+\z/ =~ timeValue
         time = timeValue
      elsif /\A\d\d:\d\d\.\d+\z/ =~ timeValue
         time = set_time_partial_to_full(timeValue)
      elsif /\A\d+\.\d+(h|m|s)\z/ =~ timeValue
         time = set_time_count_to_full(timeValue, $1)
      elsif /\A\d+(ms)\z/ =~ timeValue
         time = set_time_count_to_full(timeValue, $1)
      else
         return [-1, "時間表記が正しくないようです"]
      end
      return time
   end

   def set_time_partial_to_full(dur)
      "0:#{dur}"
   end

   def set_time_count_to_full(dur, unit)
      case unit
      when 'h'
         h, m, s, ms = calc_h(dur.sub(/h/, ""))
      when 'm'
         h, m, s, ms = calc_m(dur.sub(/m/, ""))
      when 's'
         h, m, s, ms = calc_s(dur.sub(/s/, ""))
      when 'ms'
         h, m, s, ms = calc_ms(dur.sub(/ms/, ""))
      end
      h = "0" if h.nil?
      m = "00" if m.nil?
      s = "00" if s.nil?
      ms = ".000" if ms.nil?
      m = "0#{m}" if 1 == m.to_s.size
      s = "0#{s}" if 1 == s.to_s.size
      return "#{h}:#{m}:#{s}#{ms}"
   end

   def calc_h(fig)
      h1 = fig.to_i
      hf = fig.to_f
      dotM = hf - h1.to_f
      mf = 60 * dotM
      h2, m, s, ms = calc_m(mf) unless mf.integer?
      h2.nil? ? h = h1 : h = h1 + h2
      return h, m, s, ms
   end

   def calc_m(fig)
      m1 = fig.to_i
      dotS = fig.to_f - m1.to_f
      sf = 60 * dotS
      h, m2, s, ms = calc_s(sf) unless sf.integer?
      m2.nil? ? m = m1 : m = m1 + m2
      if 59 < m
         ma = m.divmod(60)
         h = h + ma[0]; m = ma[1]
      end
      return h, m, s, ms
   end

   def calc_s(fig)
      s = fig.to_i
      dotMS = $1 if /(\.\d+)\z/ =~ fig
      if 59 < s
         sa = s.divmod(60)
         m = sa[0]; s = sa[1]
      end
      unless m.nil?
         if 59 < m
            ma = m.divmod(60)
            h = ma[0]; m = ma[1]
         end
      end
      return h, m, s, dotMS
   end

   def calc_ms(fig)
      ms = fig.to_i
      if 999 < ms
         msa = ms.divmod(1000)
         s = msa[0]
         zero = "0" * (3 - msa[1].to_s.size)
         ms = ".#{zero}#{msa[1]}"
      end
      unless s.nil?
         if 59 < s
            sa = s.divmod(60)
            m = sa[0]; s = sa[1]
         end
      end
      unless m.nil?
         if 59 < m
            ma = m.divmod(60)
            h = ma[0]; m = ma[1]
         end
      end
      return h, m, s, ms
   end
end

class Ncc
   def initialize
      @tag, @tagClass, @id, @ref, @text = nil, nil, nil, nil, nil
   end
   attr_accessor :tag, :tagClass, :id, :ref, :text

   class Headline < Ncc
      def initialize
         super
      end
   end
   class Page < Ncc
      def initialize
         super
      end
   end
end

class Smil
   class Ref < Smil
      def initialize(title, src, id)
         @title = title
         @src = src
         @id = id
      end
      attr_accessor :title, :src, :id
   end
   class Seq < Smil
      def initialize(dur = nil)
         @dur = dur
         @item = []
      end
      attr_accessor :dur, :item
   end
   class Par < Smil
      def initialize(endsync = nil)
         @text = nil
         @audio = nil
      end
      attr_accessor :endsync, :item, :text, :audio
   end
   class Text < Smil
      def initialize(src, id)
         @src = src
         @id = id
      end
      attr_accessor :src, :id
   end
   class Audio < Smil
      def initialize(src, clipBegin, clipEnd, id)
         @src = src
         @clipBegin = clipBegin
         @clipEnd = clipEnd
         @id = id
      end
      attr_accessor :src, :clipBegin, :clipEnd, :id
   end
end

