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
      :all_day                 ,
      :repeats

    def self.events_for_day(calendar_id, d)
      q = ["calendar_id = ? 
        and cast(begin_date as date) <= ?
        and cast(end_date   as date) >= ?",
        calendar_id, d.to_date, d.to_date]
      self.where(q).reorder(:begin_date).all
    end
    
    def duplicate(d)
      e = CalendarEvent.create(        
        :calendar_id             => self.calendar_id,
        :calendar_event_group_id => self.calendar_event_group_id,
        :name                    => self.name,
        :description             => self.description,
        :location                => self.location,
        :begin_date              => d,
        :end_date                => d + (self.end_date - self.begin_date).seconds,
        :all_day                 => self.all_day,
        :repeats                 => self.repeats
      )
      return e
    end

  end
end
