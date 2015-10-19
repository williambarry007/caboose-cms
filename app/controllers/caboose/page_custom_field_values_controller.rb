module Caboose
  class PageCustomFieldValuesController < ApplicationController
                
    # PUT /admin/page-custom-field-values/:id
    def admin_update      
      return if !user_is_allowed('pagecustomfieldvalues', 'edit')
      
      resp = Caboose::StdClass.new
      fv = PageCustomFieldValue.find(params[:id])
      
      save = true
      params.each do |k, v|    
        case k            
          when 'value' then fv.value                = v                            
        end
      end
      resp.success = save && fv.save      
      render :json => resp
    end
  
  end
end
