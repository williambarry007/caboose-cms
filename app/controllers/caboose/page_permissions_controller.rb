
module Caboose
  class PagePermissionsController < ApplicationController
    
    # @route POST /admin/page-permissions
    def admin_add
      return unless user_is_allowed('pages', 'add')

      resp = Caboose::StdClass.new      
      page_id = params[:page_id]
      role_id = params[:role_id]
      action = params[:action2]
      
      if !PagePermission.where(:page_id => page_id, :role_id => role_id, :action => action).exists?
        PagePermission.create(:page_id => page_id, :role_id => role_id, :action => action)
      end
      
      resp.success = true      
      render :json => resp
    end

    # @route DELETE /admin/page-permissions
    # @route DELETE /admin/page-permissions/:id
    def admin_delete
      return unless user_is_allowed('pages', 'edit')

      if params[:id]
        PagePermission.find(params[:id]).destroy
      else        
        PagePermission.where(:page_id => params[:page_id], :role_id => params[:role_id], :action => params[:action2]).destroy_all
      end
            
      resp = StdClass.new('success' => true)        
      render :json => true
    end
		
  end
end
