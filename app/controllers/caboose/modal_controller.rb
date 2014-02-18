module Caboose
  class ModalController < Caboose::ApplicationController    
    layout 'caboose/application'
    
    # GET /modal/:url
    def index
      @url = "/#{params[:url]}"
      @url << "?#{request.query_string}" if request.query_string      
    end    	
  end  
end
