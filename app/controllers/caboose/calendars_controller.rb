
module Caboose
  class CalendarsController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end  

    # @route GET /calendar/feed/:id
    def feed
      cal = Caboose::Calendar.find(params[:id])
      if cal
        query = []                                                                                                                             
        args = []
        d1 = Date.parse(params[:start])
        d2 = Date.parse(params[:end])
        query << "(( cast(begin_date as date) >= ? and cast(begin_date as date) <= ?) or ( cast(end_date as date) >= ? and cast(end_date as date) <= ? )) or ( cast(begin_date as date) <= ? and cast(end_date as date) >= ? )"
        args << d1
        args << d2
        args << d1
        args << d2
        args << d1
        args << d2
        where = [query.join(' and ')]
        where2 = params[:admin] == 'true' && params[:published] == 'false' ? '(published is false)' : '(published is true)'
        args.each { |arg| where << arg }
        events = Caboose::CalendarEvent.where(where2).where("calendar_id = ?", cal.id).where(where).reorder(:begin_date).all
        render :json => events.collect { |e|
          begin_date = e.all_day ? Date.parse(e.begin_date.strftime("%Y-%m-%d")) : e.begin_date
          end_date = e.all_day ? Date.parse(e.end_date.strftime("%Y-%m-%d")).next : e.end_date
          {
            'id'     => e.id,
            'title'  => (e.published ? e.name : "#{e.name} (DRAFT)"),
            'start'  => begin_date.strftime('%Y-%m-%d %H:%M:%S'),
            'end'    => end_date.strftime('%Y-%m-%d %H:%M:%S'),
            'url'    => (params[:admin] == 'true' ? "/admin/calendars/#{cal.id}/events/#{e.id}" : "/calendar-events/#{e.id}"),
            'allDay' => e.all_day
          }
        }
      else
        return nil
      end
    end

    # @route GET /calendar/event/:id/json
    def json
      event = Caboose::CalendarEvent.find(params[:id])
      e = {
        'id'     => event.id,
        'name'  => event.name,
        'begin_date'  => event.begin_date.strftime('%Y-%m-%d %H:%M:%S'),
        'end_date'    => event.end_date.strftime('%Y-%m-%d %H:%M:%S'),
        'location'    => event.location,
        'description' => event.description,
        'all_day' => event.all_day
      }
      if event
        render :json => e
      end
    end
    
    # @route GET /admin/calendars
    def admin_index
      return if !user_is_allowed('calendars', 'view')
      render :file => 'caboose/extras/error_invalid_site' and return if @site.nil?
                  
      @calendars = Calendar.where(:site_id => @site.id).reorder(:name).all
      render :layout => 'caboose/admin'      
    end

    # @route GET /admin/calendars/:id
    def admin_edit
      return unless user_is_allowed('calendars', 'edit')
      @calendar = Calendar.find(params[:id])
      
      @d = params[:d] ? DateTime.iso8601(params[:d]) : DateTime.now
      @d = @d - (@d.strftime('%-d').to_i-1)      
      
      render :layout => 'caboose/admin'
    end
            
    # @route PUT /admin/calendars/:id
    def admin_update
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      calendar = Calendar.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name
          when 'name'         then calendar.name         = value
          when 'description'  then calendar.description  = value
          when 'color'        then calendar.color        = value
        end
      end
    
      resp.success = save && calendar.save
      render :json => resp
    end
    
    # @route POST /admin/calendars
    def admin_add
      return unless user_is_allowed('calendars', 'edit')
      
      resp = StdClass.new      
      calendar = Calendar.new
      calendar.name = params[:name]
      calendar.site_id = @site.id
      
      if calendar.name.nil? || calendar.name.strip.length == 0
        resp.error = "Please enter a calendar name."
      else
        calendar.save
        resp.redirect = "/admin/calendars/#{calendar.id}"
      end
      render :json => resp
    end
    
    # @route DELETE /admin/calendars/:id
    def admin_delete
      return unless user_is_allowed('calendars', 'delete')
      Calendar.find(params[:id]).destroy      
      resp = StdClass.new({ 'redirect' => "/admin/calendars" })                  
      render :json => resp
    end       
		
  end
end
