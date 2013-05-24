module Caboose
  class LogoutController < ApplicationController
    # GET /logout
    def index
      reset_session
      redirect_to "/"    
    end
  end
end