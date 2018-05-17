module Caboose
  class CalendarEventGroup < ActiveRecord::Base    
    self.table_name = "calendar_event_groups"
    
    has_many :calendar_events      
    attr_accessible :id ,
      :period        , # Daily, weekly, monthly, or yearly
      :frequency     , 
      :repeat_by     , # Used for monthly repeats
      :sun           ,
      :mon           ,
      :tue           ,
      :wed           ,
      :thu           ,
      :fri           ,
      :sat           ,
      :date_start    ,
      :repeat_count  , # How many times the repeat occurs
      :date_end
     
    PERIOD_DAY   = 'Day'
    PERIOD_WEEK  = 'Week'
    PERIOD_MONTH = 'Month'
    PERIOD_YEAR  = 'Year'

    REPEAT_BY_DAY_OF_MONTH = 'Day of month'
    REPEAT_BY_DAY_OF_WEEK  = 'Day of week'
    
    def create_events      
      return if self.date_start.nil?      
      return if self.date_end.nil?      
      return if self.date_end < self.date_start      
      
      e = self.calendar_events.reorder(:begin_date).first      
      return if e.nil?
      
      dates = [e.begin_date.to_date]
      if self.period == 'Day'
        d = self.date_start
        while d <= self.date_end
          if !CalendarEvent.where("calendar_event_group_id = ? and cast(begin_date as date) = ?", self.id, d).exists?
            e.duplicate(d)
          end
          dates << d.to_date
          d = d + 1.day
        end
        
      elsif self.period == 'Week'
                
        d = self.date_start - self.date_start.strftime('%w').to_i.days
        while d <= self.date_end          
          (0..6).each do |i|            
            d = d + 1
            Caboose.log("d = #{d}")
            next if d < self.date_start
            break if d > self.date_end
            w = d.strftime('%w').to_i
            if (w == 0 && self.sun) || (w == 1 && self.mon) || (w == 2 && self.tue) || (w == 3 && self.wed) || (w == 4 && self.thu) || (w == 5 && self.fri) || (w == 6 && self.sat)
              Caboose.log("Found a day")
              if !CalendarEvent.where("calendar_event_group_id = ? and cast(begin_date as date) = ?", self.id, d).exists?
                e.duplicate(d)
              end
              dates << d.to_date
            end
          end
          d = d + (self.frequency-1).weeks
        end
        
      elsif self.period == 'Month'
        d = self.date_start
        if self.repeat_by == 'Day of month'     
          while d <= self.date_end           
            if !CalendarEvent.where("calendar_event_group_id = ? and cast(begin_date as date) = ?", self.id, d).exists?
              e.duplicate(d)
            end
            dates << d.to_date
            d = d + self.frequency.months  
          end
        elsif self.repeat_by == self::REPEAT_BY_DAY_OF_WEEK
          
          #d0 = DateTime.new(d.strftime('%Y'), d.strftime('%m'), 1)
          #w = d0.strftime('%w').to_i
          #i = 0
          #while d0 <= d
          #  i = i + 1 if d0.strftime('%w').to_i == w
          #  d0 = d0 + 1.day
          #end
          #
          ## Now set the i'th occurance of the w day of the week           
          #d = DateTime.new(d.strftime('%Y'), d.strftime('%m'), 1)
          #while d <= self.date_end
          #  d0 = d
          #  while d
          #    
          #    
          #  if !CalendarEvent.where("calendar_event_group_id = ? and cast(begin_date as date) = ?", self.id, d).exists?
          #    CalendarEvent.duplicate(d)
          #  end
          #  d = d + self.frequency.months  
          #end
          
        end
        
      elsif self.period == 'Year'
        d = self.date_start
        while d <= self.date_end
          if !CalendarEvent.where("calendar_event_group_id = ? and cast(begin_date as date) = ?", self.id, d).exists?
            e.duplicate(d)
          end
          dates << d.to_date
          d = d + 1.year
        end
        
      end
      
      # Get rid of events that shouldn't be in the group            
      CalendarEvent.where("calendar_event_group_id = ? and cast(begin_date as date) not in (?)", self.id, dates).destroy_all
                  
    end    
  end
end
