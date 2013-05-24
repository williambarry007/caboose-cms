
class Caboose::PagePermission < ActiveRecord::Base
  self.table_name = "page_permissions"
  belongs_to :page
  belongs_to :role   
  attr_accessible :page_id, :role_id, :action
end
