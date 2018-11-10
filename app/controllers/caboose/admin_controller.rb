
module Caboose
  class AdminController < ApplicationController
      
    # @route GET /admin
    def index      
      return if !user_is_allowed('admin', 'view')
      @return_url = params[:return_url].nil? ? '/admin/pages' : params[:return_url]
    end
    
  end
end
