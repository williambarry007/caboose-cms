module Caboose
  class ModalController < Caboose::ApplicationController    
    layout 'caboose/application'
    
    # GET /modal
    def layout
      render 'layouts/caboose/modal', layout: false
    end
    
    # GET /modal/:url
    def index
      @url = "/#{params[:url]}"
      @url << "?#{request.query_string}" if request.query_string      
    end    	
  end  
end
