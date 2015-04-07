module Caboose
  class RetargetingConfig < ActiveRecord::Base
    self.table_name = "retargeting_configs"

    belongs_to :site
    attr_accessible :id,
      :site_id,
      :conversion_id,      
      :labels_function
    
    def labels(request, page)          
      arr = eval(self.labels_function)
      return [arr] if arr is_a? String
      return arr        
    end
    
  end  
end
