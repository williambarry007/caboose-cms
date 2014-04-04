
class Caboose::TimezoneAbbreviation < ActiveRecord::Base
  self.table_name = "timezone_abbreviations" 
  attr_accessible :id, :abbreviation, :name      
end
