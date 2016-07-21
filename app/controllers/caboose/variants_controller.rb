module Caboose
  class VariantsController < Caboose::ApplicationController
    
    # @route POST /variants/find-by-options
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
    
    # @route GET /variants/:id/display-image
    def display_image
      ap "File is found"
      render :json => Variant.find(params[:id]).product_images.first
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # @route GET /admin/products/:product_id/variants    
    def admin_index   
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])
      
      if @product.variants.nil? || @product.variants.count == 0
        v = Variant.new
        v.product_id = @product.id
        v.option1 = @product.default1 if @product.option1
        v.option2 = @product.default2 if @product.option2
        v.option3 = @product.default3 if @product.option3
        v.status  = 'Active'
        v.save        
      end
      @variant = params[:variant_id] ? Variant.find(params[:variant_id]) : @product.variants[0]
      @highlight_variant_id = params[:highlight] ? params[:highlight].to_i : nil
      render :layout => 'caboose/admin'                
    end
    
    # @route GET /admin/products/:product_id/variants/json
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
        :models => pager.items.as_json(:include => [:flat_rate_shipping_package, :flat_rate_shipping_method])
      }      
    end
    
    # @route GET /admin/products/:product_id/variants/:id/json
    def admin_json_single
      return if !user_is_allowed('products', 'view')
      
      v = Variant.find(params[:id])      
      render :json => v      
    end
            
    # @route GET /admin/products/:product_id/variants/:id/download-url
    def admin_download_url
      return if !user_is_allowed('variants', 'edit')
      
      resp = StdClass.new
      v = Variant.find(params[:id])
      expires_in = params[:expires_in].to_i
      
      if !v.downloadable
        resp.error = "This variant is not downloadable."
      else
        config = YAML.load_file("#{::Rails.root}/config/aws.yml")
        AWS.config({ 
          :access_key_id => config[Rails.env]['access_key_id'],
          :secret_access_key => config[Rails.env]['secret_access_key']  
        })        
        bucket = AWS::S3::Bucket.new(config[Rails.env]['bucket'])
        s3object = AWS::S3::S3Object.new(bucket, v.download_path)
        resp.url = s3object.url_for(:read, :expires => expires_in.minutes).to_s
        resp.success = true
      end

      render :json => resp
    end
    
    # @route GET /admin/products/:product_id/variants/new
    def admin_new
      return if !user_is_allowed('variants', 'add')
      @top_categories = ProductCategory.where(:parent_id => nil).reorder('name').all
      @product_id = params[:product_id] 
      @variant = Variant.new
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products/:product_id/variants/sort-order  
    def admin_edit_sort_order
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])      
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products/:product_id/variants/option1-media  
    def admin_edit_option1_media
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])
      @variants = Variant.where(:product_id => @product.id, :option1 => params[:option_value]).reorder(:option1_sort_order).all      
      render :layout => 'caboose/modal'
    end
    
    # @route GET /admin/products/:product_id/variants/option2-media  
    def admin_edit_option2_media
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])
      @variants = Variant.where(:product_id => @product.id, :option2 => params[:option_value]).reorder(:option2_sort_order).all      
      render :layout => 'caboose/modal'
    end
    
    # @route GET /admin/products/:product_id/variants/option3-media  
    def admin_edit_option3_media
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:product_id])
      @variants = Variant.where(:product_id => @product.id, :option3 => params[:option_value]).reorder(:option3_sort_order).all      
      render :layout => 'caboose/modal'
    end
    
    # @route GET /admin/products/:product_id/variants/:id
    def admin_edit
      return if !user_is_allowed('variants', 'edit')    
      @variant = Variant.find(params[:id])
      @product = @variant.product
      render :layout => 'caboose/admin'            
    end
    
    # @route PUT /admin/products/:product_id/variants/:id/attach-to-image
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
  
    # @route PUT /admin/products/:product_id/variants/:id/unattach-from-image
    def admin_unattach_from_image
      render :json => false if !user_is_allowed('variants', 'edit')
      v = Variant.find(params[:id])
      img = ProductImage.find(params[:product_image_id])       
      img.variants.delete(v)
      img.save
      render :json => true
    end
  
    # @route DELETE /admin/products/:product_id/variants/:id
    def admin_delete
      return if !user_is_allowed('variants', 'delete')
      v = Variant.find(params[:id])
      v.status = 'Deleted'
      v.save
      render :json => Caboose::StdClass.new({
        :redirect => "/admin/products/#{v.product_id}/variants"
      })
    end
    
    # @route DELETE /admin/products/:product_id/variants/bulk
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
    
    # @route PUT /admin/products/:product_id/variants/option1-sort-order
    def admin_update_option1_sort_order
      product_id = params[:product_id]
      params[:values].each_with_index do |value, i|
        Variant.where(:product_id => product_id, :option1 => value).all.each do |v|
          v.update_attribute(:option1_sort_order, i)
        end
      end            
      render :json => { :success => true }
    end
    
    # @route PUT /admin/products/:product_id/variants/option2-sort-order
    def admin_update_option2_sort_order            
      product_id = params[:product_id]
      params[:values].each_with_index do |value, i|
        Variant.where(:product_id => product_id, :option2 => value).all.each do |v|
          v.update_attribute(:option2_sort_order, i)
        end
      end            
      render :json => { :success => true }
    end
    
    # @route PUT /admin/products/:product_id/variants/option3-sort-order
    def admin_update_option3_sort_order      
      product_id = params[:product_id]
      params[:values].each_with_index do |value, i|
        Variant.where(:product_id => product_id, :option3 => value).all.each do |v|
          v.update_attribute(:option3_sort_order, i)
        end
      end            
      render :json => { :success => true }
    end
    
    # @route PUT /admin/products/:product_id/variants/bulk
    def admin_bulk_update
      return unless user_is_allowed_to 'edit', 'sites'
    
      resp = Caboose::StdClass.new    
      variants = params[:model_ids].collect{ |variant_id| Variant.find(variant_id) }      
    
      save = true
      params.each do |k,value|
        case k
          when 'alternate_id'       then variants.each { |v| v.alternate_id       = value }
          when 'sku'                then variants.each { |v| v.sku                = value }
          when 'barcode'            then variants.each { |v| v.barcode            = value }
          when 'price'              then variants.each { |v| v.price              = value }
          when 'quantity_in_stock'  then variants.each { |v| v.quantity_in_stock  = value }
          when 'ignore_quantity'    then variants.each { |v| v.ignore_quantity    = value }
          when 'allow_backorder'    then variants.each { |v| v.allow_backorder    = value }
          when 'clearance'          then variants.each { |v| v.clearance          = value }
          when 'clearance_price'    then variants.each { |v| v.clearance_price    = value }
          when 'status'             then variants.each { |v| v.status             = value }
          when 'weight'             then variants.each { |v| v.weight             = value }
          when 'length'             then variants.each { |v| v.length             = value }
          when 'width'              then variants.each { |v| v.width              = value }
          when 'height'             then variants.each { |v| v.height             = value }
          when 'option1'            then variants.each { |v| v.option1            = value }
          when 'option2'            then variants.each { |v| v.option2            = value }
          when 'option3'            then variants.each { |v| v.option3            = value }
          when 'option1_media_id'   then variants.each { |v| v.option1_media_id   = value }
          when 'option2_media_id'   then variants.each { |v| v.option2_media_id   = value }
          when 'option3_media_id'   then variants.each { |v| v.option3_media_id   = value }
          when 'requires_shipping'  then variants.each { |v| v.requires_shipping  = value }
          when 'taxable'            then variants.each { |v| v.taxable            = value }
          when 'downloadable'       then variants.each { |v| v.downloadable       = value }
          when 'download_path'      then variants.each { |v| v.download_path      = value }

          when 'sale_price'
            variants.each_with_index do |v, i|              
              v.sale_price = value            
              v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale if i == 0
            end
          when 'date_sale_starts'
            variants.each_with_index do |v, i|
              v.date_sale_starts = ModelBinder.update_date(v.date_sale_starts, value, @logged_in_user.timezone)
              if i == 0
                v.product.delay(:run_at => v.date_sale_starts, :queue => 'caboose_store').update_on_sale
                v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale                
              end                                
            end
          when 'time_sale_starts'
            variants.each_with_index do |v, i|
              v.date_sale_starts = ModelBinder.update_time(v.date_sale_starts, value, @logged_in_user.timezone)                                    
              if i == 0
                v.product.delay(:run_at => v.date_sale_starts, :queue => 'caboose_store').update_on_sale
                v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale                
              end
            end            
          when 'date_sale_ends'
            variants.each_with_index do |v, i|
              v.date_sale_ends = ModelBinder.update_date(v.date_sale_ends, value, @logged_in_user.timezone)            
              if i == 0
                v.product.delay(:run_at => v.date_sale_ends  , :queue => 'caboose_store').update_on_sale
                v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale                
              end
            end            
          when 'time_sale_ends'
            variants.each_with_index do |v, i|
              v.date_sale_ends = ModelBinder.update_time(v.date_sale_ends, value, @logged_in_user.timezone)                                    
              if i == 0
                v.product.delay(:run_at => v.date_sale_ends  , :queue => 'caboose_store').update_on_sale
                v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale                
              end
            end
            
        end        
      end
      variants.each{ |v| v.save }
    
      resp.success = true
      render :json => resp
    end
    
    # @route PUT /admin/products/:product_id/variants/:id
    def admin_update
      return if !user_is_allowed('variants', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      v = Variant.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name        
          when 'alternate_id'                  then v.alternate_id                  = value
          when 'sku'                           then v.sku                           = value
          when 'barcode'                       then v.barcode                       = value
          when 'cost'                          then v.cost                          = value
          when 'price'                         then v.price                         = value                      
          when 'quantity_in_stock'             then v.quantity_in_stock             = value
          when 'ignore_quantity'               then v.ignore_quantity               = value
          when 'allow_backorder'               then v.allow_backorder               = value
          when 'clearance'                     then v.clearance                     = value
          when 'clearance_price'               then v.clearance_price               = value
          when 'status'                        then v.status                        = value
          when 'weight'                        then v.weight                        = value
          when 'length'                        then v.length                        = value
          when 'width'                         then v.width                         = value
          when 'height'                        then v.height                        = value
          when 'option1'                       then v.option1                       = value
          when 'option2'                       then v.option2                       = value
          when 'option3'                       then v.option3                       = value
          when 'requires_shipping'             then v.requires_shipping             = value
          when 'taxable'                       then v.taxable                       = value
          when 'is_bundle'                     then v.is_bundle                     = value
          when 'flat_rate_shipping'            then v.flat_rate_shipping            = value
          when 'flat_rate_shipping_single'     then v.flat_rate_shipping_single     = value
          when 'flat_rate_shipping_combined'   then v.flat_rate_shipping_combined   = value
          when 'flat_rate_shipping_package_id' then v.flat_rate_shipping_package_id = value
          when 'flat_rate_shipping_method_id'  then v.flat_rate_shipping_method_id  = value
          when 'flat_rate_shipping_package_method_id' then
            arr = value.split('_')
            v.flat_rate_shipping_package_id = arr[0].to_i
            v.flat_rate_shipping_method_id  = arr[1].to_i
          when 'downloadable'                then v.downloadable                = value
          when 'download_path'               then v.download_path               = value
            
          when 'sale_price'
            v.sale_price = value            
            v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale            
          when 'date_sale_starts'
            v.date_sale_starts = ModelBinder.local_datetime_to_utc(value, @logged_in_user.timezone)                        
            v.product.delay(:run_at => v.date_sale_starts, :queue => 'caboose_store').update_on_sale
            v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale
          when 'date_sale_ends'
            v.date_sale_ends = ModelBinder.local_datetime_to_utc(value, @logged_in_user.timezone)                        
            v.product.delay(:run_at => v.date_sale_ends  , :queue => 'caboose_store').update_on_sale  
            v.product.delay(:run_at => 3.seconds.from_now, :queue => 'caboose_store').update_on_sale
          
        end
      end
      resp.success = save && v.save
      render :json => resp
    end
  
    # @route GET /admin/variants/group
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
      @categories = Category.where('site_id = ? and parent_id IS NOT NULL AND name IS NOT NULL', @site.id).reorder(:url)
      
      # Grab all vendors      
      @vendors = Vendor.where('site_id = ? and name IS NOT NULL', @site.id).reorder(:name)
      
      render :layout => 'caboose/admin'
    end
    
    # @route POST /admin/products/:product_id/variants
    def admin_add      
      resp = Caboose::StdClass.new
      p = Caboose::Product.find(params[:product_id])
      
      pd = @site.product_default
      vd = @site.variant_default
      
      v = Caboose::Variant.where(:alternate_id => params[:alternate_id]).first
      v = Caboose::Variant.new(:product_id => p.id) if v.nil?
      
      v.product_id        = p.id
      v.alternate_id      = params[:alternate_id].strip
      v.quantity_in_stock = params[:quantity_in_stock].strip.to_i
      v.price             = '%.2f' % params[:price].strip.to_f
      v.option1           = params[:option1] if p.option1
      v.option2           = params[:option2] if p.option2
      v.option3           = params[:option3] if p.option3            
            
      v.cost              = vd.cost
      v.available         = vd.available
      v.ignore_quantity   = vd.ignore_quantity              
      v.allow_backorder   = vd.allow_backorder              
      v.weight            = vd.weight                       
      v.length            = vd.length                       
      v.width             = vd.width                        
      v.height            = vd.height                       
      v.volume            = vd.volume                       
      v.cylinder          = vd.cylinder                     
      v.requires_shipping = vd.requires_shipping            
      v.taxable           = vd.taxable                                  
      v.status            = vd.status                       
      v.downloadable      = vd.downloadable                 
      v.is_bundle         = vd.is_bundle                    
      
      v.save
      
      resp.success = true      
      render :json => resp
    end
    
    # @route POST /admin/products/:product_id/variants/bulk
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
          v = nil
          if row[0].strip.length == 0
            v = Caboose::Variant.new(:product_id => p.id)
          else
            v = Caboose::Variant.where(:alternate_id => row[0]).first
            v = Caboose::Variant.new(:product_id => p.id) if v.nil?
          end

          v.product_id        = p.id
          v.alternate_id      = row[0].strip
          v.quantity_in_stock = row[1].strip.to_i
          v.price             = '%.2f' % row[2].strip.to_f
          v.option1 = row[3] if p.option1
          v.option2 = row[4] if p.option2
          v.option3 = row[5] if p.option3
          v.status = 'Active'
          v.save
        end
        resp.success = true
      end
      
      render :json => resp
    end
    
    # @route POST /admin/products/:product_id/variants/remove
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
    
    # @route GET /admin/variants/status-options
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
