module Caboose
  
  PageBarGenerator.class_eval do
    def all_records
      return model_with_includes.where(where)
    end
  end
  
  class ProductsController < Caboose::ApplicationController
           
    # @route GET /admin/products/stubs
    def admin_stubs      
      title = params[:title] ? params[:title].strip.downcase.split(' ') : nil
      render :json => [] and return if title.nil? || title.length == 0
      
      where = ["site_id = ?","status = ?"]      
      vars = [@site.id, 'Active']
      title.each do |str|
        where << 'lower(title) like ?'
        vars << "%#{str}%"
      end      
      where = where.join(' and ')
      query = ["select id, title, option1, option2, option3 from store_products where #{where} order by title limit 20"]
      vars.each{ |v| query << v }
      
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))
      arr = rows.collect do |row|
        has_options = row[2] || row[3] || row[4] ? true : false
        variant_id = nil
        if !has_options
          v = Variant.where(:product_id => row[0].to_i, :status => 'Active').first
          variant_id = v.id if v
        end          
        { :id => row[0], :title => row[1], :variant_id => variant_id }
      end        
      render :json => arr
    end
    
    # @route GET /products/:id/info
    def info
      p = Product.find(params[:id])
      render :json => { 
        :product => p,
        :option1_values => p.option1_values_with_media(true),
        :option2_values => p.option2_values_with_media(true),
        :option3_values => p.option3_values_with_media(true)
      }
    end
    
    # @route GET /products
    # @route GET /products/:id
    # @route_constraints { :id => /.*/ }        
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
          add_ga_event('Products', 'View', 'Sales')
          render 'caboose/products/sales' and return
          
        elsif params[:id].to_i > 0 && Product.exists?(params[:id])
          @product = Product.find(params[:id])
          render 'caboose/products/not_available' and return if @product.status == 'Inactive' || @product.site_id != @site.id
          
          @category       = @product.categories.first
          @review         = Review.new
          @reviews        = Review.where(:product_id => @product.id).limit(10).reorder("id DESC") || nil
          @logged_in_user = logged_in_user
          
          add_ga_event('Products', 'View', "Product #{@product.id}")
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
        'search_like'     => '',
        'cm_category_id'  => cat.id # This filters the CategoryMembership object that we'll be sorting on
      }, {
        'model'           => 'Caboose::Product',
        #'sort'            => if params[:sort] then params[:sort] else 'store_products.sort_order' end,
        #'sort'            => if params[:sort] then params[:sort] else 'store_category_memberships.sort_order' end,
        'sort'            => 'store_category_memberships.sort_order',
        'base_url'        => url_without_params,
        'items_per_page'  => 15,
        'use_url_params'  => false,
        
        'abbreviations'   => {
          'search_like'   => 'title_concat_store_products.alternate_id_concat_vendor_name_concat_category_name_like',
        },
        
        'includes' => {
          'cm_category_id'  => [ 'category_memberships' , 'category_id' ],          
          'category_id'     => [ 'categories'           , 'id'          ],
          'category_name'   => [ 'categories'           , 'name'        ],
          'vendor_id'       => [ 'vendor'               , 'id'          ],
          'vendor_name'     => [ 'vendor'               , 'name'        ],
          'vendor_status'   => [ 'vendor'               , 'status'      ],
          'price_gte'       => [ 'variants'             , 'price'       ],
          'price_lte'       => [ 'variants'             , 'price'       ],
          'variant_status'  => [ 'variants'             , 'status'      ]
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
      add_ga_event('Products', 'View', "Category #{cat.id}")      
    end
    
    def show      
    end        
    
    #=============================================================================
    # Admin actions
    #=============================================================================
    
    # @route PUT /admin/products/update-vendor-status/:id
    def admin_update_vendor_status
      vendor = Vendor.find(params[:id])
      vendor.status = params[:status]
      render :json => vendor.save
    end
    
    # @route GET /admin/products/alternate-ids
    def admin_alternate_ids
      return if !user_is_allowed('products', 'view')
      
      query = ["select P.id as product_id, V.id as variant_id, P.title, P.option1, V.option1 as option1_value, P.option2, V.option2 as option2_value, P.option3, V.option3 as option3_value, V.alternate_id
        from store_variants V
        left join store_products P on V.product_id = P.id
        where P.site_id = ?
        order by title, P.option1, V.option1", @site.id]      
      rows = ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.send(:sanitize_sql_array, query))
      
      @rows = rows.collect{ |row| Caboose::StdClass.new({
        :product_id     => row[0],      
        :variant_id     => row[1],
        :title          => row[2],
        :option1        => row[3],
        :option1_value  => row[4],
        :option2        => row[5],
        :option2_value  => row[6],
        :option3        => row[7],
        :option3_value  => row[8],
        :alternate_id   => row[9]        
      })}

      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products
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
        'vendor_status'  => '',
        'price_gte'      => '',
        'price_lte'      => '',        
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
    
    # @route GET /admin/products/json
    def admin_json
      return if !user_is_allowed('products', 'view')
      
      # Temporary patch for vendor name sorting; Fix this
      params[:sort] = 'store_vendors.name' if params[:sort] == 'vendor'
      
      pager = Caboose::PageBarGenerator.new(params, {
        'site_id'      => @site.id,
        'vendor_name'  => '',
        'search_like'  => '',
        'category_id'  => '',
        'status'       => 'Active',
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
    
    # @route GET /admin/products/:id/json
    def admin_json_single
      p = Product.find(params[:id])
      render :json => p      
    end


    # @route GET /admin/products/exports/:id/json    
    def admin_export_single
      return unless (user_is_allowed_to 'edit', 'products')
      e = Caboose::Export.where(:id => params[:id]).first      
      render :json => e
    end

    # @route POST /admin/products/export
    def admin_export
      return unless (user_is_allowed_to 'edit', 'products')      
      resp = Caboose::StdClass.new
      e = Caboose::Export.create(
        :kind => 'products',
        :date_created => DateTime.now.utc,        
        :params => params.to_json,
        :status => 'pending'
      )
      e.delay(:queue => 'caboose_general', :priority => 8).product_process if Rails.env.production?
      e.product_process if Rails.env.development?
      resp.new_id = e.id
      resp.success = true
      render :json => resp
    end

    
    # @route GET /admin/products/:id
    # @route GET /admin/products/:id/general
    def admin_edit_general
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products/:id/description
    def admin_edit_description   
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products/:id/options
    def admin_edit_options
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'          
    end
    
    # @route GET /admin/products/:id/categories
    def admin_edit_categories
      return if !user_is_allowed('products', 'edit')
      @product = Product.find(params[:id])
      @top_categories = Category.where(:parent_id => 1).reorder('name').all
      @selected_ids = @product.categories.collect{ |cat| cat.id }
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products/:id/images
    def admin_edit_images    
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])  
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]      
      access_key = config['access_key_id']
      secret_key = config['secret_access_key']
      bucket     = config['bucket']      
      policy = {        
        "expiration" => 1.hour.from_now.utc.xmlschema,
        "conditions" => [
          { "bucket" => "#{bucket}-uploads" },          
          { "acl" => "public-read" },
          [ "starts-with", "$key", '' ],      
          [ 'starts-with', '$name', '' ],   
          [ 'starts-with', '$Filename', '' ],          
        ]
      }
      @policy = Base64.encode64(policy.to_json).gsub(/\n/,'')      
      @signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret_key, @policy)).gsub("\n","")
      @s3_upload_url = "https://#{bucket}-uploads.s3.amazonaws.com/"
      @aws_access_key_id = access_key                            
          
      @top_media_category = @product.media_category.parent
      @media_category = @product.media_category

      render :layout => 'caboose/admin'
    end
    
    # @route POST /admin/products/:id/images
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
    
    # @route GET /admin/products/:id/collections
    def admin_edit_collections
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end    
    
    # @route GET /admin/products/:id/seo
    def admin_edit_seo
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
    
    # @route GET /admin/products/:id/delete
    def admin_delete_form
      return if !user_is_allowed('products', 'edit')    
      @product = Product.find(params[:id])
      render :layout => 'caboose/admin'
    end
      
    # @route PUT /admin/products/:id
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
          when 'title'
            product.title = value
            c = MediaCategory.where(:id => product.media_category_id).last
            c.name = value
            c.save
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
          when 'option1'            then product.option1            = (value.blank? ? nil : value)
          when 'option2'            then product.option2            = (value.blank? ? nil : value)
          when 'option3'            then product.option3            = (value.blank? ? nil : value)
          when 'option1_media'      then product.option1_media      = value
          when 'option2_media'      then product.option2_media      = value
          when 'option3_media'      then product.option3_media      = value
          when 'default1'
            product.default1 = (value.blank? ? nil : value)
            Variant.where(:product_id => product.id, :option1 => nil).each do |p|
              p.option1 = (value.blank? ? nil : value)
              p.save
            end
          when 'default2'
            product.default2 = (value.blank? ? nil : value)
            Variant.where(:product_id => product.id, :option2 => nil).each do |p|
              p.option2 = (value.blank? ? nil : value)
              p.save
            end
          when 'default3'
            product.default3 = (value.blank? ? nil : value)
            Variant.where(:product_id => product.id, :option3 => nil).each do |p|
              p.option3 = (value.blank? ? nil : value)
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
    
    # @route_priority 1
    # @route GET /admin/products/new
    def admin_new
      return if !user_is_allowed('products', 'add')
      render :layout => 'caboose/admin'
    end
    
    # @route POST /admin/products
    def admin_add
      return if !user_is_allowed('products', 'add')
      
      resp = Caboose::StdClass.new
      name = params[:name]
      pd = @site.product_default
      vd = @site.variant_default
      
      if name.length == 0
        resp.error = "The title cannot be empty."
      else                
        p = Product.new(:site_id => @site.id, :title => name)
        mc = MediaCategory.where(:site_id => @site.id).where("parent_id IS NULL").exists? ? MediaCategory.where(:site_id => @site.id).where("parent_id IS NULL").last : MediaCategory.create(:name => "Media", :site_id => @site.id)
        pc = MediaCategory.where(:name => "Products", :site_id => @site.id).exists? ? MediaCategory.where(:name => "Products", :site_id => @site.id).last : MediaCategory.create(:name => "Products", :site_id => @site.id, :parent_id => mc.id)
        c = MediaCategory.create(:site_id => @site.id, :name => name, :parent_id => pc.id)
        p.media_category_id = c.id
                        
        p.vendor_id       = pd.vendor_id      
        p.option1         = pd.option1        
        p.option2         = pd.option2        
        p.option3         = pd.option3
        p.status          = pd.status
        p.on_sale         = pd.on_sale
        p.allow_gift_wrap = pd.allow_gift_wrap
        p.gift_wrap_price = pd.gift_wrap_price
        
        p.save
        
        v = Variant.new
        v.product_id = p.id 
        v.option1    = p.default1 if p.option1
        v.option2    = p.default2 if p.option2
        v.option3    = p.default3 if p.option3
        
        v.cost                           = vd.cost                         
        v.price                          = vd.price                              
        v.available                      = vd.available                    
        v.quantity_in_stock              = vd.quantity_in_stock            
        v.ignore_quantity                = vd.ignore_quantity              
        v.allow_backorder                = vd.allow_backorder              
        v.weight                         = vd.weight                       
        v.length                         = vd.length                       
        v.width                          = vd.width                        
        v.height                         = vd.height                       
        v.volume                         = vd.volume                       
        v.cylinder                       = vd.cylinder                     
        v.requires_shipping              = vd.requires_shipping            
        v.taxable                        = vd.taxable                      
        v.shipping_unit_value            = vd.shipping_unit_value          
        v.flat_rate_shipping             = vd.flat_rate_shipping           
        v.flat_rate_shipping_package_id  = vd.flat_rate_shipping_package_id
        v.flat_rate_shipping_method_id   = vd.flat_rate_shipping_method_id 
        v.flat_rate_shipping_single      = vd.flat_rate_shipping_single    
        v.flat_rate_shipping_combined    = vd.flat_rate_shipping_combined     
        v.status                         = vd.status                       
        v.downloadable                   = vd.downloadable                 
        v.is_bundle                      = vd.is_bundle
        
        v.save
        
        resp.new_id = p.id
        resp.new_variant_id = v.id
        resp.success = true
        resp.redirect = "/admin/products/#{p.id}/general"
      end
      render :json => resp    
    end

    # @route DELETE /admin/products/bulk
    def admin_bulk_delete
      return unless user_is_allowed_to 'delete', 'products'
      params[:model_ids].each do |product_id|
        prod = Product.where(:id => product_id).first
        prod.destroy if prod
      end
      resp = Caboose::StdClass.new('success' => true)
      render :json => resp
    end
    
    # @route DELETE /admin/products/:id
    def admin_delete
      return if !user_is_allowed('products', 'delete')
      p = Product.find(params[:id])
      p.status = 'Deleted'
      p.save
      render :json => Caboose::StdClass.new({
        :redirect => '/admin/products'
      })
    end
    
    # @route_priority 3
    # @route GET /admin/products/status-options
    def admin_status_options
      arr = ['Active', 'Inactive', 'Deleted']      
      render :json => arr.collect{ |status| { :value => status, :text => status }}
    end
    
    # @route GET /products/stackable-group-options
    def admin_stackable_group_options
      arr = ['Active', 'Inactive', 'Deleted']
      render :json => arr.collect{ |status| { :value => status, :text => status }}      
    end
    
    # @route_priority 2
    # @route GET /admin/products/combine
    def admin_combine_select_products
    end
    
    # @route_priority 4
    # @route GET /admin/products/combine-step2
    def admin_combine_assign_title
    end
    
    # @route_priority 5
    # @route POST /admin/products/combine
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
    
    # @route_priority 6
    # @route GET /admin/products/sort
    def admin_sort
      #@products   = Product.active
      #@vendors    = Vendor.active
      #@categories = Category.all      
      render :layout => 'caboose/admin'
    end
    
    # @route PUT /admin/categories/:category_id/products/sort-order
    def admin_update_sort_order
      cat_id = params[:category_id]      
      params[:product_ids].each_with_index do |product_id, i|
        cm = CategoryMembership.where(:category_id => cat_id, :product_id => product_id).first
        cm.sort_order = i
        cm.save
      end      
      render :json => { :success => true }
    end
    
    #=============================================================================
    # API actions
    #=============================================================================
    
    # @route GET /api/products
    def api_index
      render :json => Product.where(:status => 'Active')
    end

    # @route GET /api/products/keyword
    def api_keyword
      query = params[:query]
      resp = Caboose::StdClass.new({'products' => {}})
      if query && !query.blank?
        resp.products = Product.select('title, id').where(:status => 'Active').where(:site_id => @site.id).where('title ILIKE (?)',"%#{query}%").order(:title).limit(30)
      end
      render :json => resp
    end
    
    # @route GET /api/products/:id
    def api_details
      p = Product.where(:id => params[:id]).first
      render :json => p ? p : { :error => 'Invalid product ID' }
    end
    
    # @route GET /api/products/:id/variants
    def api_variants
      p = Product.where(:id => params[:id]).first
      render :json => p ? p.variants : { :error => 'Invalid product ID' }
    end

    

        
  end
end

