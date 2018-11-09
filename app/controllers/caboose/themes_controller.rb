module Caboose
  class ThemesController < ApplicationController
    layout 'caboose/admin'
    
    # @route GET /admin/theme
    def admin_edit
      return if !user_is_allowed('theme', 'edit')            
      @theme = @site.theme
      redirect_to '/admin' and return if @theme.nil?
    end
    
    # @route PUT /admin/theme
    def admin_update
      return if !user_is_allowed('theme', 'edit')
      resp = StdClass.new     
      theme = @site.theme
      save = true
      params.each do |name,value|
        case name
          when 'color_main'              then theme.color_main              = value
          when 'color_alt'                 then theme.color_alt                 = value
          when 'color_dark' then theme.color_dark = value
          when 'color_light' then theme.color_light = value
          when 'max_width' then theme.max_width = value
          when 'body_bg_color' then theme.body_bg_color = value
          when 'font_size' then theme.font_size = value
          when 'header_height' then theme.header_height = value
          when 'header_bg_color' then theme.header_bg_color = value
          when 'header_font_color' then theme.header_font_color = value
          when 'dropdown_color' then theme.dropdown_color = value
          when 'mobile_menu_bg_color' then theme.mobile_menu_bg_color = value
          when 'mobile_menu_font_color' then theme.mobile_menu_font_color = value
          when 'mobile_menu_border_color' then theme.mobile_menu_border_color = value
          when 'mobile_menu_icon_color' then theme.mobile_menu_icon_color = value
          when 'mobile_menu_icon_top' then theme.mobile_menu_icon_top = value
          when 'footer_height' then theme.footer_height = value
          when 'footer_bg_color' then theme.footer_bg_color = value
          when 'footer_font_color' then theme.footer_font_color = value
          when 'btn_border_radius' then theme.btn_border_radius = value
          when 'btn_border_width' then theme.btn_border_width = value
          when 'btn_border_color' then theme.btn_border_color = value
          when 'btn_font_color' then theme.btn_font_color = value
          when 'btn_font_size' then theme.btn_font_size = value
          when 'btn_font_weight' then theme.btn_font_weight = value
          when 'btn_font_case' then theme.btn_font_case = value
          when 'btn_border_side' then theme.btn_border_side = value
          when 'input_border_radius' then theme.input_border_radius = value
          when 'input_bg_color' then theme.input_bg_color = value
          when 'input_border_color' then theme.input_border_color = value
          when 'input_border_width' then theme.input_border_width = value
          when 'input_font_color' then theme.input_font_color = value
          when 'input_font_size' then theme.input_font_size = value
          when 'input_padding' then theme.input_padding = value

          when 'body_line_height' then theme.body_line_height = value
          when 'body_font_color' then theme.body_font_color = value
          when 'button_padding' then theme.button_padding = value
          when 'button_line_height' then theme.button_line_height = value
          when 'footer_padding' then theme.footer_padding = value
          when 'footer_font_size' then theme.footer_font_size = value
          when 'header_font_size' then theme.header_font_size = value
          when 'note_padding' then theme.note_padding = value
          when 'header_nav_spacing' then theme.header_nav_spacing = value
          when 'logo_width' then theme.logo_width = value
          when 'logo_height' then theme.logo_height = value
          when 'logo_top_padding' then theme.logo_top_padding = value
          when 'heading_line_height' then theme.heading_line_height = value
          when 'mobile_menu_nav_padding' then theme.mobile_menu_nav_padding = value
          when 'mobile_menu_font_size' then theme.mobile_menu_font_size = value
          when 'banner_padding' then theme.banner_padding = value
          when 'banner_overlay_color' then theme.banner_overlay_color = value
          when 'banner_overlay_opacity' then theme.banner_overlay_opacity = value
          when 'default_header_style' then theme.default_header_style = value
          when 'default_header_position' then theme.default_header_position = value
          when 'sidebar_width' then theme.sidebar_width = value
          when 'sidebar_bg_color' then theme.sidebar_bg_color = value

          when 'banner_font_size' then theme.banner_font_size = value
          when 'footer_hover_color' then theme.footer_hover_color = value
          when 'actual_footer_height' then theme.actual_footer_height = value
          when 'actual_banner_height' then theme.actual_banner_height = value
          when 'dropdown_nav_padding' then theme.dropdown_nav_padding = value

          when 'btn_main_bg_color' then theme.btn_main_bg_color = value
          when 'btn_alt_bg_color' then theme.btn_alt_bg_color = value
          when 'header_text_transform' then theme.header_text_transform = value
          when 'ninebar_show' then theme.ninebar_show = value
          when 'ninebar_bg_color' then theme.ninebar_bg_color = value
          when 'ninebar_text' then theme.ninebar_text = value
          when 'header_hover_bg_color' then theme.header_hover_bg_color = value
          when 'header_hover_font_color' then theme.header_hover_font_color = value
          when 'header_border_bottom' then theme.header_border_bottom = value
          when 'note_error_bg' then theme.note_error_bg = value
          when 'note_loading_bg' then theme.note_loading_bg = value
          when 'note_success_bg' then theme.note_success_bg = value
          when 'nav_lineheight_offset' then theme.nav_lineheight_offset = value

          when 'mobile_header_height' then theme.mobile_header_height = value
          when 'mobile_logo_width' then theme.mobile_logo_width = value
          when 'mobile_logo_height' then theme.mobile_logo_height = value
          when 'mobile_logo_top_padding' then theme.mobile_logo_top_padding = value
          when 'constrain_footer' then theme.constrain_footer = value
          when 'heading_base_font_size' then theme.heading_base_font_size = value

    	  end
    	end
    	resp.success = save && theme.save
    	render :json => resp
    end

    # @route PUT /admin/themes/:id/compile
    def admin_compile
      return if !user_is_allowed('theme', 'edit')
      resp = StdClass.new     
      theme = @site.theme
      if params['code']
        theme.custom_sass = params['code']
        theme.save
      elsif params['btsm_id']
        btsm = Caboose::BlockTypeSiteMembership.find(params['btsm_id'])
        btsm.custom_css = params['custom_css']
        btsm.save
      end
      theme.compile(@site.id) if Rails.env.development?
      theme.delay(:queue => 'general', :priority => 5).compile(@site.id) if Rails.env.production?
      resp.success = true
      resp.message = Rails.env.development? ? "Theme has been compiled!" : "Theme has been queued for compilation!"
      render :json => resp
    end

    # @route GET /admin/theme/sass
    def admin_sass
      return if !user_is_allowed('theme', 'edit')
      @theme = @site.theme
    end

    # @route PUT /admin/theme/sass
    def admin_update_sass
      return if !user_is_allowed('theme', 'edit')
      resp = StdClass.new  
      @theme = @site.theme
      @theme.custom_sass = params['code']
      @theme.save
      resp.success = true
      resp.message = "Theme has been saved!"
      render :json => resp
    end

    # @route POST /admin/themes/:id/default-banner-image
    def admin_update_default_banner_image
      return if !user_is_allowed('theme', 'edit')
      resp = Caboose::StdClass.new
      theme = @site.theme
      theme.default_banner_image = params[:default_banner_image]            
      resp.success = theme.save
      resp.attributes = { 'default_banner_image' => { 'value' => theme.default_banner_image.url(:huge) }}
      if Caboose::use_cloudinary
        theme.update_cloudinary_banner if Rails.env.development?
        theme.delay(:queue => 'general', :priority => 12).update_cloudinary_banner if Rails.env.production?
      end
      render :text => resp.to_json
    end

    # @route PUT /admin/themes/:id/files/:file_id/toggle
    def admin_toggle_file
      resp = Caboose::StdClass.new
      checked = params[:checked]
      theme_id = params[:id]
      file_id = params[:file_id]
      if checked && checked != false && checked != 'false'
        am = Caboose::ThemeFileMembership.where(:theme_id => theme_id, :theme_file_id => file_id).first
        am = am ? am : Caboose::ThemeFileMembership.new
        am.theme_id = theme_id
        am.theme_file_id = file_id
        am.save
      else
        Caboose::ThemeFileMembership.delete_all(:theme_id => theme_id, :theme_file_id => file_id)
      end
      resp.success = "Success"
      render :json => resp
    end
    
  end
end