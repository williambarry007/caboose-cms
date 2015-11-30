module Caboose
  class PostCustomFieldsController < ApplicationController
    
    helper :application
         
    # GET /admin/post-custom-fields    
    def admin_index
      return if !user_is_allowed_to 'view', 'postcustomfields'              
      render :layout => 'caboose/admin'    
    end
    
    # GET /admin/post-custom-fields/json        
    def admin_json
      return if !user_is_allowed_to 'view', 'postcustomfields'
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
        'model' => 'Caboose::PostCustomField',
        'sort'  => 'key',
        'desc'  => 'false',
        'items_per_page' => 100,
        'base_url' => '/admin/post-custom-fields'      
      })
    end
    
    # GET /admin/post-custom-fields/:id/json    
    def admin_json_single
      return if !user_is_allowed_to 'view', 'postcustomfields'
      f = PostCustomField.find(params[:id])      
      render :json => f
    end
                      
    # GET /admin/post-custom-fields/:id
    def admin_edit
      return if !user_is_allowed('postcustomfields', 'edit')    
      @post_custom_field = PostCustomField.find(params[:id])      
      render :layout => 'caboose/admin'
    end
        
    # PUT /admin/post-custom-fields/:id
    def admin_update      
      return if !user_is_allowed('postcustomfields', 'edit')
      
      resp = Caboose::StdClass.new
      f = PostCustomField.find(params[:id])
      
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
  
    # POST /admin/post-custom-fields
    def admin_add
      return if !user_is_allowed('postcustomfields', 'add')
  
      resp = Caboose::StdClass.new
    
      f = PostCustomField.new      
      f.name = params[:key]            

      if f.name.nil? || f.name.length == 0
        resp.error = 'A field key is required.'      
      else
        f.site_id = @site.id
        f.key = f.name.gsub(' ', '_').gsub('-', '_').downcase
        f.field_type = PostCustomField::FIELD_TYPE_TEXT
        f.save
        resp.redirect = "/admin/post-custom-fields/#{f.id}"
      end
      
      render :json => resp
    end
    
    # DELETE /admin/post-custom-fields/:id
    def admin_delete
      return if !user_is_allowed('postcustomfields', 'edit')

      if params[:id] == 'bulk'      
        params[:model_ids].each do |fid|
          PostCustomFieldValue.where(:post_custom_field_id => fid).destroy_all
          PostCustomField.where(:id => fid).destroy_all                                    
        end
      else
        fid = params[:id]
        PostCustomFieldValue.where(:post_custom_field_id => fid).destroy_all
        PostCustomField.where(:id => fid).destroy_all        
      end
  
      render :json => { 'redirect' => '/admin/post-custom-fields' }      
    end
        
    # GET /admin/post-custom-fields/:field-options    
    def admin_options
      return if !user_is_allowed_to 'view', 'postcustomfields'  
	    options = []
	    case params[:field]
	      when nil
	        arr = PostCustomField.where(:site_id => @site.id).reorder(:key).all
	        options = arr.collect{ |a| { 'value' => a.id, 'text' => a.name }} 	    
	      when 'field-type'
	        options = [
	          { 'value' => PostCustomField::FIELD_TYPE_TEXT     , 'text' => 'Text'     },
            { 'value' => PostCustomField::FIELD_TYPE_SELECT   , 'text' => 'Select'   },
            { 'value' => PostCustomField::FIELD_TYPE_CHECKBOX , 'text' => 'Checkbox' },
            { 'value' => PostCustomField::FIELD_TYPE_DATE     , 'text' => 'Date'     },
            { 'value' => PostCustomField::FIELD_TYPE_DATETIME , 'text' => 'Datetime' }          
          ]                            
      end        
	    render :json => options
	  end
    
  end
end
