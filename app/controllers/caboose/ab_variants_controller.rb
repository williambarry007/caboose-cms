module Caboose
  class AbVariantsController < ApplicationController
    layout 'caboose/admin'

    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end

    # @route GET /admin/ab-variants
    def admin_index
      return unless user_is_allowed_to 'view', 'ab_variants'

      @gen = PageBarGenerator.new(params, {'name' => '', 'analytics_name' => ''}, {
        'model' => 'Caboose::AbVariant',
        'sort'  => 'name',
        'desc'  => 'false',
        'base_url' => '/admin/ab-variants'
      })
      @variants = @gen.items
    end

    # @route GET /admin/ab-variants/new
    def admin_new
      return unless user_is_allowed_to 'add', 'ab_variants'
      @variant = AbVariant.new
    end

    # @route GET /admin/ab-variants/:id
    def admin_edit
      return unless user_is_allowed_to 'edit', 'ab_variants'
      @variant = AbVariant.find(params[:id])
    end

    # @route POST /admin/ab-variants
    def admin_create
      return unless user_is_allowed_to 'edit', 'ab_variants'

      resp = StdClass.new({
        'error' => nil,
        'redirect' => nil
      })

      variant = AbVariant.new
      variant.name = params[:name]
      variant.analytics_name = params[:name].gsub(' ', '_').downcase

      if (variant.name.length == 0)
        resp.error = "A name is required."
      elsif variant.save
        resp.redirect = "/admin/ab-variants/#{variant.id}"
      end
      
      render json: resp
    end

    # @route PUT /admin/ab-variants/:id
    def admin_update
      return unless user_is_allowed_to 'edit', 'ab_variants'

      resp = StdClass.new
      variant = AbVariant.find(params[:id])

      save = true
      params.each do |k,v|
        case k
          when 'name'
            variant.name = v
            break
          when 'analytics_name'
            variant.analytics_name = v
            break
        end
      end

      resp.success = save && variant.save
      render :json => resp
    end

    # @route DELETE /admin/ab-variants/:id
    def admin_destroy
      return unless user_is_allowed_to 'delete', 'ab_variants'      
      AbVariants.find(params[:id]).destroy
      resp = StdClass.new('redirect' => '/admin/ab-variants')
      render :json => resp
    end

  end
end
