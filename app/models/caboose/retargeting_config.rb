module Caboose
  class RetargetingConfig < ActiveRecord::Base
    self.table_name = "retargeting_configs"

    belongs_to :site
    attr_accessible :id,
      :site_id,
      :google_conversion_id,      
      :google_labels_function,
      :fb_pixel_id,
      :fb_vars_function
      #:fb_access_token,
      #:fb_access_token_expires
    
    def google_labels(request, page)
      return [] if self.google_labels_function.nil? || self.google_labels_function.strip.length == 0      
      return [self.google_labels_function] if self.google_labels_function.starts_with?('_')        
      arr = eval(self.google_labels_function)      
      return [] if arr.nil?
      return [arr] if arr is_a? String
      return arr        
    end
    
    def fb_vars(request, page)
      return [] if self.fb_vars_function.nil? || self.fb_vars_function.strip.length == 0      
      arr = eval(self.fb_vars_function)      
      return [] if arr.nil?
      return [arr] if arr is_a? String
      return arr        
    end
    
  end  
end
