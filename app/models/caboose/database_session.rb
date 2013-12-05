
class Caboose::DatabaseSession < ActiveRecord::Base
  self.table_name = "sessions"
  attr_accessible :session_id, :data, :created_at, :updated_at	
end
