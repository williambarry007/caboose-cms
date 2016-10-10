
module Caboose
  class CalendarEventsController < ApplicationController
    
    helper :application
    
    # @route GET /admin/calendars/:calendar_id/events/json
    def admin_json
      return unless user_is_allowed('calendars', 'edit')      
      render :json => Caboose::CalendarEvent.events_for_month(params[:calendar_id], params[:month], params[:year])    
    end
    
    # @route GET /admin/calendars/:calendar_id/events/:id/json
    def admin_json_single
      return unless user_is_allowed('calendars', 'edit')
      event = CalendarEvent.find(params[:id])
      if event.calendar_event_group_id.nil?
        g = CalendarEventGroup.create
        event.calendar_event_group_id = g.id
        event.save
      end
      render :json => event.as_json(:include => :calendar_event_group)
    end
    
    # @route GET /admin/calendars/:calendar_id/events/:id
    def admin_edit
      return unless user_is_allowed('calendars', 'edit')
      @event = CalendarEvent.find(params[:id])
      if @event.calendar_event_group_id.nil?
        g = CalendarEventGroup.create
        @event.calendar_event_group_id = g.id
        @event.save
      end
      render :layout => 'caboose/modal'
    end
    
    # @route_priority 1
    # @route GET /admin/calendars/:calendar_id/events/new
    def admin_new
      return unless user_is_allowed('calendars', 'edit')
      @calendar = Calendar.find(params[:calendar_id])
      @begin_date = DateTime.iso8601(params[:begin_date])
      render :layout => 'caboose/modal'
    end
    
    # @route POST /admin/calendars/:calendar_id/events
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
        resp.success = true
        resp.new_id = event.id
        resp.redirect = "/admin/calendars/#{event.calendar_id}/events/#{event.id}"
      end
      render :json => resp
    end
    
    # @route PUT /admin/calendars/:calendar_id/events/:id
    def admin_update
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new({ 'attributes' => {} })
      event = CalendarEvent.find(params[:id])

      edit_recurring = event.repeats ? params[:edit_recurring] : nil             
      events = case edit_recurring
        when nil                  then [event]
        when 'this only'          then [event]
        when 'this and following' then CalendarEvent.where(:calendar_event_group_id => event.calendar_event_group_id).where("begin_date >= ?", event.begin_date).all
        when 'all'                then CalendarEvent.where(:calendar_event_group_id => event.calendar_event_group_id).all
      end
              
      params.each do |name, value|
        case name
          when 'name'         then events.each{ |ev| ev.name         = value }  
          when 'location'     then events.each{ |ev| ev.location     = value }
          when 'description'  then events.each{ |ev| ev.description  = value }
          when 'all_day'      then events.each{ |ev| ev.all_day      = value }
          when 'begin_date'              
            t = event.begin_date ? event.begin_date.strftime('%H:%M %z') : '10:00 -0500'
            event.begin_date = DateTime.strptime("#{value} #{t}", '%m/%d/%Y %H:%M %z')                        
          when 'begin_time'
            events.each do |ev|
              d = ev.begin_date ? ev.begin_date.strftime('%Y-%m-%d') : DateTime.now.strftime('%Y-%m-%d')
              ev.begin_date = DateTime.strptime("#{d} #{value}", '%Y-%m-%d %I:%M %P')
            end
          when 'end_date'
            t = event.end_date ? event.end_date.strftime('%H:%M %z') : '10:00 -0500'
            event.end_date = DateTime.strptime("#{value} #{t}", '%m/%d/%Y %H:%M %z')
          when 'end_time'
            events.each do |ev|
              d = ev.end_date ? ev.end_date.strftime('%Y-%m-%d') : DateTime.now.strftime('%Y-%m-%d')
              ev.end_date = DateTime.strptime("#{d} #{value}", '%Y-%m-%d %I:%M %P')
            end
          when 'repeats'
            g = event.calendar_event_group
            if value == true || value.to_i == 1
              g.date_start = event.begin_date.to_date if g.date_start.nil?
              g.date_end   = event.end_date.to_date   if g.date_end.nil?
              g.save              
            end
            event.repeats = value              
          
        end
      end
      event.save
      events.each{ |ev| ev.save }
      
      resp.success = true
      render :json => resp
    end        
    
    # @route DELETE /admin/calendars/:calendar_id/events/:id
    def admin_delete
      return unless user_is_allowed('calendars', 'delete')      
      resp = StdClass.new
      
      e = CalendarEvent.find(params[:id])
      if e.repeats        
        case params[:delete_recurring] 
          when 'this only'
            e.destroy            
          when 'this and following'
            CalendarEvent.where("calendar_event_group_id = ? and begin_date >= ?", e.event_group_id, e.begin_date).destroy_all
            e.destroy            
          when 'all'
            CalendarEvent.where(:calendar_event_group_id => e.calendar_event_group_id).destroy_all            
        end
      else
        e.destroy
      end
                  
      resp.success = true
      resp.redirect = "/admin/calendars/#{params[:calendar_id]}"                  
      render :json => resp
    end
		
  end
end
