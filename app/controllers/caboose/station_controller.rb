
module Caboose
  class StationController < ApplicationController
    layout 'caboose/modal'
    
    # GET /station
    def index
      @user = logged_in_user
      page_id = params['page_id'].nil? ? Page.index_page(@site.id).id : params['page_id']
      @page = Page.find(page_id)
      @tab = params['tab']
      
      if @user.nil? || @user.id == Caboose::User.logged_out_user_id(@site.id)
        redirect_to "/login"
      end
    end
    
    # GET /station/plugin-count
    def plugin_count
      render :json => Caboose::plugins.count  
    end
      
    # PUT /admin/station
    def index_admin
      session[:caboose_station_state]       = params[:state]
      session[:caboose_station_open_tabs]   = params[:open_tabs]
      session[:caboose_station_return_url]  = params[:return_url]
      render :json => true
    end
  end
end
