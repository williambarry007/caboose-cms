module Caboose
  class ModalController < Caboose::ApplicationController    
    layout 'caboose/application'
    
    # GET /modal/:url
    def index
      @url = "/#{params[:url]}"      
    end    	
  end  
end
