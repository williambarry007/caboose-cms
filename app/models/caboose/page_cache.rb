module Caboose
  class PageCache < ActiveRecord::Base
    self.table_name = "page_cache"
    
    belongs_to :page
    attr_accessible :id,
      :page_id,
      :render_function,
      :block      
        
  end
end
