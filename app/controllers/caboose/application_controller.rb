module Caboose
  class ApplicationController < ActionController::Base

    protect_from_forgery  
    before_filter :before_before_action
    
    def before_before_action
      
      # Modify the built-in params array with URL params if necessary 
      parse_url_params if Caboose.use_url_params
      
      # Try to find the page 
      @page = Page.page_with_uri(request.fullpath)
      
      session['use_redirect_urls'] = true if session['use_redirect_urls'].nil?
      assign_ab_variants
      
      @crumb_trail  = Caboose::Page.crumb_trail(@page)
		  @subnav       = {}
      @actions      = {}
      @tasks        = {}
      @page_tasks   = {}
      @is_real_page = false
      
      # Sets an instance variable of the logged in user
      @logged_in_user = logged_in_user

      Caboose.log session
      
      before_action
    end

    # sets the ab_variants for the user's session
    def assign_ab_variants
      unless session['ab_variants']
        session['ab_variants'] = Hash.new()
        session['analytics_string'] = "|"
        AbVariant.find_each do |var|
          opt = var.get_session_option
          session['ab_variants'][var.analytics_name] = opt[:text]
          session['analytics_string'] = session['analytics_string'] + "#{var.analytics_name}=#{opt[:id]}|"
        end
      end
    end

    # finds and returns the variant option for the session. if 
    # no variant option is found (for example, if new variants were
    # added during a user's session), create a variant option for 
    # the session
    def get_ab_option_for(analytics_name)
      # we don't need a new variant if it's been assigned.
      unless session['ab_variants'][variant_name]
        # get the variant
        var = AbVariant.find(analytics_name: variant_name).first
        # get an option for it
        opt = var.get_session_option
        # set the variants hash to the text
        session['ab_variants'][var.analytics_name] = opt[:text]
        # add to the analytics string
        session['analytics_string'] = session['analytics_string'] + "#{var.analytics_name}=#{opt[:id]}|"
      end

      return session['ab_variants'][variant_name]
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
        params[k] = v if v && v.length > 0
        i = i-2
      end      
    end
    
    # To be overridden by the child controllers
    def before_action      
    end
    
    # Logs in a user
    def login_user(user, remember = false)
      session["app_user"] = user
      cookies.permanent[:caboose_user_id] = user.id if remember
    end
    
    # Returns whether or not a user is logged in
    def logged_in?
      validate_token
      validate_cookie
      return true if !session["app_user"].nil? && session["app_user"] != false && session["app_user"].id != -1    
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
      if cookies[:caboose_user_id] && User.exists?(cookies[:caboose_user_id])
        user = User.find(cookies[:caboose_user_id])
        login_user(user)
        return true
      end
      return false
    end
    
    # Returns the currently logged in user
    def logged_in_user
      if (!logged_in?)
        return User.logged_out_user
      end
      #return nil if !logged_in?
      return session["app_user"]
    end
    
    # DEPRECATED: Use user_is_allowed_to(action, resource)
    #
    # Checks to see if a user has permission to perform the given action 
    # on the given resource.
    # Redirects to login if not logged in.
    # Redirects to error page with message if not allowed.
    def user_is_allowed(resource, action)
      if (!logged_in?)
        redirect_to "/login?return_url=" + URI.encode(request.fullpath)
        return false
      end
      
      @user = logged_in_user
      if (!@user.is_allowed(resource, action))
        @error = "You don't have permission to " + action + " " + resource
        render :template => "caboose/extras/error"
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
    def user_is_allowed_to(action, resource)
      unless logged_in?
        redirect_to "/login?return_url=" + URI.encode(request.fullpath)
        return false
      end

      @user = logged_in_user
      unless @user.is_allowed(resource, action)
        @error = "You don't have permission to #{action} #{resource}"
        render :template => "caboose/extras/error"
        return false
      end
      return true
    end

    # Redirects to login if not logged in.
    def verify_logged_in
      if (!logged_in?)
        redirect_to "/login?return_url=" + URI.encode(request.fullpath)
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
    
    def var(key)
      v = Var.where(:key => key).first
        return "" if v.nil?    
      return v.val
    end
  end
end
