
module Caboose
  class ImagesController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end    
    
    # GET /admin/images
    def admin_index
      return if !user_is_allowed('images', 'view')
      render :file => 'caboose/extras/error_invalid_site' and return if @site.nil?
                  
      id = params[:media_category_id]        
      @media_category = id ? MediaCategory.find(id) : MediaCategory.top_image_category(@site.id)      
      render :layout => 'caboose/admin'      
    end
    
    # GET /admin/images/json
    def admin_json
      return if !user_is_allowed('images', 'view')
      render :json => false and return if @site.nil?
      
      id = params[:media_category_id]        
      cat = id ? MediaCategory.find(id) : MediaCategory.top_image_category(@site.id)      
      render :json => cat.api_hash
    end

    # GET /admin/images/new
    def admin_new
      return unless user_is_allowed('images', 'add')
      @media_category_id = params[:media_category_id]             
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/images/:id
    def admin_edit
      return unless user_is_allowed('images', 'edit')
      @media_image = MediaImage.find(params[:id])
      render :layout => 'caboose/admin'
    end
            
    # PUT /admin/images/:id
    def admin_update
      return unless user_is_allowed('images', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      image = MediaImage.find(params[:id])
      
      save = true      
      params.each do |name, value|
        case name
          when 'name'         then image.name         = value
          when 'description'  then image.description  = value          
        end
      end
    
      resp.success = save && image.save
      render :json => resp
    end
    
    # DELETE /admin/images/:id
    def admin_delete
      return unless user_is_allowed('images', 'delete')
      img = MediaImage.find(params[:id])      
      resp = StdClass.new({
        'redirect' => "/admin/images?media_category_id=#{img.media_category_id}"
      })
      img.destroy            
      render :json => resp
    end       
       
    # GET /admin/images/sign-s3
    def admin_sign_s3
      
      name = params[:name]      
      mi = MediaImage.create(
        :media_category_id => params[:media_category_id], 
        :name => params[:name]
      )
      key = "media-images/#{mi.id}#{File.extname(name)}".downcase
      
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]      
      access_key = config['access_key_id']
      secret_key = config['secret_access_key']
      bucket     = config['bucket']
      
      policy = {        
        "expiration" => 10.seconds.from_now.utc.xmlschema,
        "conditions" => [
          { "bucket" => bucket },
          ["starts-with", "$key", key],
          { "acl" => "public-read" },
          { "success_action_status" => "200" }
          #{ "success_action_redirect" => "/admin/images/s3-result" }          
        ]
      }
      policy = Base64.encode64(policy.to_json).gsub(/\n/,'')      
      signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret_key, policy)).gsub("\n","")
      
      render :json => {
        :media_image_id => mi.id,
        :url => "https://#{bucket}.s3.amazonaws.com",
        :fields => {
          :key                     => key,
          'AWSAccessKeyId'         => access_key,
          :acl                     => 'public-read',
          :success_action_status   => '200',
          #:success_action_redirect => '/admin/images/s3-result',
          :policy                  => policy, 
          :signature               => signature
        }
      }
      
    end
    
    def admin_s3_result
      render :layout => 'caboose/empty'      
    end
    
    # GET /admin/images/:id/process
    def admin_process
      return if !user_is_allowed('images', 'edit')
      mi = MediaImage.find(params[:id])      
      mi.delay.process
      render :json => true      
    end
    
    ## GET /admin/images/:id/finished
    def admin_process_finished      
      return if !user_is_allowed('images', 'edit')
      mi = MediaImage.find(params[:id])
      resp = StdClass.new
      if mi.image_file_name && mi.image_file_name.strip.length > 0
        resp.is_finished = true
        resp.tiny_url     = mi.image.url(:tiny)
        resp.thumb_url    = mi.image.url(:thumb)
        resp.large_url    = mi.image.url(:large)
        resp.original_url = mi.image.url(:original)
      else
        resp.is_finished = false
      end
      render :json => resp
    end
		
  end
end
