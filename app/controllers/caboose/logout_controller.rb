module Caboose
  class LogoutController < ApplicationController
    # GET /logout
    def index
      logout_user      
      redirect_to "/"    
    end
  end
end