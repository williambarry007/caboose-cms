module Caboose
  PageBarGenerator.class_eval do
    def all_records
      return model_with_includes.where(where)
    end
  end
end

module Caboose
  class ProductsController < Caboose::ApplicationController
        
    # GET /products || GET /products/:id
    def index
      
      # If id exists, is an integer and a product exists with the specified id then get the product
      if params[:id] && params[:id].to_i > 0 && Product.exists?(params[:id])
        @product = Product.find(params[:id])
        render 'product/not_available' and return if @product.status == 'Inactive'
        
        @category       = @product.categories.first
        @review         = Review.new
        @reviews        = Review.where(:product_id => @product.id).limit(10).order("id DESC") || nil
        @logged_in_user = logged_in_user
        
        render 'caboose/products/details' and return        
      end
      
      # Filter params from url
      url_without_params = request.fullpath.split('?').first
      
      # Find the category
      cat = Category.where(:site_id => @site.id, :url => url_without_params).first
      if cat.nil?
        cat = Category.where(:site_id => @site.id, :url => '/products').first
        cat = Category.create(:site_id => @site.id, :url => '/products') if cat.nil?          
      end
            
      # Set category ID
      params['category_id'] = cat.id
      
      # If this is the top-most category, collect all it's immediate children IDs
      params['category_id'] = cat.children.collect { |child| child.id } if cat.id == 1
      
      # Shove the original category ID into the first position if the param is an array
      params['category_id'].unshift(category.id) if params['category_id'].is_a?(Array)
      
      # Otherwise looking at a category or search parameters
      @pager = Caboose::Pager.new(params, {
        'site_id'        => @site.id,
        'category_id'    => '',
        'vendor_id'      => '',
        'vendor_name'    => '',
        'vendor_status'  => 'Active',
        'status'         => 'Active',
        'variant_status' => 'Active',
        'price_gte'      => '',
        'price_lte'      => '',
        'alternate_id'   => '',
        'search_like'    => ''
      }, {
        'model'          => 'Caboose::Product',
        'sort'           => if params[:sort] then params[:sort] else 'store_products.sort_order' end,
        'base_url'       => url_without_params,
        'items_per_page' => 15,
        'use_url_params' => false,
        
        'abbreviations' => {
          'search_like' => 'title_concat_store_products.alternate_id_concat_vendor_name_concat_category_name_like',
        },
        
        'includes' => {
          'category_id'    => [ 'categories' , 'id'     ],
          'category_name'  => [ 'categories' , 'name'   ],
          'vendor_id'      => [ 'vendor'     , 'id'     ],
          'vendor_name'    => [ 'vendor'     , 'name'   ],
          'vendor_status'  => [ 'vendor'     , 'status' ],
          'price_gte'      => [ 'variants'   , 'price'  ],
          'price_lte'      => [ 'variants'   , 'price'  ],
          'variant_status' => [ 'variants'   , 'status' ]
        }
      })
      
      @sort_options = [
        { :name => 'Default',             :value => 'store_products.sort_order' },
        { :name => 'Price (Low to High)', :value => 'store_variants.price ASC'  },
        { :name => 'Price (High to Low)', :value => 'store_variants.price DESC' },
        { :name => 'Alphabetical (A-Z)',  :value => 'store_products.title ASC'  },
        { :name => 'Alphabetical (Z-A)',  :value => 'store_products.title DESC' },
      ]
      
      SearchFilter.delete_all
      
      @filter   = SearchFilter.find_from_url(request.fullpath, @pager, ['page'])
      @products = @pager.items
      @category = if @filter['category_id'] then Category.find(@filter['category_id'].to_i) else nil end
      
      @pager.set_item_count            
    end
    
    def show
    end
    
    # GET /product/info
    def info
      p = Product.find(params[:id])
      render :json => { 
        :product => p,
        :option1_values => p.option1_values,
        :option2_values => p.option2_values,
        :option3_values => p.option3_values
      }
    end
    
    #=============================================================================
    # API actions
    #=============================================================================
    
    # GET /api/products
    def api_index
      render :json => Product.where(:status => 'Active')
    end
    
    # GET /api/products/:id
    def api_details
      p = Product.where(:id => params[:id]).first
      render :json => p ? p : { :error => 'Invalid product ID' }
    end
    
    # GET /api/products/:id/variants
    def api_variants
      p = Product.where(:id => params[:id]).first
      render :json => p ? p.variants : { :error => 'Invalid product ID' }
    end
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # GET /admin/products/:id/variants/group
    def admin_group_variants
      @product = Product.find(params[:id])
      
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
      products = values.any? ? Product.joins(joins).where([where.join(' AND ')].concat(values)) : []
      
      # Grab variants for each product
      @variants = products.collect { |product| product.variants }.flatten
      
      # Grab all categories; except for "all" and "uncategorized"
      @categories = Category.where('site_id = ? and parent_id IS NOT NULL AND name IS NOT NULL', @site.id).order(:url)
      
      # Grab all vendors
      @vendors = Vendor.where('site_id = ? and name IS NOT NULL', @site.id).order(:name)
      
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/products/:id/variants/add
    def admin_add_variants
      params[:variant_ids].each do |variant_id|
        variant = Variant.find(variant_id)
        
        # Delete current variant product if this is the last variant
        # variant.product.update_attribute(:status, 'deleted') if variant.product.variants.where('status != ?', 'deleted').count == 0
        
        # Add reference to new product
        # varant.product_id = params[:id]
      end
      
      # Iterate over variants and add them to the product
        # Remove product that the variants are associated with; UNLESS it's the current product
      
      redirect_to "/admin/products/#{params[:id]}/variants"
    end
    
    # POST /admin/products/:id/varaints/add-multiple
    def admin_add_multiple_variants
      product = Product.find(params[:id])
      
      params[:variants_csv].split("\r\n").each do |variant|
        row = variant.split(',')
        
        render :json => { :success => false, :error => "Quantity is not defined for variant: #{row[0].strip}" } and return if row[1].nil?
        render :json => { :success => false, :error => "Price is not defined for variant: #{row[0].strip}" } and return if row[2].nil?
        
        attributes = {
          :alternate_id => row[0].strip,
          :quantity_in_stock => row[1].strip.to_i,
          :price => '%.2f' % row[2].strip.to_f,
          :status => 'Active'
        }
        
        if product.option1 && row[3].nil?
          render :json => { :success => false, :error => "#{product.option1} not defined for variant: #{attributes[:alternate_id]}" } and return
        elsif product.option1
          attributes[:option1] = row[3].strip
        end
        
        if product.option2 && row[4].nil?
          render :json => { :success => false, :error => "#{product.option2} not defined for variant: #{attributes[:alternate_id]}" } and return
        elsif product.option2
          attributes[:option2] = row[4].strip
        end
        
        if product.option3 && row[5].nil?
          render :json => { :success => false, :error => "#{product.option3} not defined for variant: #{attributes[:alternate_id]}" } and return
        elsif product.option3
          attributes[:option3] = row[5].strip
        end
        
        if product.variants.find_by_alternate_id(attributes[:alternate_id])
          product.variants.find_by_alternate_id(attributes[:alternate_id]).update_attributes(attributes)
        else
          Variant.create(attributes.merge(:product_id => product.id))
        end
      end
      
      render :json => { :success => true }
    end
    
    # POST /admin//products/:id/variants/remove
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
    
    # GET /admin/products/update-vendor-status/:id
    def admin_update_vendor_status
      vendor = Vendor.find(params[:id])
      vendor.status = params[:status]
      render :json => vendor.save
    end
    
    # GET /admin/products
    def admin_index
      return if !user_is_allowed('products', 'view')
      
      # Temporary patch for vendor name sorting; Fix this
      params[:sort] = 'store_vendors.name' if params[:sort] == 'vendor'
      
      @gen = Caboose::PageBarGenerator.new(params, {
        'site_id'      => @site.id,
        'vendor_name'  => '',
        'search_like'  => '', 
        'price'        => params[:filters] && params[:filters][:missing_prices] ? 0 : ''
      }, {
        'model'          => 'Caboose::Product',
        'sort'           => 'title',
        'desc'           => false,
        'base_url'       => '/admin/products',
        'items_per_page' => 25,
        'use_url_params' => false,
        
        'abbreviations' => {
          'search_like' => 'store_products.title_concat_vendor_name_like'
        },
        
        'includes' => {
          'vendor_name'  => [ 'vendor'         , 'name'  ],
          'price'        => [ 'variants'       , 'price' ]
        }
      })
      
      # Make a copy of all the items; so it can be filtered more
      @all_products = @gen.all_records
      
      # Apply any extra filters
      if params[:filters]
        @all_products = @all_products.includes(:product_images).where('store_product_images.id IS NULL') if params[:filters][:missing_images]
        @all_products = @all_products.where('vendor_id IS NULL') if params[:filters][:no_vendor]
      end
      
      # Get the correct page of the results
      @products = @all_products.limit(@gen.limit).offset(@gen.offset)
      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/products/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      # Temporary patch for vendor name sorting; Fix this
      params[:sort] = 'store_vendors.name' if params[:sort] == 'vendor'
      
      pager = Caboose::PageBarGenerator.new(params, {
        'site_id'      => @site.id,
        'vendor_name'  => '',
        'search_like'  => '', 
        'price'        => params[:filters] && params[:filters][:missing_prices] ? 0 : ''
      }, {
        'model'          => 'Caboose::Product',
        'sort'           => 'title',
        'desc'           => false,
        'base_url'       => '/admin/products',
        'items_per_page' => 25,
        'use_url_params' => false,        
        'abbreviations' => {
          'search_like' => 'store_products.title_concat_vendor_name_like'
        },        
        'includes' => {
          'vendor_name'  => [ 'vendor'   , 'name'  ],
          'price'        => [ 'variants' , 'price' ]
        }
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      }      
    end
    
    # GET /admin/products/add-upcs - TODO remove this; it's a temporary thing for woods-n-water
    def admin_add_upcs
      params[:vendor_id] if params[:vendor_id] and params[:vendor_id].empty?
      
      conditions = if params[:vendor_id]
        "store_variants.alternate_id IS NULL and store_vendors.id = #{params[:vendor_id]}"
      else
        "store_variants.alternate_id IS NULL"
      end
      
      @products = Product.all(
        :include => [:variants, :vendor],
        :conditions => conditions
      )
      
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/products/:id/json
    def admin_json_single
      p = Product.find(params[:id])
      render :json => p      
    end
    
    # GET /admin/products/:id/general
    def admin_edit_general
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/products/:id/description
    def admin_edit_description   
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/products/:id/variant-cols  
    def admin_edit_variant_columns
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      session['variant_cols'] = self.default_variant_cols if session['variant_cols'].nil?
      @cols = session['variant_cols']
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/products/:id/variant-cols
    def admin_update_variant_columns    
      return if !user_is_allowed('products', 'edit')
      session['variant_cols'] = self.default_variant_cols if session['variant_cols'].nil?
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      product = Product.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        value = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
        case name
          when 'option1'        ,
            'option2'           ,
            'option3'           ,
            'status'            ,
            'alternate_id'      ,
            'sku'               ,                        
            'barcode'           , 
            'price'             ,
            'quantity_in_stock' ,
            'weight'            , 
            'length'            , 
            'width'             , 
            'height'            , 
            'cylinder'          , 
            'requires_shipping' ,
            'allow_backorder'   ,
            'taxable'      
            session['variant_cols'][name] = value
        end
      end
      resp.success = save && product.save
      render :json => resp
    end
    
    def default_variant_cols
      return {    
        'option1'           => true,
        'option2'           => true,
        'option3'           => true,
        'status'            => true,
        'alternate_id'      => true,
        'sku'               => true,                         
        'barcode'           => false, 
        'price'             => true, 
        'quantity' => true, 
        'weight'            => false, 
        'length'            => false, 
        'width'             => false, 
        'height'            => false, 
        'cylinder'          => false, 
        'requires_shipping' => false,
        'allow_backorder'   => false,
        'taxable'           => false
      }
    end
    
    # GET /admin/products/:id/options
    def admin_edit_options
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'          
    end
    
    # GET /admin/products/:id/categories
    def admin_edit_categories
      return if !user_is_allowed('products', 'edit')
      @product = Product.find(params[:id])
      @top_categories = Category.where(:parent_id => 1).reorder('name').all
      @selected_ids = @product.categories.collect{ |cat| cat.id }
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/products/:id/categories
    def admin_add_to_category
      return if !user_is_allowed('products', 'edit')
      cat_id = params[:category_id]
      product_id = params[:id]
      
      if !CategoryMembership.exists?(:category_id => cat_id, :product_id => product_id)
        CategoryMembership.create(:category_id => cat_id, :product_id => product_id)
      end    
      render :json => true
    end
    
    # DELETE /admin/products/:id/categories/:category_id
    def admin_remove_from_category
      return if !user_is_allowed('products', 'edit')
      cat_id = params[:category_id]
      product_id = params[:id]
      
      if CategoryMembership.exists?(:category_id => cat_id, :product_id => product_id)
        CategoryMembership.where(:category_id => cat_id, :product_id => product_id).destroy_all
      end        
      render :json => true
    end
    
    # GET /admin/products/:id/images
    def admin_edit_images    
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/products/:id/images
    def admin_add_image
      return if !user_is_allowed('products', 'edit')
      product_id = params[:id]
      
      if (params[:new_image].nil?)
        render :text => "<script type='text/javascript'>parent.modal.autosize(\"<p class='note error'>You must provide an image.</p>\", 'new_image_message');</script>"
      else    
        img = ProductImage.new
        img.product_id = product_id
        img.image = params[:new_image]
        img.square_offset_x = 0
        img.square_offset_y = 0
        img.square_scale_factor = 1.00
        img.save
        render :text => "<script type='text/javascript'>parent.window.location.reload(true);</script>"
      end
    end
    
    # GET /admin/products/:id/collections
    def admin_edit_collections
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end    
    
    # GET /admin/products/:id/seo
    def admin_edit_seo
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # GET /admin/products/:id/delete
    def admin_delete_form
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
      
    # PUT /admin/products/:id
    def admin_update
      return if !user_is_allowed('products', 'edit')
      
      resp = Caboose::StdClass.new({'attributes' => {}})
      product = Product.find(params[:id])    
      
      save = true    
      params.each do |name,value|
        case name
          when 'site_id'            then product.site_id            = value
          when 'alternate_id'       then product.alternate_id       = value          
          when 'title'              then product.title              = value
          when 'caption'            then product.caption            = value
          when 'featured'           then product.featured           = value
          when 'description'        then product.description        = value          
          when 'vendor_id'          then product.vendor_id          = value
          when 'handle'             then product.handle             = value
          when 'seo_title'          then product.seo_title          = value
          when 'seo_description'    then product.seo_description    = value
          when 'status'             then product.status             = value
          when 'category_id'        then product.toggle_category(value[0], value[1])
          when 'stackable_group_id' then product.stackable_group_id = value          
          when 'option1'            then product.option1            = value
          when 'option2'            then product.option2            = value
          when 'option3'            then product.option3            = value
          when 'default1'
            product.default1 = value
            Variant.where(:product_id => product.id, :option1 => nil).each do |p|
              p.option1 = value
              p.save
            end
          when 'default2'
            product.default2 = value
            Variant.where(:product_id => product.id, :option2 => nil).each do |p|
              p.option2 = value
              p.save
            end
          when 'default3'
            product.default3 = value
            Variant.where(:product_id => product.id, :option3 => nil).each do |p|
              p.option3 = value
              p.save
            end          
          when 'date_available'
            if value.strip.length == 0
              product.date_available = nil
            else
              begin
                product.date_available = DateTime.parse(value)
              rescue
                resp.error = "Invalid date"
                save = false
              end
            end
        end
      end
      resp.success = save && product.save
      render :json => resp
    end
    
    # GET /admin/products/new
    def admin_new
      return if !user_is_allowed('products', 'add')
      render :layout => 'caboose/admin'
    end
    
    # POST /admin/products
    def admin_add
      return if !user_is_allowed('products', 'add')
      
      resp = Caboose::StdClass.new(
        :error => nil,
        :redirect => nil
      )
      
      name = params[:name]
      
      if name.length == 0
        resp.error = "The title cannot be empty."
      else
        p = Product.new(
          :site_id => @site.id,
          :title => name
        )
        p.save
        resp.redirect = "/admin/products/#{p.id}/general"
      end
      render :json => resp    
    end
    
    # DELETE /admin/products/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      p = Product.find(params[:id]).destroy
      p.status = 'Deleted'
      p.save
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/products'
      })
    end
    
    # GET /products/status-options
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
    
    # GET /products/stackable-group-options
    def admin_stackable_group_options
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
    
    # GET /admin/products/combine
    def admin_combine_select_products
    end
    
    # GET /admin/products/combine-step2
    def admin_combine_assign_title
    end
    
    # POST /admin/products/combine
    def admin_combine
      product_ids = params[:product_ids]
      
      p = Product.new
      p.title       = params[:title]
      p.description = params[:description]
      p.option1     = params[:option1]
      p.option2     = params[:option2]
      p.option3     = params[:option3]      
      p.default1    = params[:default1]
      p.default2    = params[:default2]
      p.default3    = params[:default3]
      p.status      = 'Active'
      p.save
      
      product_ids.each do |pid|
        p = Product.find(pid)
        p.variants.each do |v|
        end
      end
    end
    
    # PUT /admin/products/:id/update-vendor
    def admin_update_vendor
      render :json => { :success => Product.find(params[:id]).update_attribute(:vendor_id, params[:vendor_id]) }
    end
    
    # GET /admin/products/sort
    def admin_sort
      @products   = Product.active
      @vendors    = Vendor.active
      @categories = Category.all
      
      render :layout => 'caboose/admin'
    end
    
    # PUT /admin/products/update-sort-order
    def admin_update_sort_order
      params[:product_ids].each_with_index do |product_id, index|
        Product.find(product_id.to_i).update_attribute(:sort_order, index)
      end      
      render :json => { :success => true }
    end
        
  end
end

