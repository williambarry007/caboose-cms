module Caboose
  class VendorsController < Caboose::ApplicationController
    
    # GET /admin/vendors/status-options
    def status_options
      options = Array.new
      
      ['Active', 'Inactive', 'Deleted'].each do |status|
        options << {
          :text  => status,
          :value => status
        }
      end
      
      render :json => options
    end
    
    # GET /admin/vendors/new
    def admin_new
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/vendors/create
    def admin_create
      render :json => { :success => false, :message => 'Must define a name' } and return if params[:name].nil? || params[:name].empty?
      
      vendor        = Vendor.new
      vendor.name   = params[:name]
      vendor.status = 'Inactive'
      
      render :json => { :success => vendor.save, :redirect => "/admin/vendors/#{vendor.id}/edit" }
    end
    
    # GET /admin/vendors
    def admin_index
      @pager = Caboose::Pager.new(params, {
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
    
    # GET /admin/vendors/:id/edit
    def admin_edit
      @vendor = Vendor.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/vendors/:id/update
    def admin_update
      vendor = Vendor.find(params[:id])
      
      params.each do |name, value|
        case name
          when 'name'   then vendor.name   = value
          when 'status' then vendor.status = value
        end
      end
      
      render :json => { :success => vendor.save }
    end
  end
end

