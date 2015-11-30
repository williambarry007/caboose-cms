
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
      Rails.logger.info("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
      Rails.logger.info(title.to_s) unless title.nil?
      Rails.logger.info(message)
      Rails.logger.info(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n")
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
    return '' if str.nil?    
    str2 = ActionController::Base.helpers.strip_tags(str).gsub("\n", ' ')
    return '' if str2.nil? || str2.length == 0
    if str2.length > length
      i = str2.index(' ', length)
      if i.nil?
        i = length
      else
        i = i - 1
      end
      str2 = str2[0..i]
      str2[str2.length-1] = "" if str2.ends_with?(",")
      str2 = "#{str2}..."
    end
    return str2
  end
  
  def Caboose.random_string(length)
    o = [('a'..'z'),('A'..'Z'),('0'..'9')].map { |i| i.to_a }.flatten
    return (0...length).map { o[rand(o.length)] }.join
  end

  class Engine < ::Rails::Engine
    isolate_namespace Caboose
    require 'jquery-rails'    
    initializer 'caboose.assets.precompile' do |app|            
      app.config.assets.precompile += [      
        
        # Images
        'caboose/*.png',
        'caboose/*.gif',        
        
        # Javascript
        'caboose/*.js',        
        'caboose/model/*.js',        
        'jquery.js',
        'jquery_ujs.js',
        'jquery-ui.js',
        'colorbox-rails.js',
        'colorbox-rails/jquery.colorbox-min.js',
        'colorbox-rails/colorbox-links.js',                
        'tinymce/preinit.js',
        'tinymce/plugins/caboose/plugin.js',
        'tinymce/themes/modern/theme.js',
        'tinymce/plugins/*/plugin.js',
        '*/js/application.js', # Site JS

        # CSS   
        'caboose/*.css',
        'caboose/admin_crumbtrail.css',
        'caboose/admin_images_index.css',                        
        'caboose/cart.css',
        'caboose/checkout.css',        
        'caboose/message_boxes.css',
        'caboose/my_account_edit_order.css',
        'caboose/product_images.css',
        'caboose/product_options.css',                        
        'colorbox-rails.css',        
        'colorbox-rails/colorbox-rails.css',
        'jquery-ui.css',                
        '*/css/application.css', # Site CSS
        
        # PLUpload        
        'plupload/i18n/*.js',
        'plupload/jquery.plupload.queue/css/*.css',
        'plupload/jquery.plupload.queue/img/*.gif',
        'plupload/jquery.plupload.queue/img/*.png',
        'plupload/jquery.plupload.queue/*.js',
        'plupload/jquery.ui.plupload/css/*.css',
        'plupload/jquery.ui.plupload/img/*.gif',
        'plupload/jquery.ui.plupload/img/*.png',
        'plupload/jquery.ui.plupload/*.js',
        'plupload/*.js',
        'plupload/*.swf',
        'plupload/*.xap',        

        # Fonts
        'caboose/fonts/avenir-medium.eot',
        'caboose/fonts/avenir-medium.ttf',
        'caboose/fonts/big_noodle_titling_oblique.ttf',
        'caboose/fonts/big_noodle_titling.ttf',               
        'caboose/icons.txt'
        
      ]      
    end
    
    # Configure rspec
    config.generators do |g|
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false        
    end
    
  end
end
    
#initializer 'caboose_store.payment_processor', :after => :finish_hook do |app|
#  case Caboose::payment_processor
#    when 'authorize.net'
#      Caboose::PaymentProcessor = Caboose::PaymentProcessors::Authorizenet
#    when 'payscape'
#      Caboose::PaymentProcessor = Caboose::PaymentProcessors::Payscape
#  end
#end
#
#initializer 'caboose_store.cart', :after => :finish_hook do |app|
#  ActiveSupport.on_load(:action_controller) do
#    include Caboose::BootStrapper
#  end
#  
#  Caboose::User.class_eval do
#    self.primary_key = :id
#  end
#end
