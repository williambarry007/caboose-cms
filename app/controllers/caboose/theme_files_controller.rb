module Caboose
class ThemeFilesController < ApplicationController
  layout 'caboose/admin'

  # @route GET /admin/theme-files
  def admin_index
    return unless (user_is_allowed_to 'view', 'theme_files')            
  end

  # @route POST /admin/theme-files
  def admin_add
    return unless (user_is_allowed_to 'edit', 'theme_files')
    resp = Caboose::StdClass.new
    c = Caboose::ThemeFile.new
    c.nice_name = params[:nice_name]
    c.save
    resp.redirect = "/admin/theme-files/#{c.id}"
    render :json => resp
  end

  # @route GET /admin/theme-files/json
  def admin_json 
    render :json => false and return if !user_is_allowed_to 'view', 'theme_files'
    pager = Caboose::Pager.new(params, {
      'nice_name_like' => ''
    }, {
      'model' => 'Caboose::ThemeFile',
      'sort'  => 'nice_name',
      'desc'  => 'false',
      'base_url' => '/admin/theme-files',
      'items_per_page' => 50
    })
    render :json => {
      :pager => pager,
      :models => pager.items
    } 
  end

  # @route GET /admin/theme-files/:id/json
  def admin_json_single
    render :json => false and return if !user_is_allowed_to 'edit', 'theme_files'
    prop = Caboose::ThemeFile.find(params[:id])
    render :json => prop
  end
  
  # @route GET /admin/theme-files/:id
  def admin_edit
    if !user_is_allowed_to 'edit', 'theme_files'
      Caboose.log("invalid permissions")
    else
      @themefile = Caboose::ThemeFile.where(:id => params[:id]).first
    end
  end

  # @route PUT /admin/theme-files/:id/sass
  def admin_update_sass
    return if !user_is_allowed('edit', 'theme_files')
    resp = StdClass.new  
    @themefile = ThemeFile.find(params[:id])
    @themefile.code = params['code']
    @themefile.save
    resp.success = true
    resp.message = "Code has been saved!"
    render :json => resp
  end
    
  # @route PUT /admin/theme-files/:id
  def admin_update
    return unless (user_is_allowed_to 'edit', 'theme_files')
    resp = Caboose::StdClass.new
    theme_files = params[:id] == 'bulk' ? params[:model_ids].collect{ |rid| Caboose::ThemeFile.find(rid) } : [Caboose::ThemeFile.find(params[:id])] 
    user = logged_in_user
    if user
      params.each do |k,v|
        case k
          when "filename" then theme_files.each { |r| r.filename = v }
          when "nice_name" then theme_files.each { |r| r.nice_name = v }
          when "default_included" then theme_files.each { |r| r.default_included = v }
        end
      end
      theme_files.each do |r|
        r.save
      end
      resp.success = true
    end
    render :json => resp
  end

  # @route DELETE /admin/theme-files/bulk
  def admin_bulk_delete
    return unless user_is_allowed_to 'delete', 'theme_files'
    params[:model_ids].each do |rc_id|
      prop = Caboose::ThemeFile.where(:id => rc_id).first
      prop.destroy
    end
    resp = Caboose::StdClass.new('success' => true)
    render :json => resp
  end
  
  # @route DELETE /admin/theme-files/:id
  def admin_delete
    return unless user_is_allowed_to 'delete', 'theme_files'
    prop = Caboose::ThemeFile.find(params[:id])    
    resp = Caboose::StdClass.new('redirect' => "/admin/theme-files")
    prop.destroy
    render :json => resp
  end

end
end