module Caboose
  class ApplicationController < ActionController::Base

    protect_from_forgery  
    before_filter :before_before_action
    helper_method :logged_in?
    helper :all
    
    @find_page = true
    
    def before_before_action
      
      # Modify the built-in params array with URL params if necessary
      parse_url_params if Caboose.use_url_params
      
   #   @use_page_cache = !request.fullpath.starts_with?('/admin')
            
      # Get the site we're working with      
      @domain = Domain.where(:domain => request.host_with_port).first      
      @site = @domain ? @domain.site : nil      
      if @domain.nil? || @site.nil?
        Caboose.log("Error: No site configured for #{request.host_with_port}")
      end
      
      # Set the site in any mailers
      CabooseMailer.site = @site
        
      # Make sure someone is logged in
      if !logged_in? && @site                
        elo = User.logged_out_user(@site.id)        
        login_user(elo) if elo
      end
      
      session['use_redirect_urls'] = true if session['use_redirect_urls'].nil?
      
      # Initialize AB Testing
      AbTesting.init(request.session_options[:id]) if Caboose.use_ab_testing            
      
      # Try to find the page
      @request = request      
      @page = Page.new
      @crumbtrail = Crumbtrail.new      
      @subnav       = {}
      @actions      = {}
      @tasks        = {}
      @page_tasks   = {}
      @is_real_page = false
      @ga_events    = []      
      
      #if @find_page
        @page = Page.page_with_uri(request.host_with_port, request.fullpath)
    #    @crumb_trail  = Caboose::Page.crumb_trail(@page)		    
      #end


      
      # Sets an instance variable of the logged in user
      @logged_in_user = logged_in_user  

      @nav = Caboose.plugin_hook('admin_nav', [], @logged_in_user, @page, @site) if request.fullpath.include?('/admin')
      
      # Initialize the card
      init_cart if @site && @site.use_store && !@domain.under_construction
      
      before_action
    end
    
    # Initialize the cart in the session
    def init_cart            
      # Check if the cart ID is defined and that it exists in the database
      create_new_invoice = false
      if session[:cart_id]
        @invoice = Caboose::Invoice.where(:id => session[:cart_id]).first
        create_new_invoice = true if @invoice.nil? || @invoice.status != 'cart'                    
      else                        
        create_new_invoice = true                         
      end

      if create_new_invoice # Create an invoice to associate with the session        
        @invoice = Caboose::Invoice.new        
        @invoice.site_id          = @site ? @site.id : nil
        @invoice.status           = Caboose::Invoice::STATUS_CART
        @invoice.financial_status = Caboose::Invoice::STATUS_PENDING
        @invoice.date_created     = DateTime.now
        @invoice.referring_site   = request.env['HTTP_REFERER']
        @invoice.landing_page     = request.fullpath
        @invoice.landing_page_ref = params[:ref] || nil
        @invoice.payment_terms    = @site.store_config.default_payment_terms
        @invoice.save
        
        InvoiceLog.create(
          :invoice_id     => @invoice.id,          
          :user_id        => logged_in_user.id,
          :date_logged    => DateTime.now.utc,
          :invoice_action => InvoiceLog::ACTION_INVOICE_CREATED                
        )
        
        # Save the cart ID in the session
        session[:cart_id] = @invoice.id
      end                  
    end
    
    def add_ga_event(cat, action, label = nil, value = nil)
      # Category String Required  Typically the object that was interacted with (e.g. button)
      # Action   String Required  The type of interaction (e.g. click)
      # Label    String Option    Useful for categorizing events (e.g. nav buttons)
      # Value    Number Option    Values must be non-negative. Useful to pass counts (e.g. 4 times)
      @ga_events << [cat, action, label, value]
    end

    # Parses any parameters in the URL and adds them to the params
    def parse_url_params      
      return if !Caboose.use_url_params      
      url = "#{request.fullpath}"
      url[0] = "" if url.starts_with?('/')      
      url = url.split('?')[0] if url.include?('?')      
      arr = url.split('/')      
      i = arr.count - 1
      while i >= 1 do
        k = arr[i-1]
        v = arr[i]    
        if v && v.length > 0
          v = v.gsub('%20', ' ')
          params[k] = v
        end
        i = i-2
      end      
    end
    
    # To be overridden by the child controllers
    def before_action      
    end
    
    # Logs a user out
    def logout_user
      cookies.delete(:caboose_user_id)
      session["app_user"] = nil
      reset_session
    end
      
    # Logs in a user
    def login_user(user, remember = false)
      session["app_user"] = Caboose::StdClass.new({      
        :id         => user.id         ,
        :site_id    => user.site_id    ,
        :first_name => user.first_name ,
        :last_name  => user.last_name  ,
        :username   => user.username   ,
        :email      => user.email                             
      })  
      cookies.permanent[:caboose_user_id] = user.id if remember
    end
    
    # Returns whether or not a user is logged in
    def logged_in?
      validate_token
      validate_cookie
      return true if !session["app_user"].nil? && session["app_user"] != false && session["app_user"].id != -1 && session["app_user"].id != User.logged_out_user_id(@site.id)
      return false
    end
    
    # Checks to see if a token is given. If so, it tries to validate the token 
    # and log the user in.
    def validate_token
      token = params[:token]
      return false if token.nil?
      
      user = User.validate_token(token)
      return false if user.nil?
     
      login_user(user)
      return true
    end
    
    # Checks to see if a remember me cookie value is present.    
    def validate_cookie     
      if cookies[:caboose_user_id]
        user = User.where(:id => cookies[:caboose_user_id]).first
        if user        
          login_user(user)
          return true
        end
      end
      return false
    end
    
    # Returns the currently logged in user
    def logged_in_user
      if (!logged_in?)
        return User.logged_out_user(@site.id)
      end
      #return nil if !logged_in?
      return Caboose::User.where(:id => session["app_user"].id).first
    end
    
    # DEPRECATED: Use user_is_allowed_to(action, resource)
    #
    # Checks to see if a user has permission to perform the given action 
    # on the given resource.
    # Redirects to login if not logged in.
    # Redirects to error page with message if not allowed.
    def user_is_allowed(resource, action, json = false)
      if !logged_in?
        if json
          render :json => false
        else
          redirect_to "/login?return_url=" + URI.encode(request.fullpath)
        end
        return false
      end
      
      @user = logged_in_user
      if !@user.is_allowed(resource, action)        
        if json
          render :json => false
        else
          @error = "You don't have permission to " + action + " " + resource
          @return_url = request.fullpath
          render :template => "caboose/extras/error"
        end
        return false
      end
      
      return true    
    end

    # Checks to see if a user has permission
    # to perform action on resource
    #
    # Redirects to login if not logged in
    # Redirects to error page with message if not allowed
    #
    # useful for creating super-readable code, for example:
    #   > return unless user_is_allowed_to 'edit', 'pages'
    # Even your mom could read that code.
    def user_is_allowed_to(action, resource, json = false)
      unless logged_in?
        if json
          render :json => { :error => 'Not logged in.' }
        else
          redirect_to "/login?return_url=" + URI.encode(request.fullpath)
        end
        return false
      end

      @user = logged_in_user
      unless @user.is_allowed(resource, action)
        if json
          render :json => { :error => "You don't have permission." }
        else          
          @error = "You don't have permission to #{action} #{resource}"
          @return_url = request.fullpath
          render :template => "caboose/extras/error"
        end
        return false
      end
      return true
    end

    # Redirects to login if not logged in.
    def verify_logged_in
      if !logged_in?
        redirect_to "/modal/login?return_url=" + URI.encode(request.fullpath)
        return false
      end      
      return true    
    end
    
    # Removes a given parameter from a URL querystring
    def reject_param(url, param)
      arr = url.split('?')
      return url if (arr.count == 1)
      qs = arr[1].split('&').reject { |pair| pair.split(/[=;]/).first == param }
      url2 = arr[0]
      url2 += "?" + qs.join('&') if qs.count > 0 
      return url2
    end
    
    #def auth_or_error(message)
    #  if (!logged_in?)
    #    redirect_to "/login?return_url=#{request.request_uri}" and return false
    #  end
    #  redirect_to "/error?message=#{message}"
    #end
    
    def var(name)
      s = Setting.where(:name => name).first
      return "" if s.nil?    
      return s.value
    end
    
    # Redirects/Converts querystrings into hashes    
    def hashify_query_string
      if request.query_string && request.query_string.length > 0
        redirect_to request.url.gsub('?', '#')
        return true
      end
      return false
    end
    
    # Standard methods used by model binder
    def admin_index()       raise 'This method should be overridden.' end
    def admin_json()        raise 'This method should be overridden.' end
    def admin_json_single() raise 'This method should be overridden.' end
    def admin_edit()        raise 'This method should be overridden.' end
    def admin_update()      raise 'This method should be overridden.' end
    def admin_bulk_update() raise 'This method should be overridden.' end        
    def admin_add()         raise 'This method should be overridden.' end    
    def admin_bulk_add()    raise 'This method should be overridden.' end
    def admin_delete()      raise 'This method should be overridden.' end
    def admin_bulk_delete() raise 'This method should be overridden.' end
      
    # Make sure we're not under construction or on a forwarded domain
    def under_construction_or_forwarding_domain?
            
      d = Caboose::Domain.where(:domain => request.host_with_port).first
      if d.nil?
        Caboose.log("Could not find domain for #{request.host_with_port}\nAdd this domain to the caboose site.")
      elsif d.under_construction == true
        if d.site.under_construction_html && d.site.under_construction_html.strip.length > 0 
          render :text => d.site.under_construction_html
        else 
          render :file => 'caboose/application/under_construction', :layout => false
        end
        return true
      # See if we're on a forwarding domain
      elsif d.primary == false && d.forward_to_primary == true
        pd = d.site.primary_domain
        if pd && pd.domain != request.host
          url = "#{request.protocol}#{pd.domain}"
          if d.forward_to_uri && d.forward_to_uri.strip.length > 0
            url << d.forward_to_uri
          elsif request.fullpath && request.fullpath.strip.length > 0 && request.fullpath.strip != '/'
            url << request.fullpath
          end
          redirect_to url
          return true
        end
      # Check for a 301 redirect
      else
        new_url = PermanentRedirect.match(@site.id, request.fullpath)        
        if new_url
          redirect_to new_url, :status => 301
          return true
        end        
      end
      return false
    end
            
  end
end
