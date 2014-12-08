module Caboose
  class VariantsController < Caboose::ApplicationController
    
    # POST /variants/find-by-options
    def find_by_options
      
      # Find the variant based on the product ID and options
      variant = Variant.find_by_options(params[:product_id], params[:option1], params[:option2], params[:option3])
      
      # If there are customizations, find the correct variant
      customizations = if params[:customizations]
        params[:customizations].map do |customization_id, options|
          Variant.find_by_options(customization_id, options[:option1], options[:option2], options[:option3])
        end
      else
        Array.new
      end
      
      render :json => { :variant => variant, :customizations => customizations }
    end
    
    # GET /variants/:id/display-image
    def display_image
      ap "File is found"
      render :json => Variant.find(params[:id]).product_images.first
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
     
    # GET /admin/products/:product_id/variants/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      pager = Caboose::PageBarGenerator.new(params, {
        'product_id'   => params[:product_id]
      }, {
        'model'          => 'Caboose::Variant',
        'sort'           => 'option1, option2, option3',
        'desc'           => false,
        'base_url'       => "/admin/products/#{params[:product_id]}/variants",
        'items_per_page' => 100,
        'use_url_params' => false        
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      }      
    end
    
    # GET /admin/variants/:variant_id/edit
    # GET /admin/products/:product_id/variants/:variant_id/edit
    def admin_edit
      return if !user_is_allowed('variants', 'edit')    
      @variant = Variant.find(params[:variant_id])
      @product = @variant.product
      render :layout => 'caboose/admin'            
    end
    
    # GET /admin/products/:id/variants
    # GET /admin/products/:id/variants/:variant_id
    def admin_edit_variants   
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      
      if @product.variants.nil? || @product.variants.count == 0
        v = Variant.new
        v.option1 = @product.default1 if @product.option1
        v.option2 = @product.default2 if @product.option2
        v.option3 = @product.default3 if @product.option3
        v.status  = 'Active'
        @product.variants = [v]
        @product.save
      end
      @variant = params[:variant_id] ? Variant.find(params[:variant_id]) : @product.variants[0]
      session['variant_cols'] = self.default_variant_cols if session['variant_cols'].nil?
      @cols = session['variant_cols']
      
      @highlight_variant_id = params[:highlight] ? params[:highlight].to_i : nil        
      
      if @product.options.nil? || @product.options.count == 0
        render 'caboose/products/admin_edit_variants_single', :layout => 'caboose/admin'  
      else
        render 'caboose/products/admin_edit_variants', :layout => 'caboose/admin'
      end          
    end
    
    # PUT /admin/variants/:id
    def admin_update
      return if !user_is_allowed('variants', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      v = Variant.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name        
          when 'alternate_id'       then v.alternate_id       = value
          when 'sku'                then v.sku                = value
          when 'barcode'            then v.barcode            = value
          when 'price'              then v.price              = value
          when 'quantity_in_stock'  then v.quantity_in_stock  = value
          when 'ignore_quantity'    then v.ignore_quantity    = value
          when 'allow_backorder'    then v.allow_backorder    = value
          when 'status'             then v.status             = value
          when 'weight'             then v.weight             = value
          when 'length'             then v.length             = value
          when 'width'              then v.width              = value
          when 'height'             then v.height             = value
          when 'option1'            then v.option1            = value
          when 'option2'            then v.option2            = value
          when 'option3'            then v.option3            = value
          when 'requires_shipping'  then v.requires_shipping  = value
          when 'taxable'            then v.taxable            = value
        end
      end
      resp.success = save && v.save
      render :json => resp
    end
    
    # GET /admin/products/:id/variants/new
    def admin_new
      return if !user_is_allowed('variants', 'add')
      @top_categories = ProductCategory.where(:parent_id => nil).reorder('name').all
      @product_id = params[:id] 
      @variant = Variant.new
      render :layout => 'caboose/admin'
    end
  
    # POST /admin/products/:id/variants
    def admin_add
      return if !user_is_allowed('variants', 'add')
      resp = Caboose::StdClass.new(
        :error   => nil,
        :refresh => nil
      )
    
      p = Product.find(params[:id])
      v = Variant.new(:product_id => p.id)
      v.option1 = p.default1
      v.option2 = p.default2
      v.option3 = p.default3
      v.status  = 'Active'
      v.save
      resp.refresh = true
      render :json => resp
    end
  
    # PUT /admin/variants/:id/attach-to-image
    def admin_attach_to_image
      render :json => false if !user_is_allowed('variants', 'edit')         
      variant_id = params[:id].to_i
      img = ProductImage.find(params[:product_image_id])

      exists = false
      img.variants.each do |v|
        if v.id == variant_id
          exists = true
          break
        end
      end
      if exists
        render :json => true
        return
      end
    
      img.variants = [] if img.variants.nil?
      img.variants << Variant.find(variant_id)
      img.save
    
      render :json => true
    end
  
    # PUT /admin/variants/:id/unattach-from-image
    def admin_unattach_from_image
      render :json => false if !user_is_allowed('variants', 'edit')
      v = Variant.find(params[:id])
      img = ProductImage.find(params[:product_image_id])       
      img.variants.delete(v)
      img.save
      render :json => true
    end
  
    # DELETE /admin/variants/:id
    def admin_delete
      return if !user_is_allowed('variants', 'delete')
      v = Variant.find(params[:id])
      v.status = 'Deleted'
      v.save
      render :json => Caboose::StdClass.new({
        :redirect => "/admin/products/#{v.product_id}/variants"
      })
    end
    
    # GET /admin/products/:product_id/variants/sort-order  
    def admin_edit_sort_order
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])      
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/products/:product_id/variants/option1-sort-order
    def admin_update_option1_sort_order
      product_id = params[:product_id]
      params[:values].each_with_index do |value, i|
        Variant.where(:product_id => product_id, :option1 => value).all.each do |v|
          v.update_attribute(:option1_sort_order, i)
        end
      end            
      render :json => { :success => true }
    end
    
    # PUT /admin/products/:product_id/variants/option1-sort-order
    def admin_update_option2_sort_order            
      product_id = params[:product_id]
      params[:values].each_with_index do |value, i|
        Variant.where(:product_id => product_id, :option2 => value).all.each do |v|
          v.update_attribute(:option2_sort_order, i)
        end
      end            
      render :json => { :success => true }
    end
    
    # PUT /admin/products/:product_id/variants/option1-sort-order
    def admin_update_option3_sort_order      
      product_id = params[:product_id]
      params[:values].each_with_index do |value, i|
        Variant.where(:product_id => product_id, :option3 => value).all.each do |v|
          v.update_attribute(:option3_sort_order, i)
        end
      end            
      render :json => { :success => true }
    end
  
    # GET /admin/variants
    def admin_group
      return if !user_is_allowed('variants', 'edit')
      
      joins  = []
      where  = ''
      values = []
      
      if params[:category_ids]
        joins  << [:category_memberships]
        where  << 'store_category_memberships.category_id IN (?)'
        values << params[:category_ids]
      end
      
      if params[:vendor_ids]
        joins  << [:vendor]
        where  << 'store_vendors.id IN (?)'
        values << params[:vendor_ids]
      end
      
      if params[:title]
        where  << 'LOWER(store_products.title) LIKE ?'
        values << "%#{params[:title].downcase}%"
      end
      
      # Query for all relevant products
      products = values.any? ? Caboose::Product.joins(joins).where([where].concat(values)) : []
      
      # Grab variants for each product
      @variants = products.collect { |product| product.variants }.flatten
      
      # Grab all categories; except for all and uncategorized
      @categories = Caboose::Category.where('parent_id IS NOT NULL')
      
      # Grab all vendors
      @vendors = Caboose::Vendor.all
      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/variants/status-options
    def admin_status_options
      arr = ['Active', 'Inactive', 'Deleted']
      options = []
      arr.each do |status|
        options << {
          :value => status,
          :text => status
        }
      end
      render :json => options
    end
  end
end
