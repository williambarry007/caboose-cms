require 'httparty'

module Caboose
  class GoogleSpreadsheetsController < Caboose::ApplicationController
    
    # GET /google-spreadsheets/:spreadsheet_id/csv
    def csv_data           
      spreadsheet_id = params[:spreadsheet_id]                                                                                                              
      #url = "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/export?format=csv&id=#{spreadsheet_id}&gid=0"
      url = "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/pub?output=csv&single=true&gid=0"            
      resp = HTTParty.get(url)
      arr = nil
      begin 
        arr = CSV.parse(resp.body)
      rescue
        Caboose.log("Error parsing CSV in spreadsheet #{spreadsheet_id}:\n\n#{resp.body}")    
      end
      render :json => arr
    end

  end
end
