
module Caboose
  class EventsController < ApplicationController
    
    helper :application
    
    # @route GET /admin/calendars/:calendar_id/events/:id
    def admin_edit
      return unless user_is_allowed('calendars', 'edit')
      @event = CalendarEvent.find(params[:id])
      if @event.calendar_event_group_id.nil?
        g = CalendarEventGroup.create
        @event.calendar_event_group_id = g.id
        @event.save
      end
      render :layout => 'caboose/admin'
    end

    # @route GET /calendar-events/:id
    def show
      @event = CalendarEvent.where(:id => params[:id], :published => true).first
      render :file => "caboose/extras/error404" and return if @event.nil?
      @page.title = @event.name if @event
      render :layout => 'caboose/application'
    end
    
    # @route_priority 1
    # @route GET /admin/calendars/:calendar_id/events/new
    # def admin_new
    #   return unless user_is_allowed('calendars', 'edit')
    #   @calendar = Calendar.find(params[:calendar_id])
    #   @begin_date = DateTime.iso8601(params[:begin_date])
    #   render :layout => 'caboose/admin'
    # end
    
    # @route POST /admin/calendars/:calendar_id/events
    def admin_add
      return unless user_is_allowed('calendars', 'edit')
      resp = StdClass.new      
      event = CalendarEvent.new
      event.calendar_id = params[:calendar_id]
      event.name = params[:name]
      event.begin_date = DateTime.parse("#{params[:begin_date]}T10:00:00-05:00") 
      event.end_date   = DateTime.parse("#{params[:begin_date]}T10:00:00-05:00")      
      event.all_day = false
      event.published = false
      event.url_label = "More Information"
      event.save
      resp.redirect = "/admin/calendars/#{event.calendar_id}/events/#{event.id}"
      render :json => resp
    end
    
    # @route PUT /admin/calendars/:calendar_id/events/:id
    def admin_update
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new({ 'attributes' => {} })
      event = CalendarEvent.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name
          when 'name'         then event.name         = value
          when 'location'     then event.location     = value
          when 'description'  then event.description  = value
          when 'url'          then event.url  = value
          when 'url_label'          then event.url_label  = value
          when 'published'    then event.published  = value
          when 'all_day'      then event.all_day      = value
          when 'begin_date'              
            t = event.begin_date ? event.begin_date.strftime('%H:%M %z') : '10:00 -0500'
            event.begin_date = DateTime.strptime("#{value} #{t}", '%m/%d/%Y %H:%M %z')                        
          when 'begin_time'
            d = event.begin_date ? event.begin_date.strftime('%Y-%m-%d') : DateTime.now.strftime('%Y-%m-%d')
            event.begin_date = DateTime.strptime("#{d} #{value}", '%Y-%m-%d %I:%M %P')
          when 'end_date'
            t = event.end_date ? event.end_date.strftime('%H:%M %z') : '10:00 -0500'
            event.end_date = DateTime.strptime("#{value} #{t}", '%m/%d/%Y %H:%M %z')
          when 'end_time'
            d = event.end_date ? event.end_date.strftime('%Y-%m-%d') : DateTime.now.strftime('%Y-%m-%d')
            event.end_date = DateTime.strptime("#{d} #{value}", '%Y-%m-%d %I:%M %P')
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
    
      resp.success = save && event.save
      render :json => resp
    end  


    # @route POST /admin/calendars/:calendar_id/events/:event_id/image
    def admin_update_image
      return if !user_is_allowed('calendars', 'edit')     
      resp = Caboose::StdClass.new
      event = CalendarEvent.find(params[:event_id])
      event.image = params[:image]            
      resp.success = event.save
      resp.attributes = { 'image' => { 'value' => event.image.url(:thumb) }}
      render :text => resp.to_json
    end      
    
    # @route DELETE /admin/calendars/:calendar_id/events/:id
    def admin_delete
      return unless user_is_allowed('calendars', 'delete')
      cal_id = CalendarEvent.find(params[:id]).calendar_id
      CalendarEvent.find(params[:id]).destroy      
      resp = StdClass.new({ 'redirect' => "/admin/calendars/#{cal_id}" })                  
      render :json => resp
    end
		
  end
end
