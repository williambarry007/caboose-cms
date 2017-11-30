module Caboose
  class SnsController < ApplicationController
    
    skip_before_filter :verify_authenticity_token

    # @route GET /admin/sns
    def admin_index
      render :json => true
    end

    # @route POST /admin/sns
    def admin_add
      body = JSON.parse(request.raw_post, {symbolize_names: true})
      Caboose.log(body)
      # if body[:Records]
      #   records = body[:Records]
      #   # if body[:Type] && body[:Type] == "SubscriptionConfirmation"
      #   #   Caboose.log("SNS Subscription SubscribeURL\n#{body[:SubscribeURL]}")
      #   if records['eventSource'] == "aws:s3"
      #     msg = JSON.parse(body[:Message])
      #     if msg['Records']
      if body && body['Records']
        body['Records'].each do |r|
          if r['eventName'] && r['eventName'].starts_with?('ObjectCreated')          
            if r['s3'] && r['s3']['object'] && r['s3']['object']['key']
              key = URI.decode(r['s3']['object']['key']).gsub('+', ' ')
              Caboose.log("Processing #{key}")
              arr = key.split('_')
              media_category_id = arr.shift
              original_name = arr.join('_')  
              name = Caboose::Media.upload_name(original_name)                                       
              m = Media.where(:media_category_id => media_category_id, :original_name => original_name, :name => name).first
              m = Media.create(:media_category_id => media_category_id, :original_name => original_name, :name => name, :processed => false) if m.nil?                
              m.delay(:queue => 'caboose_media').process
            end
          end                  
        end
      end
      #     end
      #   end
      # end
      render :json => true
    end
    
    # @route GET  /admin/sns/confirm
    # @route POST /admin/sns/confirm
    def admin_confirm      
      render :json => true
    end

    # @route PUT /admin/sns/:id
    def admin_update
      render :json => true
    end

    # @route DELETE /admin/sns/:id
    def admin_delete                        
      render :json => true
    end

  end
end
