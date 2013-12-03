
require 'tinymce-rails'
require 'jquery-ui-rails'
require 'colorbox-rails'
require 'paperclip'

class ActiveRecord::Base
  # (PLU)cks a single uni(Q)ue field
  def self.pluq(field, compact = true, sort = true)    
    arr = self.uniq.pluck(field)
    return [] if arr.nil?
    arr = arr.compact if compact
    arr = arr.sort if sort
    return arr
  end  
end

module Caboose

  def Caboose.log(message, title = nil)
    if (Rails.logger.nil?)
      puts "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      puts title.to_s unless title.nil?
      puts message
      puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
    else
      Rails.logger.debug("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
      Rails.logger.debug(title.to_s) unless title.nil?
      Rails.logger.debug(message)
      Rails.logger.debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n")
    end
  end
  
  def Caboose.plugin_hook(*args)
    resp = nil
    args[0] = args[0].to_sym 
    Caboose.plugins.each do |mod|
      #resp = mod.constantize.send(*args)
      if (mod.constantize.respond_to?(args[0]))
        resp = mod.constantize.send(*args)
      end
    end
    return resp
  end
  
  def Caboose.json(obj, defaultvalue = "")
    return defaultvalue.to_json if obj.nil?
    return obj.to_json
  end
  
  # Verifies (non-destructively) that the given schema exists in the database.
  def Caboose.create_schema(schema)
    c = ActiveRecord::Base.connection
    schema.each do |model, columns|
      tbl = model.table_name
      c.create_table tbl if !c.table_exists?(tbl)
      columns.each do |col|        
        
        # Skip if the column exists with the proper data type
        next if c.column_exists?(tbl, col[0], col[1])
        
        # If the column doesn't exists, add it
        if !c.column_exists?(tbl, col[0])
          if col.count > 2                      
            c.add_column tbl, col[0], col[1], col[2]
          else          
            c.add_column tbl, col[0], col[1] 
          end
          
        # Column exists, but not with the correct data type, try to change it
        else
          
          # Add a temp column
          if col.count > 2
            c.add_column tbl, "#{col[0]}_temp", col[1], col[2]
          else
            c.add_column tbl, "#{col[0]}_temp", col[1]
          end
          
          # Copy the old column and cast with correct data type to the new column
          model.all.each do |m|            
            m["#{col[0]}_temp"] = case col[1]
              when :integer  then m[col[0]].to_i
              when :string   then m[col[0]].to_s
              when :text     then m[col[0]].to_s
              when :numeric  then m[col[0]].to_f
              when :datetime then DateTime.parse(m[col[0]])
              when :boolean  then m[col[0]].to_i == 1
              else nil
              end
            m.save
          end
          
          # Remove the old column and rename the new one
          c.remove_column tbl, col[0]
          c.rename_column tbl, "#{col[0]}_temp", col[0]        

        end
      end
    end
  end
  
  # Strips html and returns the text that breaks closest to the given length
  def Caboose.teaser_text(str, length = 100)
    return "" if str.nil?    
    str2 = ActionController::Base.helpers.strip_tags(str)
    if str2.length > 200
      i = str2.index(' ', 200) - 1
      i = 200 if i.nil?
      str2 = str2[0..i]
      str2[str2.length-1] = "" if str2.ends_with?(",")
      str2 = "#{str2}..."
    end
    return str2
  end
  
  class Engine < ::Rails::Engine
    isolate_namespace Caboose
  end
end
