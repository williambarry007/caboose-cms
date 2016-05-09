require 'httparty'

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


    # GET /api/instagram
    def authorize_instagram
      code = params[:code]
      site_id = params[:state]
      site = Site.where(:id => site_id).first
      master_site = Site.where(:is_master => true).first
      master_domain = master_site ? (master_site.primary_domain ? master_site.primary_domain.domain : 'caboosecms.com') : 'caboosecms.com'
      domain = site ? (site.primary_domain ? site.primary_domain.domain : 'www.caboosecms.com') : 'www.caboosecms.com'
      resp = HTTParty.post(
        'https://api.instagram.com/oauth/access_token',
        :body => {
          :client_id => 'bac12987b6cb4262a004f3ffc388accc',
          :client_secret => 'ede277a5b2df47fe8efcb69a9fac8e07',
          :grant_type => 'authorization_code',
          :redirect_uri => 'http://' + master_domain + '/api/instagram',
          :code => code
        }
      )
      if resp
        if resp['code'] && (resp['code'] == 400 || resp['code'] = '400')
          redirect_to 'http://' + domain + '/admin/social?instagram=fail'
        elsif !resp['access_token'].blank?
          sc = SocialConfig.where(:site_id => site_id).first
          sc.instagram_access_token = resp['access_token']
          sc.instagram_user_id = resp['user']['id']
          sc.instagram_username = resp['user']['username']
          sc.save
          redirect_to 'http://' + domain + '/admin/social?instagram=success'
        end
      else
        redirect_to 'http://' + domain + '/admin/social?instagram=fail'
      end      
    end

    # DELETE /api/instagram
    def deauthorize_instagram
      resp = StdClass.new     
      site_id = params[:site_id]
      site = Site.where(:id => site_id).first
      sc = SocialConfig.where(:site_id => site.id).first
      sc.instagram_username = nil
      sc.instagram_user_id = nil
      sc.instagram_access_token = nil
      sc.save
      resp.success = true
      render :json => resp
    end
    
  end
end
