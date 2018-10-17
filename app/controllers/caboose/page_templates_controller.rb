module Caboose
  class PageTemplatesController < ApplicationController
    layout 'caboose/admin'
    
    # @route GET /admin/templates
    def admin_index
      return if !user_is_allowed('templates', 'view') || !@site.is_master
      @categories = PageTemplateCategory.order(:sort_order).all
    end

    # @route GET /admin/templates/new
    def admin_new
      return if !user_is_allowed('templates', 'add') || !@site.is_master
    end

    # @route POST /admin/templates
    def admin_create
      return unless user_is_allowed('templates', 'add')
      resp = Caboose::StdClass.new({'error' => nil,'redirect' => nil})
      @template = PageTemplate.new
      @template.title = params[:title]
      @template.category_id = params[:category_id]
      @template.save
      resp.redirect = "/admin/templates/#{@template.id}"
      render :json => resp
    end

    # @route PUT /admin/templates/:id
    def admin_update
      return unless ((user_is_allowed_to 'edit', 'templates') && @site.is_master)
      resp = Caboose::StdClass.new
      templates = params[:id] == 'bulk' ? params[:model_ids].collect{ |rid| PageTemplate.find(rid) } : [PageTemplate.find(params[:id])] 
      params.each do |k,v|
        case k
          when "title" then templates.each { |r| r.title = v }
          when "page_id" then templates.each { |r| r.page_id = v }
          when "description" then templates.each { |r| r.description = v }
          when "category_id" then templates.each { |r| r.category_id = v }
          when "sort_order" then templates.each { |r| r.sort_order = v }
        end
      end
      templates.each do |r|
        r.save
      end
      resp.success = true
      render :json => resp
    end

    # @route POST /admin/templates/:id/screenshot
    def admin_update_screenshot
      render :json => false and return unless user_is_allowed_to 'edit', 'templates'    
      resp = Caboose::StdClass.new({ 'attributes' => {} })
      template = PageTemplate.find(params[:id])
      template.screenshot = params[:screenshot]
      template.save
      resp.attributes['image'] = { 'value' => template.screenshot.url(:small) }
      render :text => resp.to_json
    end

    # @route GET /admin/templates/:id
    def admin_edit
      return if !user_is_allowed('templates', 'edit') || !@site.is_master
      @template = PageTemplate.find(params[:id])
    end

    # @route DELETE /admin/templates/:id
    def admin_delete
      return if !user_is_allowed('templates', 'delete') || !@site.is_master
      prop = PageTemplate.find(params[:id])    
      resp = Caboose::StdClass.new('redirect' => "/admin/templates")
      prop.destroy    
      render :json => resp
    end
            
  end
end