
class Caboose::PostCategory < ActiveRecord::Base
  self.table_name = "post_categories"
  
  has_many :post_category_memberships
  has_many :posts, :through => :post_category_memberships
    
  attr_accessible :id, :site_id, :name 

end
