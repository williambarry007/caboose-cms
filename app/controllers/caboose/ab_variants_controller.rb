module Caboose
  class AbVariantsController < ApplicationController
    layout 'caboose/admin'

    def before_action
      @page = Page.page_with_uri('/admin')
    end

    # GET /admin/ab_variants
    def index
      return unless user_is_allowed_to 'view', 'ab_variants'

      @gen = PageBarGenerator.new(params, {'name' => ''}, {
        'model' => 'Caboose::AbVariant',
        'sort'  => 'name',
        'desc'  => 'false',
        'base_url' => '/admin/ab_variants'
      })
      @variants = @gen.items
    end

    # GET /admin/ab_variants/new
    def new
      return unless user_is_allowed_to 'add', 'ab_variants'
      @variant = AbVariant.new
    end

    # GET /admin/ab_variants/:id
    def edit
      return unless user_is_allowed_to 'edit', 'ab_variants'
      @variant = Variant.find(params[:id])
    end

    # POST /admin/ab_variants
    def create
      return unless user_is_allowed_to 'edit', 'ab_variants'

      resp = StdClass.new({
        'error' => nil,
        'redirect' => nil
      })

      variant = AbVariant.new
      variant.name = params[:name]
      variant.analytics_name = params[:name].parameterize

      if (variant.name.length == 0)
        resp.error = "A name is required."
      elsif
        variant.save
        resp.redirect = "/admin/ab_variants/"+variant.id
      end
      render json: resp
    end

    # PUT /admin/ab_variants/:id
    def update
      return unless user_is_allowed_to 'edit', 'ab_variants'

      resp = StdClass.new
      variant = AbVariants.find(params[:id])

      save = true
      params.each do |name,value|
       user[name.to_sym] = value 
      end

      resp.success = save && user.save
      render json: resp
    end

    # DELETE /admin/ab_variants/:id
    def destroy
      return unless user_is_allowed_to 'delete', 'ab_variants'
      
      variant = AbVariants.find(params[:id])
      variant.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/users'
      })
      render json: resp
    end

  end
end
