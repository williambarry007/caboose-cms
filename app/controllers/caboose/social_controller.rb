module Caboose
  class SocialController < ApplicationController
    layout 'caboose/admin'

    def analytics

    end
    
    # GET /admin/social
    def admin_edit
      return if !user_is_allowed('social', 'edit')            
      @social_config = @site.social_config
      @social_config = SocialConfig.create(:site_id => @site.id) if @social_config.nil?
    end
    
    # PUT /admin/social
    def admin_update
      return if !user_is_allowed('sites', 'edit')

      resp = StdClass.new     
      sc = @site.social_config
      sc = SocialConfig.create(:site_id => @site.id) if sc.nil?
          
      save = true
      params.each do |name,value|
        case name
          when 'site_id'              then sc.site_id              = value
          when 'facebook_page_id'     then sc.facebook_page_id     = value
          when 'twitter_username'     then sc.twitter_username     = value
          when 'instagram_username'   then sc.instagram_username   = value
          when 'youtube_url'          then sc.youtube_url          = value
          when 'pinterest_url'        then sc.pinterest_url        = value
          when 'vimeo_url'            then sc.vimeo_url            = value
          when 'rss_url'              then sc.rss_url              = value
          when 'google_plus_url'      then sc.google_plus_url      = value
          when 'linkedin_url'         then sc.linkedin_url         = value
          when 'google_analytics_id'  then sc.google_analytics_id  = value
          when 'google_analytics_id2' then sc.google_analytics_id2 = value
          when 'auto_ga_js'           then sc.auto_ga_js           = value
    	  end
    	end
    	
    	resp.success = save && sc.save
    	render :json => resp
    end
    
  end
end
