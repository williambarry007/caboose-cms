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
    
    # GET /admin/products/:id/variants
    # GET /admin/products/:id/variants/:variant_id
    def admin_index   
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])
      
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
      @highlight_variant_id = params[:highlight] ? params[:highlight].to_i : nil
      render :layout => 'caboose/admin'                
    end
    
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
        
    # GET /admin/products/:product_id/variants/:variant_id
    def admin_edit
      return if !user_is_allowed('variants', 'edit')    
      @variant = Variant.find(params[:id])
      @product = @variant.product
      render :layout => 'caboose/admin'            
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
  
    # DELETE /admin/products/:product_id/variants/:id
    def admin_delete
      return if !user_is_allowed('variants', 'delete')
      v = Variant.find(params[:id])
      v.status = 'Deleted'
      v.save
      render :json => Caboose::StdClass.new({
        :redirect => "/admin/products/#{v.product_id}/variants"
      })
    end
    
    # DELETE /admin/products/:product_id/variants/bulk
    def admin_bulk_delete
      return if !user_is_allowed('variants', 'delete')
      
      resp = Caboose::StdClass.new
      params[:model_ids].each do |variant_id|
        v = Variant.find(variant_id)
        v.status = 'Deleted'
        v.save
      end
      resp.success = true
      render :json => resp
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
      where  = []
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
      products = values.any? ? Caboose::Product.joins(joins).where([where.join(' AND ')].concat(values)) : []
      
      # Grab variants for each product
      @variants = products.collect { |product| product.variants }.flatten
      
      # Grab all categories; except for all and uncategorized      
      @categories = Category.where('site_id = ? and parent_id IS NOT NULL AND name IS NOT NULL', @site.id).order(:url)
      
      # Grab all vendors      
      @vendors = Vendor.where('site_id = ? and name IS NOT NULL', @site.id).order(:name)
      
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/products/:product_id/variants/add
    def admin_add
      
      resp = Caboose::StdClass.new
      p = Caboose::Product.find(params[:product_id])
      
      v = Caboose::Variant.where(:alternate_id => params[:alternate_id]).first
      v = Caboose::Variant.new(:product_id => p.id) if v.nil?
      
      v.product_id        = p.id
      v.alternate_id      = params[:alternate_id].strip
      v.quantity_in_stock = params[:quantity_in_stock].strip.to_i
      v.price             = '%.2f' % params[:price].strip.to_f
      v.option1 = params[:option1] if p.option1
      v.option2 = params[:option2] if p.option2
      v.option3 = params[:option3] if p.option3      
      v.save
      
      resp.success = true      
      render :json => resp
    end
    
    # POST /admin/products/:product_id/variants/bulk
    def admin_bulk_add
      product = Product.find(params[:product_id])
      
      resp = Caboose::StdClass.new
      p = Caboose::Product.find(params[:product_id])
      
      # Check for data integrity first
      CSV.parse(params[:csv_data]).each do |row|
        if    row[1].nil? then resp.error = "Quantity is not defined for variant: #{row[0].strip}" and break          
        elsif row[2].nil? then resp.error = "Price is not defined for variant: #{row[0].strip}" and break
        elsif p.option1 && row[3].nil? then resp.error = "#{p.option1} is not defined for variant: #{row[0].strip}" and break
        elsif p.option2 && row[4].nil? then resp.error = "#{p.option2} is not defined for variant: #{row[0].strip}" and break
        elsif p.option3 && row[5].nil? then resp.error = "#{p.option3} is not defined for variant: #{row[0].strip}" and break
        end
      end
      
      if resp.error.nil?
        CSV.parse(params[:csv_data]).each do |row|                    
          v = Caboose::Variant.where(:alternate_id => row[0]).first
          v = Caboose::Variant.new(:product_id => p.id) if v.nil?
      
          v.product_id        = p.id
          v.alternate_id      = row[0].strip
          v.quantity_in_stock = row[1].strip.to_i
          v.price             = '%.2f' % row[2].strip.to_f
          v.option1 = row[3] if p.option1
          v.option2 = row[4] if p.option2
          v.option3 = row[5] if p.option3      
          v.save
        end
        resp.success = true
      end
      
      render :json => resp
    end
    
    # POST /admin/products/:product_id/variants/remove
    def admin_remove_variants
      params[:variant_ids].each do |variant_id|
        variant = Variant.find(variant_id)
        # variant.update_attribute(:status, 'deleted')
        # variant.product.update_attribute(:status, 'deleted') if variant.product.variants.where('status != ?', 'deleted').count == 0
      end
      
      # Remove passed variants
      # redirect_to "/admin/products/#{params[:id]}/variants/group"
            
      render :json => true
    end
    
    #===========================================================================
    # Option methods
    #===========================================================================
    
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
