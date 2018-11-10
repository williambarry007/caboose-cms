module Caboose
  class LogoutController < ApplicationController
    
    # @route GET /logout
    def index
      Caboose.plugin_hook('before_logout')
      logout_user
      elo = User.logged_out_user(@site.id)        
      login_user(elo)      
      redirect_to params[:return_url] ? params[:return_url] : "/"    
    end
    
  end
end