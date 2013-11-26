
require 'tinymce-rails'
require 'jquery-ui-rails'
#require 'modeljs'
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
  
  def Caboose.create_schema(schema_file)
    c = ActiveRecord::Base.connection
    require schema_file    
    @schema.each do |table, columns|
      c.create_table table if !c.table_exists?(table)
      columns.each do |col|
        
        # Skip if the column exists with the proper data type
        next if c.column_exists?(table, col[0], col[1])
        
        # If the column exists, but not with the correct data type, try to change it
        if c.column_exists?(table, col[0])
          if col.count > 2                      
            c.change_column table, col[0], col[1], col[2]
          else          
            c.change_column table, col[0], col[1] 
          end
        else                  
          if col.count > 2                      
            c.add_column table, col[0], col[1], col[2]
          else          
            c.add_column table, col[0], col[1] 
          end
        end
      end
    end
  end
  
  class Engine < ::Rails::Engine
    isolate_namespace Caboose
  end
end
