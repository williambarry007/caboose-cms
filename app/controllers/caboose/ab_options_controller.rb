module Caboose
  class AbOptionsController < ApplicationController
    layout 'caboose/admin'

    # GET /admin/ab_variants/:variant_id/options
    def admin_index
      return unless user_is_allowed_to 'view', 'ab_variants'
      v = AbVariant.find(params[:variant_id])
      render :json => v.ab_options
    end

    # POST admin/ab-variants/:variant_id/options'
    def admin_create
      return unless user_is_allowed_to 'edit','ab_variants'
      
      resp = StdClass.new({
        'error' => nil,
        'redirect' => nil
      })
      
      opt = AbOption.create(
        :ab_variant_id => params[:variant_id],
        :text => params[:text]
      )      
      resp.redirect = "/admin/ab-variants/#{params[:variant_id]}"      
      render :json => resp
    end

    # PUT /admin/ab_options/:id
    def admin_update
      return unless user_is_allowed_to 'edit', 'ab_variants'

      resp = StdClass.new
      opt = AbOption.find(params[:id])

      save = true
      params.each do |k,v|
        case k
          when 'text'
            opt.text = v
            break
        end
      end      

      resp.success = save && opt.save      
      render :json => resp
    end

    # DELETE /admin/ab_options/:id
    def admin_delete
      return unless user_is_allowed_to 'delete', 'ab_variants'      
      AbOption.find(params[:id]).destroy                  
      render :json => true
    end

  end
end
