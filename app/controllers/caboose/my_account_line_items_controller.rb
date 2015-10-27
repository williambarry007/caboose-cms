module Caboose
  class MyAccountLineItemsController < Caboose::ApplicationController
            
    # GET /my-account/orders/:order_id/line-items
    def index
      return if !verify_logged_in      
      @order = Order.find(params[:order_id])
      if @order.customer_id != logged_in_user.id
        @error = "The given order does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end
    end
      
    # GET /my-account/orders/:order_id/line-items/:id
    def edit
      return if !verify_logged_in
      
      @order = Order.find(params[:order_id])
      @line_item = LineItem.find(params[:id])
      if @order.customer_id != logged_in_user.id
        @error = "The given order does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end      
    end
    
    # GET /my-account/orders/:order_id/line-items/:id/download
    def download
      return if !verify_logged_in
      
      order = Order.find(params[:order_id])      
      if order.customer_id != logged_in_user.id
        @error = "The given order does not belong to you."
        render :file => 'caboose/extras/error'
        return
      end
      
      li = LineItem.find(params[:id])
      if !li.variant.downloadable
        render :text => "Not a downloadable file."
        return
      end
      
      # Generate the download URL and redirect to it
      sc = @site.store_config              
      config = YAML.load_file("#{::Rails.root}/config/aws.yml")
      AWS.config({ 
        :access_key_id => config[Rails.env]['access_key_id'],
        :secret_access_key => config[Rails.env]['secret_access_key']  
      })          
      bucket = AWS::S3::Bucket.new(config[Rails.env]['bucket'])
      s3object = AWS::S3::S3Object.new(bucket, li.variant.download_path)
      url = s3object.url_for(:read, :expires => sc.download_url_expires_in.to_i.minutes).to_s

      redirect_to url
    end
             
  end
end
