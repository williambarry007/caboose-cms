module Caboose
  class RetargetingConfig < ActiveRecord::Base
    self.table_name = "retargeting_configs"

    belongs_to :site
    attr_accessible :id,
      :site_id,
      :conversion_id,      
      :labels_function,
      :fb_pixels_function
    
    def labels(request, page)
      return [] if self.labels_function.nil? || self.labels_function.strip.length == 0      
      return [self.labels_function] if self.labels_function.starts_with?('_')        
      arr = eval(self.labels_function)      
      return [] if arr.nil?
      return [arr] if arr is_a? String
      return arr        
    end
    
    def fb_pixels(request, page)
      return [] if self.fb_pixels_function.nil? || self.fb_pixels_function.strip.length == 0
      arr = eval(self.fb_pixels_function)
      return [] if arr.nil?
      return [arr] if arr.is_a?(String) || arr.is_a?(Integer)
      return arr        
    end
    
  end  
end
