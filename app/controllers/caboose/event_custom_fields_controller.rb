module Caboose
  class EventCustomFieldsController < ApplicationController
    
    helper :application
         
    # @route GET /admin/event-custom-fields    
    def admin_index
      return if !user_is_allowed_to 'view', 'eventcustomfields'              
      render :layout => 'caboose/admin'    
    end
    
    # @route GET /admin/event-custom-fields/json        
    def admin_json
      return if !user_is_allowed_to 'view', 'eventcustomfields'
      pager = self.fields_pager        
      render :json => {
        :pager => pager,
        :models => pager.items
      }      
    end
    
    def fields_pager
      return Caboose::Pager.new(params, {
        'site_id'     => @site.id,
        'key_like'    => '',
        'name_like'   => ''
      }, {
        'model' => 'Caboose::EventCustomField',
        'sort'  => 'key',
        'desc'  => 'false',
        'items_per_page' => 100,
        'base_url' => '/admin/event-custom-fields'      
      })
    end
    
    # @route GET /admin/event-custom-fields/:id/json    
    def admin_json_single
      return if !user_is_allowed_to 'view', 'eventcustomfields'
      f = EventCustomField.find(params[:id])      
      render :json => f
    end
                      
    # @route GET /admin/event-custom-fields/:id
    def admin_edit
      return if !user_is_allowed('eventcustomfields', 'edit')    
      @event_custom_field = EventCustomField.find(params[:id])      
      render :layout => 'caboose/admin'
    end
        
    # @route PUT /admin/event-custom-fields/:id
    def admin_update      
      return if !user_is_allowed('eventcustomfields', 'edit')
      
      resp = Caboose::StdClass.new
      f = EventCustomField.find(params[:id])
      
      save = true
      params.each do |name, value|    
        case name          
          when 'key'           then f.key            = value
          when 'name'          then f.name           = value
          when 'field_type'    then f.field_type     = value
          when 'default_value' then f.default_value  = value
          when 'options'       then f.options        = value
          when 'options_url'   then f.options_url    = value             
        end
      end
      resp.success = save && f.save      
      render :json => resp
    end
  
    # @route POST /admin/event-custom-fields
    def admin_add
      return if !user_is_allowed('eventcustomfields', 'add')
  
      resp = Caboose::StdClass.new
    
      f = EventCustomField.new      
      f.name = params[:key]            

      if f.name.nil? || f.name.length == 0
        resp.error = 'A field key is required.'      
      else
        f.site_id = @site.id
        f.key = f.name.gsub(' ', '_').gsub('-', '_').downcase
        f.field_type = EventCustomField::FIELD_TYPE_TEXT
        f.save
        resp.redirect = "/admin/event-custom-fields/#{f.id}"
      end
      
      render :json => resp
    end
    
    # @route DELETE /admin/event-custom-fields/:id
    def admin_delete
      return if !user_is_allowed('eventcustomfields', 'edit')
      if params[:id] == 'bulk'      
        params[:model_ids].each do |fid|
          EventCustomFieldValue.where(:event_custom_field_id => fid).destroy_all
          EventCustomField.where(:id => fid).destroy_all                                    
        end
      else
        fid = params[:id]
        EventCustomFieldValue.where(:event_custom_field_id => fid).destroy_all
        EventCustomField.where(:id => fid).destroy_all        
      end
  
      render :json => { 'redirect' => '/admin/event-custom-fields' }      
    end

    # @route GET /admin/event-custom-fields/:pcfid/options
    def admin_field_options
      options = []
      pcf = EventCustomField.where(:site_id => @site.id, :id => params[:pcfid]).first
      if pcf && !pcf.options.blank?
        pcf.options.split(/\n/).each do |f|
          opt = {'text' => f, 'value' => f}
          options << opt
        end
      end
      render :json => options
    end
        
    # @route_priority 1
    # @route GET /admin/event-custom-fields/:field-options    
    def admin_options
      return if !user_is_allowed_to 'view', 'eventcustomfields'  
	    options = []
	    case params[:field]
	      when nil
	        arr = EventCustomField.where(:site_id => @site.id).reorder(:key).all
	        options = arr.collect{ |a| { 'value' => a.id, 'text' => a.name }} 	    
	      when 'field-type'
	        options = [
	          { 'value' => EventCustomField::FIELD_TYPE_TEXT     , 'text' => 'Text'     },
            { 'value' => EventCustomField::FIELD_TYPE_SELECT   , 'text' => 'Select'   },
            { 'value' => EventCustomField::FIELD_TYPE_CHECKBOX , 'text' => 'Checkbox' },
            { 'value' => EventCustomField::FIELD_TYPE_DATE     , 'text' => 'Date'     },
            { 'value' => EventCustomField::FIELD_TYPE_DATETIME , 'text' => 'Datetime' }          
          ]                            
      end        
	    render :json => options
	  end
    
  end
end
