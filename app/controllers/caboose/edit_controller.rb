
module Caboose
  class EditController < ApplicationController
    
    helper :application    

    # GET /edit/.*
    def index
      return unless user_is_allowed('pages', 'add')
      
      # Find the page with an exact URI match 
      @page = Page.page_with_uri(request.fullpath.gsub('/edit'), false)

      @user = logged_in_user            
      if !user.is_allowed(@page, 'view')        
        if user.id == User::LOGGED_OUT_USER_ID	
          redirect_to "/modal/login?return_url=" + URI.encode(request.fullpath)		  		
          return
        else
          @page.title = 'Access Denied'          
        end
      end
            
      @editmode = !params['edit'].nil? && user.is_allowed('pages', 'edit') ? true : false
      @crumb_trail = Caboose::Page.crumb_trail(@page)
      @subnav = Caboose::Page.subnav(@page, session['use_redirect_urls'], @user)

      #@subnav.links = @tasks.collect {|href, task| {'href' => href, 'text' => task, 'is_current' => uri == href}}
      render :file ':layout => 'caboose/admin'
    end
		
  end
end
