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
    	  end
    	end
    	
    	resp.success = save && theme.save
    	render :json => resp
    end
    
  end
end