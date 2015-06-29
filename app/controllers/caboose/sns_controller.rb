module Caboose
  class SnsController < ApplicationController
    
    skip_before_filter :verify_authenticity_token

    # GET /admin/sns
    def admin_index      
      render :json => true
    end

    # POST /admin/sns
    def admin_add
      body = JSON.parse(request.raw_post, {symbolize_names: true})      
      if body[:Type] && body[:Type] == "SubscriptionConfirmation"
        Caboose.log("SNS Subscription SubscribeURL\n#{body[:SubscribeURL]}")
      elsif body[:Subject] == 'Amazon S3 Notification'
        msg = JSON.parse(body[:Message])
        if msg['Records']
          msg['Records'].each do |r|
            if r['eventName'] && r['eventName'].starts_with?('ObjectCreated')          
              if r['s3'] && r['s3']['object'] && r['s3']['object']['key']
                #Caboose.log(r['eventName'])
                #Caboose.log(r['s3']['object']['key'])
                
                key = r['s3']['object']['key']
                Caboose.log("Processing #{key}")

                arr = key.split('_')
                media_category_id = arr.shift
                original_name = arr.join('_')                
                name = Caboose::Media.upload_name(original_name)
                                      
                m = Media.where(:media_category_id => media_category_id, :original_name => original_name, :name => name).first                  
                m = Media.create(:media_category_id => media_category_id, :original_name => original_name, :name => name, :processed => false) if m.nil?
                m.process                
      
              end
            end                  
          end
        end
      end
      render :json => true
    end
    
    # GET  /admin/sns/confirm
    # POST /admin/sns/confirm
    def admin_confirm      
      render :json => true
    end

    # PUT /admin/sns/:id
    def admin_update
      render :json => true
    end

    # DELETE /admin/sns/:id
    def admin_delete                        
      render :json => true
    end

  end
end
