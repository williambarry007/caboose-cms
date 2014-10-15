module Caboose
  class ProductImagesController < Caboose::ApplicationController  
      
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/product-images/:id/variant-ids  
    def admin_variant_ids
      return if !user_is_allowed('variants', 'edit')
      img = ProductImage.find(params[:id])
      ids = img.variants.collect{ |v| v.id }
      render :json => ids
    end
    
    # GET /admin/product-images/:id/variants  
    def admin_variants
      return if !user_is_allowed('variants', 'edit')
      img = ProductImage.find(params[:id])    
      render :json => img.variants
    end
    
    # DELETE /admin/product-images/:id  
    def admin_delete
      return if !user_is_allowed('variants', 'delete')
      img = ProductImage.find(params[:id]).destroy    
      render :json => true
    end
  
    # GET /variant-images/:id
    def variant_images
      var = Variant.find(params[:id])
      img = var.product_images.first
      render :json => img
    end
  
  end
end
