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
    
    def self.events_for_month(calendar_id, month, year)
      d1 = Date.new(year.to_i, month.to_i, 1)
      d2 = d1 + 1.month              
      q = ["calendar_id = ? and cast(begin_date as date) <= ? and cast(end_date as date) >= ?", calendar_id, d2, d1]
      self.where(q).reorder(:begin_date).all
      
      #q = ["calendar_id = ? 
      #  and (
      #    (cast(begin_date as date) <= d1 and cast(begin_date as date) <= d2 and cast(end_date as date) >= d1 and cast(end_date as date) >= d2) or
      #    (cast(begin_date as date) <= d1 and cast(begin_date as date) <= d2 and cast(end_date as date) >= d1 and cast(end_date as date) <= d2) or
      #    (cast(begin_date as date) >= d1 and cast(begin_date as date) <= d2 and cast(end_date as date) >= d1 and cast(end_date as date) <= d2) or
      #    (cast(begin_date as date) >= d1 and cast(begin_date as date) <= d2 and cast(end_date as date) >= d1 and cast(end_date as date) >= d2)          
      #  )", calendar_id, d1, d2, d1, d2, d1, d2, d1, d2, d1, d2, d1, d2, d1, d2, d1, d2]
    end
    
    def duplicate(d)
      d2 = d + (self.end_date - self.begin_date).seconds
      e = CalendarEvent.create(        
        :calendar_id             => self.calendar_id,
        :calendar_event_group_id => self.calendar_event_group_id,
        :name                    => self.name,
        :description             => self.description,
        :location                => self.location,
        :begin_date              => DateTime.parse("#{d.strftime('%F')}T#{self.begin_date.strftime('%T%:z')}"),                              
        :end_date                => DateTime.parse("#{d2.strftime('%F')}T#{self.end_date.strftime('%T%:z')}"),
        :all_day                 => self.all_day,
        :repeats                 => self.repeats
      )
      return e
    end

  end
end
