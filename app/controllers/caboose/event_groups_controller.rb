
module Caboose
  class EventGroupsController < ApplicationController
    
    helper :application
    
    # PUT /admin/calendars/:calendar_id/event-groups/:id
    def admin_update
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new
      g = CalendarEventGroup.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name
          when 'frequency'    then g.frequency    = value
          when 'period'       then g.period       = value        
          when 'repeat_by'    then g.repeat_by    = value
          when 'sun'          then g.sun          = value
          when 'mon'          then g.mon          = value
          when 'tue'          then g.tue          = value
          when 'wed'          then g.wed          = value
          when 'thu'          then g.thu          = value
          when 'fri'          then g.fri          = value
          when 'sat'          then g.sat          = value
          when 'date_start'   then g.date_start   = DateTime.strptime(value, '%m/%d/%Y').to_date
          when 'repeat_count' then g.repeat_count = value
          when 'date_end'     then g.date_end     = DateTime.strptime(value, '%m/%d/%Y').to_date                                      
        end
      end
      g.save
      g.create_events
    
      resp.success = true
      render :json => resp
    end
     
    # GET /admin/event-groups/period-options
    def admin_period_options
      render :json => [
        { 'value' => CalendarEventGroup::PERIOD_DAY   , 'text' => CalendarEventGroup::PERIOD_DAY   },
        { 'value' => CalendarEventGroup::PERIOD_WEEK  , 'text' => CalendarEventGroup::PERIOD_WEEK  },
        { 'value' => CalendarEventGroup::PERIOD_MONTH , 'text' => CalendarEventGroup::PERIOD_MONTH },
        { 'value' => CalendarEventGroup::PERIOD_YEAR  , 'text' => CalendarEventGroup::PERIOD_YEAR  },
      ]
    end
    
    # GET /admin/event-groups/frequency-options
    def admin_frequency_options
      arr = (1..30).collect{ |i| { 'value' => i, 'text' => i }}
      render :json => arr        
    end
    
    # GET /admin/event-groups/repeat-by-options
    def admin_repeat_by_options
      render :json => [        
        { 'value' => CalendarEventGroup::REPEAT_BY_DAY_OF_MONTH , 'text' => 'same day of the month' },
        { 'value' => CalendarEventGroup::REPEAT_BY_DAY_OF_WEEK  , 'text' => 'same day of the week' },        
      ]
    end
    
  end
end
