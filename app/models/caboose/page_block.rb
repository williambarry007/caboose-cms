
class Caboose::PageBlock < ActiveRecord::Base
  self.table_name = "page_blocks"
  
  belongs_to :page  
  attr_accessible :id, :page_id, :type, :sort_order, :value    

end
