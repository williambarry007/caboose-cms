
module Caboose
  class AdminController < ApplicationController
      
    # @route GET /admin
    def index      
      return if !user_is_allowed('admin', 'view')
      #if logged_in?
      #  redirect_to '/admin/pages'
      #  return
      #end
      @return_url = params[:return_url].nil? ? '/admin/pages' : params[:return_url]
    end
    
    # @route GET /station
    def station
      @user = logged_in_user
      render :layout => 'caboose/station'
    end
    
  end
end
