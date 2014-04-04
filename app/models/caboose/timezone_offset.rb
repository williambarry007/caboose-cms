class Caboose::TimezoneOffset < ActiveRecord::Base
  self.table_name = "timezone_offsets"
  belongs_to :timezone
  attr_accessible :id, :timezone_id, :abbreviation, :time_start, :gmt_offset, :dst
end