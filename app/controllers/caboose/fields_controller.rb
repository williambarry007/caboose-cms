
module Caboose
  class FieldsController < ApplicationController
    
    # PUT /admin/fields/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      f = Field.find(params[:id])
                  
      save = true
      user = logged_in_user      
      
      params.each do |k,v|
        case k
          when 'value'
            f.value = v                                
        end
      end      
               
      resp.success = save && f.save
      render :json => resp
    end
    
    # POST /admin/fields/:id/image
    def admin_update_image
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      f = Field.find(params[:id])
      f.image = params[:value]
      f.save
      resp.success = true 
      resp.attributes = { 'value' => { 'value' => f.image.url(:tiny) }}
      
      render :json => resp
    end
    
    # POST /admin/fields/:id/file
    def admin_update_file
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      f = Field.find(params[:id])
      f.file = params[:value]
      f.save
      resp.success = true      
      resp.attributes = { 'value' => { 'value' => f.file.url }}
      
      render :json => resp
    end
		
  end  
end
