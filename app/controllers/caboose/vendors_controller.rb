module Caboose
  class VendorsController < Caboose::ApplicationController
        
    # GET /admin/vendors
    def admin_index
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
      @vendor = Vendor.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/vendors/:id/update
    def admin_update
      vendor = Vendor.find(params[:id])
      
      params.each do |name, value|
        case name
          when 'site_id' then vendor.site_id = value
          when 'name'    then vendor.name    = value
          when 'status'  then vendor.status  = value
        end
      end
      
      render :json => { :success => vendor.save }
    end
    
    # GET /admin/vendors/new
    def admin_new
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/vendors
    def admin_add
      render :json => { :success => false, :message => 'Must define a name' } and return if params[:name].nil? || params[:name].empty?
      
      vendor = Vendor.new(
        :site_id => @site.id,
        :name    => params[:name],
        :status  => 'Inactive'
      )      
      render :json => { :success => vendor.save, :redirect => "/admin/vendors/#{vendor.id}" }
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

