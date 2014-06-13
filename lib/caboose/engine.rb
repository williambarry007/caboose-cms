
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
  
  def Caboose.json(obj, defaultvalue = "", options = {})
    return defaultvalue.to_json if obj.nil?
    return obj.to_json(options)
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
    require 'jquery-rails'    
    initializer 'caboose.assets.precompile' do |app|            
      app.config.assets.precompile += [      
        # Images
        'caboose/caboose_logo_small.png',
        'caboose/caboose_nav_black.png',
        'caboose/caboose_nav.png',
        'caboose/default_user_pic.png',
        'caboose/loading_black_on_white.gif',
        'caboose/loading_green.gif',
        'caboose/loading_small_black_on_white.gif',
        'caboose/loading_small_white_on_black.gif',
        'caboose/loading_white_on_black.gif',
        'caboose/search.png',
        # Javascript
        'caboose/admin_page_edit_content.js',
        'caboose/admin_page_new_blocks.js',
        'caboose/admin.js',
        'caboose/application.js',
        'caboose/modal_integration.js',
        'caboose/modal.js',
        'caboose/model/all.js',
        'caboose/model/attribute.js',
        'caboose/model/bound_checkbox_multiple.js',
        'caboose/model/bound_checkbox.js',
        'caboose/model/bound_control.js',
        'caboose/model/bound_image.js',
        'caboose/model/bound_richtext.js',
        'caboose/model/bound_select.js',
        'caboose/model/bound_text.js',
        'caboose/model/bound_textarea.js',
        'caboose/model/class.js',
        'caboose/model/model_binder.js',
        'caboose/model/model.js',
        'caboose/model.form.page.js',
        'caboose/model.form.user.js',
        'caboose/placeholder.js',
        'caboose/shortcut.js',
        'caboose/station.js',
        'caboose/tinymce/plugins/caboose/plugin.js',
        # CSS
        'caboose/admin_page_edit_content.css',
        'caboose/admin.css',
        'caboose/application.css',
        'caboose/bound_input.css',
        'caboose/caboose.css',
        'caboose/fonts/big_noodle_titling_oblique.ttf',
        'caboose/fonts/big_noodle_titling.ttf',
        'caboose/fonts.css',
        'caboose/login.css',
        'caboose/modal.css',
        'caboose/page_bar_generator.css',
        'caboose/register.css',
        'caboose/station_modal.css',
        'caboose/station_sidebar.css',
        'caboose/tinymce.css'
      ]      
    end   
  end
end
