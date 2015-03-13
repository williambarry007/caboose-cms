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
      if params[:id]        
        if params[:id] == 'sales'
          products = Caboose::Product.where(:site_id => @site.id, :status => Caboose::Product::STATUS_ACTIVE, :on_sale => true).all      
          @sale_categories = {}        
          products.each do |p|
            cat = 'Uncategorized'
            if p.categories.count > 0
              cats = p.categories.last.ancestry.collect{ |a| a.name }
              cats.shift
              cat = cats.join(' > ')
            end
            @sale_categories[cat] = [] if @sale_categories[cat].nil?
            @sale_categories[cat] << p
          end
          render 'caboose/products/sales' and return
          
        elsif params[:id].to_i > 0 && Product.exists?(params[:id])
          @product = Product.find(params[:id])
          render 'product/not_available' and return if @product.status == 'Inactive'
          
          @category       = @product.categories.first
          @review         = Review.new
          @reviews        = Review.where(:product_id => @product.id).limit(10).order("id DESC") || nil
          @logged_in_user = logged_in_user
          
          render 'caboose/products/details' and return
        end
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
        'site_id'         => @site.id,
        'on_sale'         => '',
        'category_id'     => '',
        'vendor_id'       => '',
        'vendor_name'     => '',
        'vendor_status'   => 'Active',
        'status'          => 'Active',
        'variant_status'  => 'Active',
        'price_gte'       => '',
        'price_lte'       => '',
        'alternate_id'    => '',
        'search_like'     => ''
        #'pcs_category_id' => cat.id
      }, {
        'model'           => 'Caboose::Product',
        'sort'            => if params[:sort] then params[:sort] else 'store_products.sort_order' end,
        #'sort'            => if params[:sort] then params[:sort] else 'store_product_category_sorts.sort_order' end,
        'base_url'        => url_without_params,
        'items_per_page'  => 15,
        'use_url_params'  => false,
        
        'abbreviations'   => {
          'search_like'   => 'title_concat_store_products.alternate_id_concat_vendor_name_concat_category_name_like',
        },
        
        'includes' => {
          #'pcs_category_id' => [ 'product_category_sorts', 'category_id' ],          
          'category_id'     => [ 'categories' , 'id'     ],
          'category_name'   => [ 'categories' , 'name'   ],
          'vendor_id'       => [ 'vendor'     , 'id'     ],
          'vendor_name'     => [ 'vendor'     , 'name'   ],
          'vendor_status'   => [ 'vendor'     , 'status' ],
          'price_gte'       => [ 'variants'   , 'price'  ],
          'price_lte'       => [ 'variants'   , 'price'  ],
          'variant_status'  => [ 'variants'   , 'status' ]
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
    # Admin actions
    #=============================================================================
    
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
        'site_id'        => @site.id,
        'vendor_name'    => '',
        'search_like'    => '', 
        'category_id'    => '',
        'category_name'  => '',
        'vendor_id'      => '',
        'vendor_name'    => '',
        'vendor_status'  => '',
        'price_gte'      => '',
        'price_lte'      => '',
        'price'          => '',
        'variant_status' => '',          
        'price'          => params[:filters] && params[:filters][:missing_prices] ? 0 : ''
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
          'category_id'    => [ 'categories' , 'id'     ],
          'category_name'  => [ 'categories' , 'name'   ],
          'vendor_id'      => [ 'vendor'     , 'id'     ],
          'vendor_name'    => [ 'vendor'     , 'name'   ],
          'vendor_status'  => [ 'vendor'     , 'status' ],
          'price_gte'      => [ 'variants'   , 'price'  ],
          'price_lte'      => [ 'variants'   , 'price'  ],
          'price'          => [ 'variants'   , 'price'  ],
          'variant_status' => [ 'variants'   , 'status' ]
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
      @category_options = Category.options(@site.id)
      
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
        'category_id'  => '',
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
          'category_id'  => [ 'categories' , 'id'    ],
          'vendor_name'  => [ 'vendor'     , 'name'  ],
          'price'        => [ 'variants'   , 'price' ]
        }
      })
      render :json => {
        :pager => pager,
        :models => pager.items
      }      
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
          when 'vendor_id'          then product.vendor_id          = value
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
          when 'allow_gift_wrap'    then product.allow_gift_wrap    = value
          when 'gift_wrap_price'    then product.gift_wrap_price    = value
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
      
      resp = Caboose::StdClass.new
      name = params[:name]
      
      if name.length == 0
        resp.error = "The title cannot be empty."
      else
        p = Product.new(:site_id => @site.id, :title => name)
        p.save
        resp.redirect = "/admin/products/#{p.id}/general"
      end
      render :json => resp    
    end
    
    # DELETE /admin/products/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      p = Product.find(params[:id])
      p.status = 'Deleted'
      p.save
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/products'
      })
    end
    
    # GET /products/status-options
    def admin_status_options
      arr = ['Active', 'Inactive', 'Deleted']      
      render :json => arr.collect{ |status| { :value => status, :text => status }}
    end
    
    # GET /products/stackable-group-options
    def admin_stackable_group_options
      arr = ['Active', 'Inactive', 'Deleted']
      render :json => arr.collect{ |status| { :value => status, :text => status }}      
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
        
  end
end

