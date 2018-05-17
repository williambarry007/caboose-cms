module Caboose
  class EventCustomFieldValuesController < ApplicationController
                
    # @route PUT /admin/event-custom-field-values/:id
    def admin_update      
      return if !user_is_allowed('eventcustomfieldvalues', 'edit')
      
      resp = Caboose::StdClass.new
      fv = EventCustomFieldValue.find(params[:id])
      
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