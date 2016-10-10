module Caboose
  class Calendar < ActiveRecord::Base
    self.table_name = "calendars"
    has_many :calendar_events, :dependent => :destroy  
    attr_accessible :id, :site_id, :name, :description, :color, :timezone
  end
end
