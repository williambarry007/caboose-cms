module Caboose
  class VariantChildrenController < Caboose::ApplicationController
    
    #=============================================================================
    # Admin actions
    #=============================================================================
            
    # @route GET /admin/products/:product_id/variants/:variant_id/children/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      pager = Caboose::PageBarGenerator.new(params, {
        'parent_id'      => params[:variant_id]        
      }, {
        'model'          => 'Caboose::VariantChild',
        'sort'           => 'parent_id',
        'desc'           => false,
        'base_url'       => "/admin/products/#{params[:product_id]}/variants/#{params[:variant_id]}/children",
        'items_per_page' => 100,
        'use_url_params' => false        
      })
      render :json => {
        :pager => pager,
        :models => pager.items.as_json(:include => { :variant => { :methods => :full_title }})
      }      
    end
    
    # @route GET /admin/products/:product_id/variants/:variant_id/children/:id/json
    def admin_json_single
      return if !user_is_allowed('products', 'view')
      
      vc = VariantChild.find(params[:id])      
      render :json => vc.as_json(:include => { :variant => { :methods => :full_title }})      
    end
    
    # @route POST /admin/products/:product_id/variants/:parent_id/children
    def admin_add      
      resp = Caboose::StdClass.new

      VariantChild.create(
        :parent_id  => params[:parent_id],
        :variant_id => params[:variant_id],
        :quantity   => params[:quantity] ? params[:quantity] : 1
      )
      resp.success = true      
      render :json => resp
    end

    # @route PUT /admin/products/:product_id/variants/:parent_variant_id/children/:id
    def admin_update
      return if !user_is_allowed('variants', 'edit')
      
      resp = Caboose::StdClass.new
      vcs = params[:id] == 'bulk' ? params[:model_ids].collect{ |model_id| VariantChild.find(model_id) } : [VariantChild.find(params[:id])]    
                
      params.each do |name,value|
        case name        
          when 'parent_id'  then vcs.each{ |vc| vc.alternate_id = value }
          when 'variant_id' then vcs.each{ |vc| vc.sku          = value }
          when 'quantity'   then vcs.each{ |vc| vc.barcode      = value }          
        end
      end
      vcs.each{ |vc| vc.save }
      resp.success = true
      render :json => resp
    end
      
    # @route DELETE /admin/products/:product_id/variants/:variant_id/children/:id
    def admin_delete
      return if !user_is_allowed('variants', 'delete')      
      vc_ids = params[:id] == 'bulk' ? params[:model_ids] : [params[:id]]
      vc_ids.each do |vc_id|
        VariantChild.where(:id => vc_id).destroy_all
      end
      render :json => { :success => true }      
    end
            
  end
end
