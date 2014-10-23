module Caboose
  class StackableGroupsController < Caboose::ApplicationController  

    # GET /admin/stackable-groups
    def admin_index
      return if !user_is_allowed('products', 'view')      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/stackable-groups/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      pager = Caboose::PageBarGenerator.new(params, {
        'name'  => ''        
      }, {
        'model'          => 'Caboose::StackableGroup',
        'sort'           => 'name',
        'desc'           => false,
        'base_url'       => '/admin/stackable-groups',
        'items_per_page' => 25,
        'use_url_params' => false        
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      }      
    end        
    
    # GET /admin/stackable-groups/:id/json
    def admin_json_single
      sg = StackableGroup.find(params[:id])
      render :json => sg      
    end    
      
    # PUT /admin/stackable-groups/:id
    def admin_update
      return if !user_is_allowed('products', 'edit')
      
      resp = Caboose::StdClass.new
      sg = StackableGroup.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'name'           then sg.name          = value
          when 'extra_length'   then sg.extra_length  = value.to_f
          when 'extra_width'    then sg.extra_width   = value.to_f
          when 'extra_height'   then sg.extra_height  = value.to_f
          when 'max_length'     then sg.max_length    = value.to_f
          when 'max_width'      then sg.max_width     = value.to_f
          when 'max_height'     then sg.max_height    = value.to_f                      
        end
      end
      resp.success = save && sg.save
      render :json => resp
    end
    
    # POST /admin/stackable-groups
    def admin_add
      return if !user_is_allowed('products', 'add')
      
      resp = Caboose::StdClass.new      
      name = params[:name]
      
      if name.length == 0
        resp.error = "The title cannot be empty."
      elsif StackableGroup.where(:name => name).exists?
        resp.error = "A stackable group with that name already exists."
      else
        sg = StackableGroup.new(:name => name)
        sg.save
        resp.refresh = true
      end
      render :json => resp    
    end
    
    # DELETE /admin/stackable-groups/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      StackableGroup.find(params[:id]).destroy      
      render :json => true      
    end
    
    # DELETE /admin/stackable-groups/bulk
    def admin_bulk_delete
      return if !user_is_allowed('products', 'delete')
      params[:model_ids].each do |sg_id|
        sg = StackableGroup.where(:id => sg_id).first
        sg.destroy if sg
      end          
      render :json => { :success => true }
    end
    
    # GET /admin/stackable-groups/options
    def admin_options      
      options = StackableGroup.reorder(:name).all.collect do |sg|
        {
          :value => sg.id,
          :text => sg.name
        }
      end
      render :json => options
    end
        
  end
end
