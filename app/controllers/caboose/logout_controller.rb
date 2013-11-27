module Caboose
  class LogoutController < ApplicationController
    # GET /logout
    def index
      cookies.delete(:caboose_user_id)
      reset_session
      redirect_to "/"    
    end
  end
end