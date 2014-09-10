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
    
  end
end
