
module Caboose
  class AdminController < ApplicationController
      
    # GET /admin
    def index
      return if !user_is_allowed('admin', 'view')      
    end
    
    # GET /station
    def station
      @user = logged_in_user
      render :layout => 'caboose/station'
    end
    
  end
end
