class Caboose::BlockTypeSiteMembership < ActiveRecord::Base
  self.table_name = "block_type_site_memberships"
  belongs_to :site
  belongs_to :block_type  
  attr_accessible :id, :site_id, :block_type_id, :custom_css, :custom_html 
end
