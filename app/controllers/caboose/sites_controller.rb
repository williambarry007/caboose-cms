require 'csv'

module Caboose
  class SitesController < ApplicationController
    layout 'caboose/admin'
      
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end

    def sitemap
      @protocol = request && request.protocol ? request.protocol : 'http'
      begin
        view = ActionView::Base.new(ActionController::Base.view_paths)
        str = view.render(:partial => "../../app/views/caboose/blocks/#{@site.name}/sitemap", :locals => {:site => @site, :protocol => @protocol})
        render :inline => str
      rescue ActionView::MissingTemplate => ex
        respond_to :xml
      end
    end

    def robots
      respond_to :text
    end
            
    # @route GET /admin/sites
    def admin_index
      return if !user_is_allowed('sites', 'view')
      if !@site.is_master
        @error = "You are not allowed to manage sites."
        render :file => 'caboose/extras/error' and return
      end
      @pager = PageBarGenerator.new(params, {
    		  'name_like' => '',    		  
    		},{
    		  'model'          => 'Caboose::Site',
    	    'sort'			     => 'name',
    		  'desc'			     => false,
    		  'base_url'		   => '/admin/sites',
    		  'use_url_params' => false,
    		  'items_per_page' => 100
    	})
    	@sites = @pager.items
    end
    
    # @route GET /admin/sites/json
    def admin_json
      return if !user_is_allowed('sites', 'view')
      if !@site.is_master
        @error = "You are not allowed to view sites."
        render :file => 'caboose/extras/error' and return
      end
      h = {        
        'name'              => '',
        'description'       => '',
        'name_like'         => '',
        'description_like'  => '',
      }
      pager = Caboose::Pager.new(params, h, {      
        'model'          => 'Caboose::Site',
        'sort'           => 'name',
        'desc'           => 'false',
        'base_url'       => "/admin/sites",
        'items_per_page' => 1000        
      })
      render :json => {
        :pager => pager,
        :models => pager.items.as_json(:include => :domains)
      }
    end
    
    # @route GET /admin/sites/:id/json
    def admin_json_single
      return if !user_is_allowed('sites', 'view')
      site = get_edit_site(params[:id], @site.id)
      render :json => site.as_json(:include => :domains)      
    end
    
    # @route GET /admin/sites/new
    def admin_new
      return if !user_is_allowed('sites', 'add')
      if !@site.is_master
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end
      @site = Site.new
    end
            
    # @route GET /admin/sites/:id/block-types
    def admin_edit_block_types
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end
      @site = Site.find(params[:id])      
    end
            
    # @route GET /admin/sites/:id/css
    def admin_edit_css
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end    
      @site = Site.find(params[:id])      
    end
            
    # @route GET /admin/sites/:id/js
    def admin_edit_js
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end   
      @site = Site.find(params[:id])      
    end

    # @route GET /admin/sites/:id/contact
    def admin_edit_contact
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end   
      @site = Site.find(params[:id])      
    end

    # @route GET /admin/sites/:id/codes
    def admin_edit_codes
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end   
      @site = Site.find(params[:id])      
    end
            
    # @route GET /admin/sites/:id/delete
    def admin_delete_form
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end
      @site = Site.find(params[:id])      
    end
    
    # @route GET /admin/sites/:id
    def admin_edit
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        @error = "You are not allowed to edit this site."
        render :file => 'caboose/extras/error' and return
      end
      @site = Site.find(params[:id])            
    end
        
    # @route POST /admin/sites
    def admin_add
      return if !user_is_allowed('sites', 'add')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      resp = StdClass.new      
      site_name = params[:name].strip
      if site_name.blank?
        resp.error = "Please enter a valid site name."
      elsif Site.where(:name => site_name.downcase.gsub(" ","").gsub("'","").gsub("-","")).exists?
        resp.error = "That site name is taken."    
      else
        site = Caboose::Site.new
        site.name = site_name.downcase.gsub(" ","").gsub("'","").gsub("-","") 
        site.description = site_name
        site.use_fonts = true
        site.use_dragdrop = true
        site.theme_color = '#141414'
        site.allow_self_registration = false
        site.use_store = false
        site.save
        resp.redirect = "/admin/sites/#{site.id}"
        if Rails.env.development?
          site.build_new_site
        elsif Rails.env.production?
          site.delay(:queue => 'general', :priority => 11).build_new_site
        end
      end         
      render :json => resp
    end
        
    # @route PUT /admin/sites/:id
    def admin_update
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        render :json => { :error => "You are not allowed to manage sites." } and return
      end
      resp = StdClass.new     
      site = Site.find(params[:id])
      save = true
      params.each do |name,value|
        case name
          when 'name'                     then site.name                    = value
          when 'description'              then site.description             = value
          when 'under_construction_html'  then site.under_construction_html = value
          when 'use_store'                then site.use_store               = value
          when 'use_fonts'                then site.use_fonts               = value
          when 'use_dragdrop'             then site.use_dragdrop            = value
          when 'use_retargeting'          then site.use_retargeting         = value
          when 'custom_css'               then site.custom_css              = value            
          when 'custom_js'                then site.custom_js               = value
          when 'default_layout_id'        then site.default_layout_id       = value
          when 'allow_self_registration'  then site.allow_self_registration = value
          when 'theme_color'  then site.theme_color = value
          when 'assets_url'  then site.assets_url = value
          when 'main_phone' then site.main_phone = value
          when 'alt_phone' then site.alt_phone = value
          when 'address1' then site.address1 = value
          when 'address2' then site.address2 = value
          when 'city' then site.city = value
          when 'state' then site.state = value
          when 'zip' then site.zip = value
          when 'fax' then site.fax = value
          when 'contact_email' then site.contact_email = value
          when 'head_code' then site.head_code = (value.blank? ? nil : value.gsub('<end/script>','</script>'))
          when 'body_open_code' then site.body_open_code = (value.blank? ? nil : value.gsub('<end/script>','</script>'))
          when 'body_close_code' then site.body_close_code = (value.blank? ? nil : value.gsub('<end/script>','</script>'))
    	  end
    	end
    	resp.success = save && site.save
    	render :json => resp
    end
        
    # @route POST /admin/sites/:id/logo
    def admin_update_logo
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        render :json => { :error => "You are not allowed to manage sites." } and return
      end
      site = Site.find(params[:id])       
      site.logo = params[:logo]
      site.save
      resp = StdClass.new
      resp.success = true
      resp.attributes = { :logo => { :value => site.logo.url(:thumb) }}
      if Caboose::use_cloudinary
        site.update_cloudinary_logo if Rails.env.development?
        site.delay(:queue => 'general', :priority => 12).update_cloudinary_logo if Rails.env.production?
      end
      render :json => resp
    end

    # @route POST /admin/sites/:id/favicon
    def admin_update_favicon
      return if !user_is_allowed('sites', 'edit')
      if (@site.id.to_s != params[:id] && !@site.is_master)
        render :json => { :error => "You are not allowed to manage sites." } and return
      end
      site = Site.find(params[:id])       
      site.favicon = params[:favicon]
      site.save
      resp = StdClass.new
      resp.success = true
      resp.attributes = { :favicon => { :value => site.favicon.url(:tiny) }}
      if Caboose::use_cloudinary
        site.update_cloudinary_favicon if Rails.env.development?
        site.delay(:queue => 'general', :priority => 12).update_cloudinary_favicon if Rails.env.production?
      end
      render :json => resp
    end
          
    # @route DELETE /admin/sites/:id
    def admin_delete
      return if !user_is_allowed('sites', 'delete')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      site = Site.find(params[:id])
      site.destroy
      resp = StdClass.new({
        'redirect' => '/admin/sites'
      })
      render :json => resp
    end
    
    # @route POST /admin/sites/:id/members
    def admin_add_member
      return if !user_is_allowed('sites', 'edit')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      sm = SiteMembership.where(:site_id => params[:id], :user_id => params[:user_id]).first
      sm = SiteMembership.create(:site_id => params[:id], :user_id => params[:user_id]) if sm.nil?
      sm.role = params[:role]
      sm.save      
      render :json => true
    end
    
    # @route DELETE /admin/sites/:id/members/:user_id
    def admin_remove_member
      return if !user_is_allowed('sites', 'edit')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      SiteMembership.where(:site_id => params[:id], :user_id => params[:user_id]).destroy_all        
      render :json => true
    end
    
    # @route_priority 1
    # @route GET /admin/sites/options
    # @route GET /admin/sites/:field-options
    # @route GET /admin/sites/:id/:field-options    
    def options
      return if !user_is_allowed('sites', 'view')
      render :json => { :error => "You are not allowed to manage sites." } and return if !@site.is_master
      case params[:field]
        when nil
          options = logged_in_user.is_super_admin? ? Site.reorder('name').all.collect { |s| { 'value' => s.id, 'text' => s.name }} : []
        when 'default-layout'
          cat_ids = Caboose::BlockTypeCategory.layouts.collect{ |cat| cat.id }
          block_types = Caboose::BlockType.includes(:block_type_site_memberships).where("block_type_category_id in (?) and block_type_site_memberships.site_id = ?", cat_ids, params[:id]).reorder(:description).all
          options = block_types.collect do |bt|
            { 'value' => bt.id, 'text' => bt.description } 
          end
      end
      render :json => options
    end


    private

    def get_edit_site(s_id, site_id)
      site = Site.find(s_id)
      return site if site && (site.id == site_id || logged_in_user.is_super_admin?)
      return nil
    end

  end
end
