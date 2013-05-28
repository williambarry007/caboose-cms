
module Caboose
  class AdminController < ApplicationController
      
    # GET /admin
    def index
      return if !user_is_allowed('admin', 'view')
      
      @mods = [
        { 'href' => '/admin/users'        , 'text' => 'Users' },
        { 'href' => '/admin/roles'        , 'text' => 'Roles' },
        { 'href' => '/admin/permissions'  , 'text' => 'Permissions' }
      ]
      @mods = Caboose.plugin_hook('admin_nav', @mods)
      
    end
    
    # GET /station
    def station
      @user = logged_in_user
      render :layout => 'caboose/station'
    end
    
  end
end
