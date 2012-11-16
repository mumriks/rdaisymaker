# encoding: utf-8
# Copyright (c) 2011, 2012 Kishida Atsushi

class RDM
   def make_image(mes, image, args)
      where = "\n#{File.basename(@file)} line:#{@lineno}"
      @imgcount += 1
      @imgids = @imgids + "#{args[0]}-#{@imgcount} "
      if  /errmes[1-3]/ =~ mes
         print_error(Daisy::ERRMES["#{mes}"] + image + where)
      elsif 'errmes4' == mes
         @big_image << image
         i = Image.new(image, "#{args[0]}-#{@imgcount}")
      else
         i = Image.new(image, "#{args[0]}-#{@imgcount}")
      end
      @tagids["#{args[0]}-#{@imgcount}"] << ["#{File.basename(@file)} - line:#{@lineno}", i]
      return i
   end

   def image_group_set(sw, args)
      ig = ImageGroup.new(args)
      eval ("ig.#{sw}")
      return ig
   end

   def make_image_group(group, args)
      objs = []
      caption = nil
      objs << image_group_set("start", args[0]) if group.size > 1 or args[1]
      group.each {|obj|
         if obj.instance_of?(Image)
            @imgcount -= 1
            obj.ref = @imgids.rstrip
            objs << obj
            if @imgcount == 0 and args[1]
               caption = make_sentence(args[1], 'Image::Caption')
               caption.ref = @imgids.rstrip
            end
         else
            objs << obj
         end
      }
      if caption
         objs << caption
         caption = nil
      end
      objs << image_group_set("finish", args[0]) if group.size > 1 or args[1]
      @imgids = ''
      return objs
   end

   def valid_syntax_at_image?(phr)
      phr.flatten!
      if phr[0].instance_of?(Prodnote)
         return true
      else
         mes = "#{phr[0].class}はimageタグの外においてください。\n#{File.basename(@file)} line:#{@lineno}"
         print_error(mes)
      end
   end

   def not_page_in_image
      mes = "ページ数はimageブロックの外で使うようにしてください。\n#{File.basename(@file)} line:#{@lineno}"
      print_error(mes)
   end

   def invalid_phrase_in_image(phr)
      mes = "判別できないフレーズです。\n#{File.basename(@file)} line:#{@lineno}: #{phr}"
      print_error(mes)
   end
end
