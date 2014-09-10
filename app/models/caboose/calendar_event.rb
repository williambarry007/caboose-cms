module Caboose
  class CalendarEvent < ActiveRecord::Base    
    self.table_name = "calendar_events"
    
    belongs_to :calendar
    belongs_to :calendar_event_group
    attr_accessible :id        ,
      :calendar_id             ,
      :calendar_event_group_id , 
      :name                    ,
      :description             ,
      :location                ,
      :begin_date              ,
      :end_date                ,
      :all_day        

    def self.events_for_day(calendar_id, d)
      q = ["calendar_id = ? 
        and concat(date_part('year', begin_date),date_part('month', begin_date),date_part('day', begin_date)) <= ?
        and concat(date_part('year', end_date  ),date_part('month', end_date  ),date_part('day', end_date  )) >= ?",
        calendar_id, d.strftime('%Y%m%d'), d.strftime('%Y%m%d')]
      self.where(q).reorder(:begin_date).all
    end

  end
end
