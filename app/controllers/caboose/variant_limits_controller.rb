module Caboose
  class VariantLimitsController < ApplicationController
    layout 'caboose/admin'

    # @route GET /admin/variant-limits/json
    def admin_json 
      render :json => false and return if !user_is_allowed_to 'view', 'variantlimits'
      pager = Caboose::Pager.new(params, {
        'variant_id' => '',
        'user_id' => params[:user_id]
      },
      {
        'model' => 'Caboose::VariantLimit',
        'sort'  => 'variant_id',
        'desc'  => 'false',
        'base_url' => '/admin/variant-limits',
        'items_per_page' => 100
      })
      render :json => {
        :pager => pager,
        :models => pager.items.as_json(:include => [:variant])
      } 
    end

    # @route GET /admin/variant-limits/:id/json
    def admin_json_single
      render :json => false and return if !user_is_allowed_to 'edit', 'variantlimits'
      variantlimit = VariantLimit.find(params[:id])
      render :json => variantlimit.as_json(:include => [:variant])
    end

    # @route POST /admin/variant-limits
    def admin_add
      return unless (user_is_allowed_to 'edit', 'variantlimits')
      resp = Caboose::StdClass.new
      if VariantLimit.where(:user_id => params[:user_id], :variant_id => params[:variant_id]).exists?
        resp.error = 'That variant is already added to this user.'
      else
        c = VariantLimit.new
        c.user_id = params[:user_id]
        c.variant_id = params[:variant_id]
        c.min_quantity_value = 0
        c.max_quantity_value = 0
        c.current_value = 0
        c.save
        resp.success = true
      end
      render :json => resp
    end
      
    # @route PUT /admin/variant-limits/:id
    def admin_update
      return unless (user_is_allowed_to 'edit', 'variantlimits')
      resp = Caboose::StdClass.new
      variantlimit = VariantLimit.find(params[:id])
      user = logged_in_user
      if user

        params.each do |k,v|
          case k
            when "user_id"            then variantlimit.user_id            = v
            when "variant_id"         then variantlimit.variant_id         = v
            when "min_quantity_value" then variantlimit.min_quantity_value = v
            when "min_quantity_func"  then variantlimit.min_quantity_func  = v
            when "max_quantity_value" then variantlimit.max_quantity_value = v
            when "max_quantity_func"  then variantlimit.max_quantity_func  = v
            when "current_value"      then variantlimit.current_value      = v
          end
        end

        resp.success = variantlimit.save
      end
      render :json => resp
    end

    # @route GET /admin/users/:user_id/variant-limits
    def admin_edit
      return unless (user_is_allowed_to 'edit', 'users')
      @edituser = Caboose::User.find(params[:user_id])
    end

    # @route_priority 1
    # @route GET /admin/variant-limits/variant-options
    def admin_variant_options
      return unless user_is_allowed('edit', 'users')
      options = [{ 'value' => nil, 'text' => 'Select a Variant' }]
      products = Caboose::Product.where(:site_id => @site.id).all
      products.each do |p|
        p.variants.each do |v|
          options << { 'value' => v.id, 'text' => v.full_title }
        end
      end
      render :json => options
    end

  end
end