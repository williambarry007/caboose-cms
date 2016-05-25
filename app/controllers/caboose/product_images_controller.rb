module Caboose
  class ProductImagesController < Caboose::ApplicationController  
      
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # @route GET /admin/product-images/:id/variant-ids  
    def admin_variant_ids
      return if !user_is_allowed('variants', 'edit')
      img = ProductImage.find(params[:id])
      ids = img.variants.collect{ |v| v.id }
      render :json => ids
    end
    
    # @route GET /admin/product-images/:id/variants  
    def admin_variants
      return if !user_is_allowed('variants', 'edit')
      img = ProductImage.find(params[:id])    
      render :json => img.variants
    end
    
    # @route DELETE /admin/product-images/:id  
    def admin_delete
      return if !user_is_allowed('variants', 'delete')
      img = ProductImage.find(params[:id]).destroy    
      render :json => true
    end
  
    # @route GET /variant-images/:id
    def variant_images
      var = Variant.find(params[:id])
      img = var.product_images.first
      render :json => img
    end
    
    # @route PUT /admin/product-images/sort-order
    def admin_update_sort_order
      return if !user_is_allowed('products', 'edit')
            
      ids = params[:product_image_ids]            
      ids.each_with_index do |id, i|
        ProductImage.find(id).update_attribute(:position, i)
      end
      render :json => { :success => true }
    end
  
  end
end
