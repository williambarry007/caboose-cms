module Caboose
  class VendorsController < Caboose::ApplicationController
        
    # GET /admin/vendors
    def admin_index
      return if !user_is_allowed('vendors', 'view')
      
      @pager = Caboose::Pager.new(params, {
        'site_id'   => @site.id,
        'name_like' => ''
      }, {
        'model'          => 'Caboose::Vendor',
        'sort'           => 'name',
        'desc'           => false,
        'base_url'       => '/admin/vendors',
        'items_per_page' => 25,
        'use_url_params' => false
      });
      
      @vendors = @pager.items
      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/vendors/:id
    def admin_edit
      return if !user_is_allowed('vendors', 'edit')
      @vendor = Vendor.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/vendors/:id/update
    def admin_update
      return if !user_is_allowed('vendors', 'edit')
      vendor = Vendor.find(params[:id])
      
      params.each do |name, value|
        case name
          when 'site_id'  then vendor.site_id  = value
          when 'name'     then vendor.name     = value
          when 'status'   then vendor.status   = value
          when 'featured' then vendor.featured = value
        end
      end
      
      render :json => { :success => vendor.save }
    end
    
    # POST /admin/vendors/:id/update/image
    def admin_update_image
      return if !user_is_allowed('vendors', 'edit')
      
      vendor = Vendor.find(params[:id])       
      vendor.image = params[:image]
      vendor.save
      
      resp = StdClass.new
      resp.attributes = { :image => { :value => vendor.image.url(:thumb) }}
      resp.success = vendor.save            
    end
    
    # GET /admin/vendors/new
    def admin_new
      return if !user_is_allowed('vendors', 'add')
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/vendors
    def admin_add
      return if !user_is_allowed('vendors', 'add')
      
      render :json => { :success => false, :message => 'Must define a name' } and return if params[:name].nil? || params[:name].empty?
      
      vendor = Vendor.new(
        :site_id => @site.id,
        :name    => params[:name],
        :status  => 'Active'
      )      
      render :json => { :success => vendor.save, :redirect => "/admin/vendors/#{vendor.id}" }
    end
    
    # DELETE /admin/vendors/:id
    def admin_delete      
      return if !user_is_allowed('vendors', 'delete')
      v = Vendor.find(params[:id])
      v.destroy
      
      resp = StdClass.new({
        'redirect' => '/admin/vendors'
      })
      render :json => resp
    end
    
    # GET /admin/vendors/options
    def options      
      render :json => Vendor.where(:site_id => @site.id).reorder(:name).all.collect{ |v| { :value => v.id, :text => v.name }}      
    end
    
    # GET /admin/vendors/status-options
    def status_options      
      render :json => [
        { :text => 'Active'   , :value => 'Active'   },
        { :text => 'Inactive' , :value => 'Inactive' },
        { :text => 'Deleted'  , :value => 'Deleted'  }
      ]      
    end    
    
  end
end

