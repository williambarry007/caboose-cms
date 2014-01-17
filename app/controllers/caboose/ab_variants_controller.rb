module Caboose
  class AbVariantsController < ApplicationController
    layout 'caboose/admin'

    def before_action
      @page = Page.page_with_uri('/admin')
    end

    # GET /admin/ab_variants
    def index
      return unless user_is_allowed_to 'view', 'ab_variants'

      @gen = PageBarGenerator.new(params, {'name' => '', 'analytics_name' => ''}, {
        'model' => 'Caboose::AbVariant',
        'sort'  => 'name',
        'desc'  => 'false',
        'base_url' => '/admin/ab-variants'
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
      @variant = AbVariant.find(params[:id])
    end

    # POST /admin/ab-variants
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
        resp.redirect = "/admin/ab-variants/#{variant.id}"
      end
      
      render json: resp
    end

    # POST admin/ab-variants/:id/new-option'
    def create_option
      return unless user_is_allowed_to 'edit','ab_variants'
      
      resp = StdClass.new({
        'error' => nil,
        'redirect' => nil
      })

      Caboose.log params[:option_name]

      variant = AbVariant.find(params[:id])
      variant.ab_options.build(text: params[:option_name]).save
      variant.save
      resp.redirect = "/admin/ab-variants/#{variant.id}"
      
      render json: resp
    end

    # PUT /admin/ab_variants/:id
    def update
      return unless user_is_allowed_to 'edit', 'ab_variants'

      resp = StdClass.new
      variant = AbVariant.find(params[:id])

      save = true
      if params[:name]
        variant.name = params[:name]
      end
      if params[:analytics_name]
        variant.analytics_name = params[:analytics_name]
      end

      params.each do |name,value|
        Caboose.log name.slice(0,6)
        if name.slice(0,6) == "option"
          option = AbOption.find(name.to_s.scan(/\d+$/).first)
          option.text = value
          option.save
        end
      end

      resp.success = save && variant.save
      if resp.success
        Caboose.log "Saved"
      else
        Caboose.log "Not saved"
      end

      render json: resp
    end

    # DELETE /admin/ab_variants/:id
    def destroy
      return unless user_is_allowed_to 'delete', 'ab_variants'
      
      variant = AbVariants.find(params[:id])
      variant.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/ab-variants'
      })
      render json: resp
    end

  end
end
