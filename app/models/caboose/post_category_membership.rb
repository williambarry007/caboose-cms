
class Caboose::PostCategoryMembership < ActiveRecord::Base
  self.table_name = "post_category_memberships"
  
  belongs_to :post_category
  belongs_to :post
  attr_accessible :post_id, :post_category_id

end
