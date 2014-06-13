
class Caboose::BlockTypeCategory < ActiveRecord::Base
  self.table_name = "block_type_categories"

  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockTypeCategory'  
  has_many :children, :foreign_key => 'parent_id', :class_name => 'Caboose::BlockTypeCategory', :dependent => :destroy
  has_many :block_types
  attr_accessible :id,
    :parent_id,
    :name 

end
