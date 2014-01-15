
module Caboose
  class PageBlockFieldValuesController < ApplicationController
    
    # PUT /admin/page-block-field-values/:id
    def admin_update
      return unless user_is_allowed('pages', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      fv = PageBlockFieldValue.find(params[:id])
                  
      save = true
      user = logged_in_user      
      
      params.each do |k,v|
        case k
          when 'value'
            fv.value = v        
        end
      end      
               
      resp.success = save && fv.save
      render :json => resp
    end
		
  end  
end
