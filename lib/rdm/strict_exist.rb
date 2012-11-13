# encoding: utf-8
#
# Copyright (c) 2012 Kishida Atsushi
#
class File
   def self.strict_exist?(file)
      @@dskname = nil
      dirname = File.dirname(file)
      entries = collect_current_file_list(dirname)
      result = entries.find {|f| File.fnmatch(f, file) }
      unless result
         @@dskname = entries.find {|f| File.fnmatch(f, file, File::FNM_CASEFOLD) }
      end
      return true if result
      return false
   end

   def self.strict_exist_name?(file)
      strict_exist?(file)
      return @@dskname if @@dskname
      return false
   end

   private

   def self.collect_current_file_list(path)
      entries = Dir.entries(path).find_all{|f| File.file?("#{path}/#{f}")}
      unless '.' == path
         entries.each_index {|i| entries[i] = "#{path}/#{entries[i]}" }
      end
      return entries
   end
end
