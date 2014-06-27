
module Caboose
  class AdminController < ApplicationController
      
    # GET /admin
    def index
      redirect_to '/admin/pages' if logged_in?
      @return_url = params[:return_url].nil? ? '/station' : params[:return_url]
    end
    
    # GET /station
    def station
      @user = logged_in_user
      render :layout => 'caboose/station'
    end
    
  end
end
