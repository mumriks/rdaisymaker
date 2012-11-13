# encoding: utf-8
# Copyright (c) 2011, 2012 Kishida Atsushi

class RDM
   def table_header(th, row, column)
      row = row + 1
      @theader = {}
      case th
      when /-+/
         table_header_column(column)
      when /\|+/
         table_header_row(column, row)
      when /\++/
         table_header_column(column)
         table_header_row(column, row)
      end
      return table
   end

   def get_table_structure(phr)
      row = phr.size
      column = 0
      table, t = [], []
      th = ''
      phr.each {|r|
         valid_syntax_at_table?(r) if r.kind_of?(Array)
         t = r.split(/\s/)
         if /[-\|\+]+/ =~ t.to_s
            th = t[0].to_s
            row = row - 1
         else
            table << t
         end
         column = t.size if column < t.size
      }
      return th, row, column, table
   end

   def table_header_column(column)
      (1..column).each {|n|
         @theader["#{n}"] = 'th'
      }
   end

   def table_header_row(column, row)
      1.step(row * (column - 1), column) {|n|
         @theader["#{n}"] = 'th'
      }
   end

   def table_tag(num)
      if @theader["#{num}"] == 'th'
         return 'Th'
      else
         return 'Td'
      end
   end

   def make_table_caption(args)
      tc = make_sentence(args[1], 'Table::Caption', args[0])
      @first_sentence = tc if @first_sentence.nil?
      return tc
   end

   def make_table_cell(tag, phr)
      objs = []
      objs << eval("#{tag}.new")
      ts = make_sentence(phr, 'Table::Sentence')
      objs << ts
      @first_sentence = ts if @first_sentence.nil?
      objs << eval("#{tag}.new.post")
      return objs, ts
   end

   def valid_syntax_at_table?(phr)
      phr.flatten!
      mes = "#{phr[0].class}はtableタグの外においてください。\n#{File.basename(@file)} line:#{@lineno}"
      print_error(mes)
   end

   def not_table_data(args)
      mes = "テーブルのデータがありません :  //table#{args}\n#{File.basename(@file)} line:#{@lineno}"
      print_error(mes)
   end
end
