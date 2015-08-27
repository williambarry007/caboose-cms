
module Caboose
  class CalendarsController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end    
    
    # GET /admin/calendars
    def admin_index
      return if !user_is_allowed('calendars', 'view')
      render :file => 'caboose/extras/error_invalid_site' and return if @site.nil?
                  
      @calendars = Calendar.where(:site_id => @site.id).reorder(:name).all
      render :layout => 'caboose/admin'      
    end

    # GET /admin/calendars/:id
    def admin_edit
      return unless user_is_allowed('calendars', 'edit')
      @calendar = Calendar.find(params[:id])
      
      @d = params[:d] ? DateTime.iso8601(params[:d]) : DateTime.now
      @d = @d - (@d.strftime('%-d').to_i-1)      
      
      render :layout => 'caboose/admin'
    end
            
    # PUT /admin/calendars/:id
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
    
    # POST /admin/calendars
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
    
    # DELETE /admin/calendars/:id
    def admin_delete
      return unless user_is_allowed('calendars', 'delete')
      Calendar.find(params[:id]).destroy      
      resp = StdClass.new({ 'redirect' => "/admin/calendars" })                  
      render :json => resp
    end       
		
  end
end
