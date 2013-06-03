
module Caboose
  class StationController < ApplicationController
      
    # PUT /admin/station
    def index
      session[:caboose_station_state]       = params[:state]
      session[:caboose_station_open_tabs]   = params[:open_tabs]
      session[:caboose_station_return_url]  = params[:return_url]
      render :json => true
    end
  end
end
