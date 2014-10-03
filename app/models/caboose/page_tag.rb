class Caboose::PageTag < ActiveRecord::Base
  self.table_name = "page_tags"       
  belongs_to :page  
  attr_accessible :id, :page_id, :tag  
end
