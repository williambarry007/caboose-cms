module Caboose
  class PageCustomFieldsController < ApplicationController
    
    helper :application
         
    # @route GET /admin/page-custom-fields    
    def admin_index
      return if !user_is_allowed_to 'view', 'pagecustomfields'              
      render :layout => 'caboose/admin'    
    end
    
    # @route GET /admin/page-custom-fields/json        
    def admin_json
      return if !user_is_allowed_to 'view', 'pagecustomfields'
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
        'model' => 'Caboose::PageCustomField',
        'sort'  => 'key',
        'desc'  => 'false',
        'items_per_page' => 100,
        'base_url' => '/admin/page-custom-fields'      
      })
    end
    
    # @route GET /admin/page-custom-fields/:id/json    
    def admin_json_single
      return if !user_is_allowed_to 'view', 'pagecustomfields'
      f = PageCustomField.find(params[:id])      
      render :json => f
    end
                      
    # @route GET /admin/page-custom-fields/:id
    def admin_edit
      return if !user_is_allowed('pagecustomfields', 'edit')    
      @page_custom_field = PageCustomField.find(params[:id])      
      render :layout => 'caboose/admin'
    end
        
    # @route PUT /admin/page-custom-fields/:id
    def admin_update      
      return if !user_is_allowed('pagecustomfields', 'edit')
      
      resp = Caboose::StdClass.new
      f = PageCustomField.find(params[:id])
      
      save = true
      params.each do |name, value|    
        case name          
          when 'key'           then f.key            = value
          when 'name'          then f.name           = value
          when 'field_type'    then f.field_type     = value
          when 'default_value' then f.default_value  = value
          when 'options'       then f.options        = value              
        end
      end
      resp.success = save && f.save      
      render :json => resp
    end
  
    # @route POST /admin/page-custom-fields
    def admin_add
      return if !user_is_allowed('pagecustomfields', 'add')
  
      resp = Caboose::StdClass.new
    
      f = PageCustomField.new      
      f.name = params[:key]            

      if f.name.nil? || f.name.length == 0
        resp.error = 'A field key is required.'      
      else
        f.site_id = @site.id
        f.key = f.name.gsub(' ', '_').gsub('-', '_').downcase
        f.field_type = PageCustomField::FIELD_TYPE_TEXT
        f.save
        resp.redirect = "/admin/page-custom-fields/#{f.id}"
      end
      
      render :json => resp
    end
    
    # @route DELETE /admin/page-custom-fields/:id
    def admin_delete
      return if !user_is_allowed('pagecustomfields', 'edit')

      if params[:id] == 'bulk'      
        params[:model_ids].each do |fid|
          PageCustomFieldValue.where(:page_custom_field_id => fid).destroy_all
          PageCustomField.where(:id => fid).destroy_all                                    
        end
      else
        fid = params[:id]
        PageCustomFieldValue.where(:page_custom_field_id => fid).destroy_all
        PageCustomField.where(:id => fid).destroy_all        
      end
  
      render :json => { 'redirect' => '/admin/page-custom-fields' }      
    end
        
    # @route_priority 1
    # @route GET /admin/page-custom-fields/:field-options    
    def admin_options
      return if !user_is_allowed_to 'view', 'pagecustomfields'  
	    options = []
	    case params[:field]
	      when nil
	        arr = PageCustomField.where(:site_id => @site.id).reorder(:key).all
	        options = arr.collect{ |a| { 'value' => a.id, 'text' => a.name }} 	    
	      when 'field-type'
	        options = [
	          { 'value' => PageCustomField::FIELD_TYPE_TEXT     , 'text' => 'Text'     },
            { 'value' => PageCustomField::FIELD_TYPE_SELECT   , 'text' => 'Select'   },
            { 'value' => PageCustomField::FIELD_TYPE_CHECKBOX , 'text' => 'Checkbox' },
            { 'value' => PageCustomField::FIELD_TYPE_DATE     , 'text' => 'Date'     },
            { 'value' => PageCustomField::FIELD_TYPE_DATETIME , 'text' => 'Datetime' }          
          ]                            
      end        
	    render :json => options
	  end
    
  end
end
