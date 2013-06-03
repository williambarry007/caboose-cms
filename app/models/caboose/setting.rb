
class Caboose::Setting < ActiveRecord::Base
  self.table_name = "settings"
  attr_accessible :name, :value
end
