
module Caboose
  class ImagesController < ApplicationController
    
    helper :application
    
    def before_action
      @page = Page.page_with_uri(request.host_with_port, '/admin')
    end    
    
    # GET /admin/images
    def admin_index
      return if !user_is_allowed('images', 'view')            
      @domain = Domain.where(:domain => request.host_with_port).first
      @media_category = @domain ? MediaCategory.top_image_category(@domain.site_id) : nil    
      render :layout => 'caboose/admin'      
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
      @page = Page.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/images
    def admin_add
      return unless user_is_allowed('images', 'add')

      resp = Caboose::StdClass.new({
          'error' => nil,
          'redirect' => nil
      })
            
      parent_id = params[:parent_id]
      title = params[:title]      

      if (title.strip.length == 0)
        resp.error = "A page title is required."
      elsif (!logged_in_user.is_allowed('all', 'all') && 
        !Page.page_ids_with_permission(logged_in_user, 'edit'   ).include?(parent_id) &&
        !Page.page_ids_with_permission(logged_in_user, 'approve').include?(parent_id))
        resp.error = "You don't have permission to add a page there."
      end
      if (!resp.error.nil?)
        render :json => resp
        return
      end
      	
      parent = Caboose::Page.find(parent_id)                  		
      page = Caboose::Page.new
      
      if parent.nil?
        d = Domain.where(:domain => request.host_with_port).first.site_id
        page.site_id = d.site_id
      else      
        page.site_id = parent.site_id
      end
      
      page.title = title
      page.parent_id = parent_id      
      page.hide = true
      page.content_format = Caboose::Page::CONTENT_FORMAT_HTML

      i = 0
      begin 
        page.slug = Page.slug(page.title + (i > 0 ? " #{i}" : ""))
        page.uri = parent.parent_id == -1 ? page.slug : "#{parent.uri}/#{page.slug}"
        i = i+1
      end while (Page.where(:uri => page.uri).count > 0 && i < 10)

      page.save
      
      # Create the top level block for the page
      bt = BlockType.find(params[:block_type_id])
      Block.create(:page_id => page.id, :block_type_id => params[:block_type_id], :name => bt.name)
      
      # Set the new page's permissions		  
      viewers = Caboose::PagePermission.where({ :page_id => parent.id, :action => 'view' }).pluck(:role_id)
      editors = Caboose::PagePermission.where({ :page_id => parent.id, :action => 'edit' }).pluck(:role_id)
      Caboose::Page.update_authorized_for_action(page.id, 'view', viewers)
      Caboose::Page.update_authorized_for_action(page.id, 'edit', editors)

      # Send back the response
      resp.redirect = "/admin/images/#{page.id}/edit"
      render json: resp
    end
    
    # PUT /admin/images/:id
    def admin_update
      return unless user_is_allowed('images', 'edit')
      
      resp = StdClass.new({'attributes' => {}})
      page = Page.find(params[:id])
      
      save = true
      user = logged_in_user
      params.each do |name, value|
        case name
        when 'parent_id'
          value = value.to_i
          if page.id == value
            resp.error = "The page's parent cannot be itself."
          elsif Page.is_child(page.id, value)
            resp.error = "You can't set the current page's parent to be one of its child pages."
          elsif value != page.parent_id
            p = Page.find(value)
            if !user.is_allowed(p, 'edit')
              resp.error = "You don't have access to put the current page there."
            end
          end	
          if resp.error
            save = false
          else
            page.parent = Page.find(value)
            page.save
            Page.update_uri(page)
            resp.attributes['parent_id'] = { 'text' => page.parent.title }
          end

        when 'custom_css', 'custom_js'
          value.strip!
          page[name.to_sym] = value

        when 'title', 'menu_title', 'hide', 'layout', 'redirect_url',
          'seo_title', 'meta_description', 'fb_description', 'gp_description', 'canonical_url'
          page[name.to_sym] = value

        when 'linked_resources'
          result = []
          value.each_line do |line|
            line.chomp!
            line.strip!
            next if line.empty?

            if !(line.ends_with('.js') || line.ends_with('.css'))
              resp.error = "Resource '#{line}' has an unsupported file type ('#{comps.last}')."
              save = false
            end

            result << line
          end
          page.linked_resources = result.join("\n")
          
        when 'content_format'
          page.content_format = value
          resp.attributes['content_format'] = { 'text' => value }
          
        when 'meta_robots'
          if (value.include?('index') && value.include?('noindex'))
            resp.error = "You can't have both index and noindex"
            save = false
          elsif (value.include?('follow') && value.include?('nofollow'))
            resp.error = "You can't have both follow and nofollow"
            save = false
          else
            page.meta_robots = value.join(', ')
            resp.attributes['meta_robots'] = { 'text' => page.meta_robots }
          end
          
        when 'content'
          page.content = value.strip.gsub(/<meta.*?>/, '').gsub(/<link.*?>/, '').gsub(/\<\!--[\S\s]*?--\>/, '')
          
        when 'slug' 
          page.slug = Page.slug(value.strip.length > 0 ? value : page.title)
          page.save
          Page.update_uri(page)                      
          resp.attributes['slug'] = { 'value' => page.slug }
          resp.attributes['uri'] = { 'value' => page.uri }
          
        when 'alias'
          page.alias = Page.slug(value.strip)
          page.save
          Page.update_uri(page)
          resp.attributes['slug'] = { 'value' => page.slug }
          resp.attributes['uri'] = { 'value' => page.uri }

        when 'custom_sort_children'
          if (value == 0)
            page.children.each do |p|
              p.sort_order = 1
              p.save
            end
          end
          page.custom_sort_children = value 		  

        when 'viewers'
          Page.update_authorized_for_action(page.id, 'view', value)
        when 'editors'
          Page.update_authorized_for_action(page.id, 'edit', value)
        when 'approvers'
          Page.update_authorized_for_action(page.id, 'approve', value)
        end
      end
    
      resp.success = save && page.save
      render json: resp
    end
    
    # DELETE /admin/images/1
    def admin_delete
      return unless user_is_allowed('images', 'delete')
      p = Page.find(params[:id])
      p.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/images'
      })
      render json: resp
    end       
    
    ## PUT /admin/images/sign-s3
    #def admin_sign_s3
    #  return unless user_is_allowed('images', 'add')
    #        
    #  config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]      
    #  access_key = config['access_key_id']
    #  secret_key = config['secret_access_key']
    #  bucket     = config['bucket']
    #  s3 = AWS::S3.new(
    #    :access_key_id => access_key,
    #    :secret_access_key => secret_key
    #  )
    #  
    #  name = params[:name]      
    #  mi = MediaImage.create(
    #    :media_category_id => params[:media_category_id], 
    #    :name => params[:name]
    #  )      
    #  pp = s3.buckets[bucket].presigned_post(              
    #    :key => "media-images/test.jpg", #{mi.id}.#{File.extname(name)}",
    #    :expires => DateTime.now + 10.seconds,
    #    :success_action_status => 201, 
    #    :acl => :public_read
    #  )
    #  
    #  render :json => {
    #    'media_image' => mi,
    #    'presigned_post' => {
    #      'url' => pp.url.to_s,
    #      'fields' => pp.fields
    #    }
    #  }
    #  
    #  #expires = (DateTime.now.utc + 10.seconds).to_i
    #  #amz_headers = "x-amz-acl:public-read"      
    #  #put_request = "PUT\n\n#{mime_type}\n#{expires}\n#{amz_headers}\n/#{bucket}/media-images/#{object_name}"
    #  #signature = CGI.escape(Base64.encode64("#{OpenSSL::HMAC.digest('sha1', secret_key, put_request)}\n"))      
    #  ##signature = base64.encodestring(hmac.new(secret_key, put_request, sha1).digest())
    #  ##signature = urllib.quote_plus(signature.strip())
    #  #render :json => {
    #  #  'signed_request' => "#{url}?AWSAccessKeyId=#{access_key}&Expires=#{expires}&Signature=#{signature}",
    #  #  'url' => url
    #  #}
    #
    #  #pp = AWS::S3::PresignedPost.new(s3.buckets[bucket], 
    #  #  :key => "media-images/#{object_name}",
    #  #  :expires => DateTime.now + 10.seconds,
    #  #  :content_type => mime_type
    #  #)            
    #  #url = "#{pp.url.to_s}#{pp.key}" #"https://#{pp.bucket.name}.s3.amazonaws.com/#{pp.key}"
    #  #render :json => {
    #  #  'signed_request' => "#{url}?AWSAccessKeyId=#{access_key}&Expires=#{pp.expires.to_time.to_i}&Signature=#{pp.fields[:signature]}",
    #  #  'url' => url
    #  #}                              
    #  
    #end
         
    def admin_sign_s3
      @document = Document.create(params[:doc])
      
      policy = {"expiration" => 10.seconds.from_now.utc.xmlschema,
        "conditions" =>  [
          {"bucket" => 'cabooseit'},           
          {"acl" => "public-read"},
          {"success_action_status" => "200"}          
        ]
      }
      policy = Base64.encode64(policy.to_json).gsub(/\n/,'')
      
      render :json => {
        :policy => policy, 
        :signature => s3_upload_signature, 
        :key => @document.s3_key, 
        :success_action_redirect => document_upload_success_document_url(@document)
      }
    end
     
    def s3_upload_policy_document      
      ret = {"expiration" => 10.seconds.from_now.utc.xmlschema,
        "conditions" =>  [
          {"bucket" => 'cabooseit'},           
          {"acl" => "public-read"},
          {"success_action_status" => "200"}          
        ]
      }
      return Base64.encode64(ret.to_json).gsub(/\n/,'')
    end
    
    # sign our request by Base64 encoding the policy document.
    def s3_upload_signature
      signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), 
        YOUR_SECRET_KEY, s3_upload_policy_document)).gsub("\n","")
    end
		
  end
end
