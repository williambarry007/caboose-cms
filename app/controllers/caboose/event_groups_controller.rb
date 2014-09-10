
module Caboose
  class EventGroupsController < ApplicationController
    
    helper :application
    
    # GET /admin/calendars/:calendar_id/events/:id
    def admin_edit
      return unless user_is_allowed('calendars', 'edit')
      @event = CalendarEvent.find(params[:id])      
      render :layout => 'caboose/modal'
    end
    
    # GET /admin/calendars/:calendar_id/events/new
    def admin_new
      return unless user_is_allowed('calendars', 'edit')
      @calendar = Calendar.find(params[:calendar_id])
      @begin_date = DateTime.iso8601(params[:begin_date])
      render :layout => 'caboose/modal'
    end
    
    # PUT /admin/calendars/:calendar_id/events/:id
    def admin_update
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new
      event = CalendarEvent.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name
          when 'name'         then event.name         = value
          when 'description'  then event.description  = value          
        end
      end
    
      resp.success = save && event.save
      render :json => resp
    end
    
    # POST /admin/calendars/:calendar_id/events
    def admin_add
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new      
      event = CalendarEvent.new
      event.calendar_id = params[:calendar_id]
      event.name = params[:name]
      event.begin_date = DateTime.iso8601("#{params[:begin_date]}T10:00:00-05:00") 
      event.end_date   = DateTime.iso8601("#{params[:begin_date]}T10:00:00-05:00")      
      event.all_day = true
            
      if event.name.nil? || event.name.strip.length == 0
        resp.error = "Please enter an event name."
      else
        event.save
        resp.redirect = "/admin/calendars/#{event.calendar_id}/events/#{event.id}"
      end
      render :json => resp
    end
    
    # DELETE /admin/calendars/:id
    def admin_delete
      return unless user_is_allowed('calendars', 'delete')
      Calendar.find(params[:id]).destroy      
      resp = StdClass.new({ 'redirect' => "/admin/calendars" })                  
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
