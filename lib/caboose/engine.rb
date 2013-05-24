module Caboose
  
  def Caboose.log(message, title = nil)
    Rails.logger.debug("\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    Rails.logger.debug(title.to_s) unless title.nil?
    Rails.logger.debug(message)
    Rails.logger.debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n")    
  end
  
  def Caboose.plugin_hook(tag, args = nil)
    Caboose.plugins.each do |mod|
      func = "#{tag}_hook"  
      if (mod.constantize.respond_to?(func))
        args = mod.constantize.send(func.to_sym, args)
      end
      #args = mod.send(func.to_sym, args)
    end
    return args
  end
  
  class Engine < ::Rails::Engine
    isolate_namespace Caboose    
  end
end
