require 'aws'

module Caboose
	class Export < ActiveRecord::Base
		self.table_name = 'exports'
							
	  attr_accessible :id ,
	    :kind,
	    :date_created,
	    :date_processed,
	    :params,
	    :status
	    
	  STATUS_PENDING    = 'pending'
	  STATUS_PROCESSING = 'processing'
	  STATUS_FINISHED   = 'finished'
    
    def product_process
      self.kind = 'products'
      self.status = 'processing'
      self.save
      pager = Caboose::Pager.new(JSON.parse(self.params), {
        'site_id'        => params['site_id'],
        'vendor_name'    => '',
        'search_like'    => '', 
        'category_id'    => '',
        'category_name'  => '',
        'vendor_id'      => '',        
        'vendor_status'  => '',
        'price_gte'      => '',
        'price_lte'      => '',        
        'variant_status' => '',          
        'price'          => params['filters'] && params['filters']['missing_prices'] ? 0 : ''
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
      str = ''
      headers = ['ID','Title','Caption','Status','Vendor','URL Handle','Description','Variant Status','Variant Alternate ID','Variant SKU','Variant Price','Variant Quantity']
      str = CSV.generate_line(headers, :quote_char => '"')
      pager.items.each do |a|
        var = a.most_popular_variant
        arr = [
          a.id.to_s,
          (a.title ? a.title : ''),
          (a.caption ? a.caption : ''),
          (a.status ? a.status : ''),
          (a.vendor ? a.vendor.name : ''),
          (a.handle ? a.handle : ''),
          (a.description ? a.description : ''),
          (var ? var.status : ''),
          (var ? var.alternate_id : ''),
          (var ? var.sku : ''),
          (var ? var.price : ''),
          (var ? var.quantity : '')
        ]
        str += CSV.generate_line(arr, :quote_char => '"')
      end
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
      AWS.config({ :access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'] })
      bucket = AWS::S3::Bucket.new(config['bucket'])
      file = bucket.objects["assets/product_exports/#{self.id}.csv"]
      file.write(str, :content_type => "text/csv", :content_disposition => 'attachment; filename=products.csv')
      self.date_processed = DateTime.now.utc
      self.status = 'finished'
      self.save
    end

    def user_process
      self.kind = 'users'
      self.status = 'processing'
      self.save
      pager = Caboose::Pager.new(JSON.parse(self.params), {
          'site_id'         => params['site_id'],
          'first_name_like' => '',
          'last_name_like'  => '',
          'username_like'   => '',
          'email_like'      => '',
        },{
          'model'          => 'Caboose::User',
          'sort'           => 'last_name, first_name',
          'desc'           => false,
          'base_url'       => '/admin/users',
          'use_url_params' => false
      })
      str = ''
      headers = ['ID','First Name','Last Name','Username','Email','Phone']
      str = CSV.generate_line(headers, :quote_char => '"')
      pager.items.each do |a|
        arr = [
          a.id.to_s,
          (a.first_name ? a.first_name : ''),
          (a.last_name ? a.last_name : ''),
          (a.username ? a.username : ''),
          (a.email ? a.email : ''),
          (a.phone ? a.phone : '')
        ]
        str += CSV.generate_line(arr, :quote_char => '"')
      end
      config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
      AWS.config({ :access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'] })
      bucket = AWS::S3::Bucket.new(config['bucket'])
      file = bucket.objects["assets/user_exports/#{self.id}.csv"]
      file.write(str, :content_type => "text/csv", :content_disposition => 'attachment; filename=users.csv')
      self.date_processed = DateTime.now.utc
      self.status = 'finished'
      self.save
    end
    
	end
end