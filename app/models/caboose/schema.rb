
class Caboose::Schema < Caboose::Utilities::Schema

  # Tables (in order) that were renamed in the development of the gem.
  def self.renamed_tables
    {
      :roles_users              => :role_memberships,
      :permissions_roles        => :role_permissions,
      #:page_block_field_values => :fields,
      #:page_block_fields       => :field_types,
      :page_block_types         => :block_types,
      :page_blocks              => :blocks,      
      :store_order_discounts    => :store_invoice_discounts,
      :store_order_packages     => :store_invoice_packages,
      :store_order_transactions => :store_invoice_transactions,
      :store_orders             => :store_invoices
    }
  end

  def self.renamed_columns
    {
      #Caboose::Field     => { :page_block_id        => :block_id,
      #                        :page_block_field_id  => :field_type_id },
      #Caboose::FieldType => { :page_block_type_id   => :block_type_id },
      Caboose::Block              => { :page_block_type_id => :block_type_id },
      Caboose::Discount           => { :order_id => :invoice_id },
      Caboose::GiftCard           => { :min_order_total => :min_invoice_total },
      Caboose::Invoice            => { :order_number => :invoice_number },
      Caboose::InvoiceDiscount    => { :order_id => :invoice_id },
      Caboose::InvoicePackage     => { :order_id => :invoice_id },        
      Caboose::InvoiceTransaction => { :order_id => :invoice_id },
      Caboose::LineItem           => { :order_id => :invoice_id, :order_package_id  => :invoice_package_id },
      Caboose::RetargetingConfig  => { :conversion_id   => :google_conversion_id, :labels_function => :google_labels_function }      
    }
  end

  def self.removed_columns
    {
      Caboose::Block => [:block_type],
      #Caboose::FieldType => [:model_binder_options],
      Caboose::AbValue => [:i, :text],
      Caboose::AbOption => [:text],      
      #Caboose::Field => [:child_block_id],
      Caboose::BlockType => [:layout_function],
      Caboose::CalendarEvent => [
        :repeat_period , 
        :repeat_sun    , 
        :repeat_mon    , 
        :repeat_tue    , 
        :repeat_wed    , 
        :repeat_thu    , 
        :repeat_fri    , 
        :repeat_sat    , 
        :repeat_start  , 
        :repeat_end    
      ],
      Caboose::CalendarEventGroup => [
        :repeat_period , 
        :repeat_sun    , 
        :repeat_mon    , 
        :repeat_tue    , 
        :repeat_wed    , 
        :repeat_thu    , 
        :repeat_fri    , 
        :repeat_sat    , 
        :repeat_start  , 
        :repeat_end        
      ],
      #Caboose::Discount => [
      #  :amount
      #],
      Caboose::Invoice => [
        :shipping_method       , 
        :shipping_method_code  ,
        :email                 ,        
        :payment_id            ,
        :gateway_id            ,
        #:date_authorized       ,
        #:date_captured         ,
        #:date_canceled         ,                
        :shipping_carrier      ,
        :shipping_service_code ,
        :shipping_service_name ,        
        :transaction_id        ,        
        :transaction_service   ,
        :amount_discounted     ,
        :auth_code             ,                
        :date_shipped          ,                        
        :decremented           
      ],        
      #Caboose::PageCache => [:block],
      #Caboose::RetargetingConfig => [:fb_pixels_function],
      Caboose::ShippingPackage => [:price, :carrier, :service_code, :service_name, :shipping_method_id, :length, :width, :height],
      Caboose::Site => [:shipping_cost_function],
      Caboose::StoreConfig => [:use_usps, :allowed_shipping_codes, :default_shipping_code, :pp_relay_url, :pp_response_url],
      Caboose::Variant => [:quantity, :on_sale],
      Caboose::Vendor => [:vendor, :vendor_id]
    }
  end

  # Any column indexes that need to exist in the database
  def self.indexes
    {
      Caboose::Block                  => [:parent_id],
      Caboose::BlockType              => [:parent_id],
      Caboose::RoleMembership         => [ :role_id    , :user_id          ],
      Caboose::RolePermission         => [ :role_id    , :permission_id    ],
      Caboose::PostCategoryMembership => [ :post_id    , :post_category_id ]
      #Caboose::Session                => [ :session_id , :updated_at       ]
    }
  end

  # The schema of the database
  # { Model => [[name, data_type, options]] }
  def self.schema
    {
      Caboose::AbVariant => [
        [ :name           , :string ],
        [ :analytics_name , :string ],
      ],
      Caboose::AbOption => [
        [ :ab_variant_id , :integer ],
        [ :value         , :string  ]
      ],
      Caboose::AbValue => [
        [ :session_id    , :string  ],
        [ :ab_variant_id , :integer ],
        [ :ab_option_id  , :integer ]
      ],
      Caboose::Address => [
        [ :name          , :string  ],
        [ :first_name    , :string  ],
        [ :last_name     , :string  ],
        [ :street        , :string  ],
        [ :address1      , :string  ],
        [ :address2      , :string  ],
        [ :company       , :string  ],
        [ :city          , :string  ],
        [ :state         , :string  ],
        [ :province      , :string  ],
        [ :province_code , :string  ],
        [ :zip           , :string  ],
        [ :country       , :string  ],
        [ :country_code  , :string  ],
        [ :phone         , :string  ]
      ],      
      Caboose::Asset => [
        [ :page_id        , :integer    ],
        [ :user_id        , :integer    ],
        [ :date_uploaded  , :datetime   ],
        [ :name           , :string     ],
        [ :filename       , :string     ],
        [ :description    , :string     ],
        [ :extension      , :string     ]
      ],
      Caboose::Block => [
        [ :page_id               , :integer    ],
        [ :post_id               , :integer    ],
        [ :parent_id             , :integer    ],
        [ :media_id              , :integer    ],
        [ :block_type_id         , :integer    ],
        [ :sort_order            , :integer     , { :default => 0     }],
        [ :constrain             , :boolean     , { :default => false }],
        [ :full_width            , :boolean     , { :default => false }],        
        [ :name                  , :string     ],
        [ :value                 , :text       ],
        [ :file                  , :attachment ],
        [ :file_upload_name      , :string     ],
        [ :image                 , :attachment ],
        [ :image_upload_name     , :string     ]
      ],
      Caboose::BlockType => [        
        [ :parent_id                       , :integer ],
        [ :name                            , :string  ],
        [ :description                     , :string  ],
        [ :icon                            , :string  ],
        [ :is_global                       , :boolean , { :default => false }],
        [ :block_type_category_id          , :integer , { :default => 2 }],
        [ :render_function                 , :text    ],
        [ :use_render_function             , :boolean , { :default => false }],
        [ :use_render_function_for_layout  , :boolean , { :default => false }],
        [ :allow_child_blocks              , :boolean , { :default => false }],
        [ :default_child_block_type_id     , :integer ],
        [ :field_type                      , :string  ],
        [ :default                         , :text    ],
        [ :width                           , :integer ],
        [ :height                          , :integer ],
        [ :fixed_placeholder               , :boolean ],
        [ :options                         , :text    ],
        [ :options_function                , :text    ],
        [ :options_url                     , :string  ],
        [ :default_constrain               , :boolean , { :default => false }],
        [ :default_full_width              , :boolean , { :default => false }],
        [ :share                           , :boolean , { :default => true  }],
        [ :downloaded                      , :boolean , { :default => false }]
      ],
      Caboose::BlockTypeSiteMembership => [
        [ :site_id        , :integer ],
        [ :block_type_id  , :integer ]
      ],      
      Caboose::BlockTypeCategory => [
        [ :parent_id  , :integer ],
        [ :name       , :string  ]
      ],
      Caboose::BlockTypeSource => [
        [ :name       , :string ],
        [ :url        , :string ],
        [ :token      , :string ],
        [ :priority   , :integer, { :default => 0 }],
        [ :active     , :boolean, { :default => true }],
      ],
      Caboose::BlockTypeSummary => [
        [ :block_type_source_id , :integer ],
        [ :name                 , :string  ],
        [ :description          , :string  ]
      ],
      Caboose::Calendar => [
        [ :site_id      , :integer  ],
        [ :name         , :string   ],
        [ :description  , :text     ],
        [ :color        , :string   ]
      ],
      Caboose::CalendarEvent => [
        [ :calendar_id              , :integer  ],
        [ :calendar_event_group_id  , :integer  ],
        [ :name                     , :string   ],
        [ :description              , :text     ],
        [ :location                 , :string   ],
        [ :begin_date               , :datetime ],
        [ :end_date                 , :datetime ],
        [ :all_day                  , :boolean  , { :default => false }],        
        [ :repeats                  , :boolean  , { :default => false }]
      ],
      Caboose::CalendarEventGroup => [
        [ :frequency    , :integer  , { :default => 1 }],
        [ :period       , :string   , { :default => 'Week' }],        
        [ :repeat_by    , :string   ],
        [ :sun          , :boolean  , { :default => false }],
        [ :mon          , :boolean  , { :default => false }],
        [ :tue          , :boolean  , { :default => false }],
        [ :wed          , :boolean  , { :default => false }],
        [ :thu          , :boolean  , { :default => false }],
        [ :fri          , :boolean  , { :default => false }],
        [ :sat          , :boolean  , { :default => false }],
        [ :date_start   , :date     ],
        [ :repeat_count , :integer  ],
        [ :date_end     , :date     ]
      ],
      Caboose::Category => [
        [ :site_id               , :integer   ],
        [ :parent_id             , :integer   ],
        [ :alternate_id          , :string    ],
        [ :name                  , :string    ],
        [ :url                   , :string    ],
        [ :slug                  , :string    ],
        [ :status                , :string    ],
        [ :image_file_name       , :string    ],
        [ :image_content_type    , :string    ],
        [ :image_file_size       , :integer   ],
        [ :image_updated_at      , :datetime  ],
        [ :square_offset_x       , :integer   ],
        [ :square_offset_y       , :integer   ],
        [ :square_scale_factor   , :numeric   ],
        [ :sort_order            , :integer   ]
      ],
      Caboose::CategoryMembership => [        
        [ :category_id           , :integer ],
        [ :product_id            , :integer ],
        [ :sort_order            , :integer  , { :default => 0 }]
      ],
      Caboose::CustomizationMembership => [
        [ :product_id       , :integer ],
        [ :customization_id , :integer ]
      ],
      Caboose::DatabaseSession => [
        [ :session_id  , :string   , :null => false ],
        [ :data        , :text                      ],
        [ :created_at  , :datetime , :null => true  ],
        [ :updated_at  , :datetime , :null => true  ]
      ],
      Caboose::Discount => [
        [ :gift_card_id , :integer  ],
        [ :invoice_id   , :integer  ],                
        [ :amount       , :decimal   , { :precision => 8, :scale => 2 }]        
      ],
      Caboose::Domain => [
        [ :site_id            , :integer ],
        [ :domain             , :string  ],
        [ :primary            , :boolean, { :default => false }],
        [ :under_construction , :boolean, { :default => false }],
        [ :forward_to_primary , :boolean, { :default => false }],
        [ :forward_to_uri     , :string  ]
      ],
      Caboose::Font => [
        [ :site_id            , :integer ],
        [ :name               , :string  ],
        [ :family             , :string  ],
        [ :variant            , :string  ],
        [ :url                , :string  ]
      ],
      Caboose::FontFamily => [
        [ :name               , :string  ]
      ],
      Caboose::FontVariant => [
        [ :font_family_id     , :integer ],
        [ :variant            , :string  ],
        [ :ttf_url            , :string  ],
        [ :weight             , :string  ],
        [ :style              , :string  ],
        [ :sort_order         , :integer ]
      ],
      Caboose::GiftCard => [
        [ :site_id           , :integer  ],        
        [ :name              , :string   ],
        [ :code              , :string   ],
        [ :card_type         , :string   ],
        [ :total             , :decimal   , { :precision => 8, :scale => 2 }],
        [ :balance           , :decimal   , { :precision => 8, :scale => 2 }],
        [ :min_invoice_total , :decimal   , { :precision => 8, :scale => 2 }],        
        [ :date_available    , :datetime ],
        [ :date_expires      , :datetime ],
        [ :status            , :string   ]                                
      ],      
      Caboose::LineItem => [
        [ :invoice_id            , :integer  ],
        [ :invoice_package_id    , :integer  ],
        [ :variant_id            , :integer  ],
        [ :parent_id             , :integer  ],                
        [ :status                , :string   ],        
        [ :quantity              , :integer   , :default => 0 ],
        [ :unit_price            , :decimal   , { :precision => 8, :scale => 2 }],
        [ :subtotal              , :decimal   , { :precision => 8, :scale => 2 }],
        [ :notes                 , :text     ],
        [ :custom1               , :string   ],
        [ :custom2               , :string   ],
        [ :custom3               , :string   ],
        [ :is_gift               , :boolean   , { :default => false }],
        [ :include_gift_message  , :boolean   , { :default => false }],
        [ :gift_message          , :text     ],
        [ :gift_wrap             , :boolean   , { :default => false }],
        [ :hide_prices           , :boolean   , { :default => false }]
      ],
      Caboose::LineItemModification => [                          
        [ :line_item_id           , :integer ],
        [ :modification_id        , :integer ],
        [ :modification_value_id  , :integer ],
        [ :input                  , :string  ]
      ],
      Caboose::LoginLog => [
        [ :site_id        , :integer  ],
        [ :username       , :string   ],
        [ :user_id        , :integer  ],
        [ :date_attempted , :datetime ],
        [ :ip             , :string   ],        
        [ :success        , :boolean   , { :default => false }]      
      ],
      Caboose::MediaCategory => [
        [ :parent_id         , :integer ],
        [ :site_id           , :integer ],
        [ :name              , :string  ]        
      ],
      Caboose::Media => [
        [ :media_category_id , :integer    ],
        [ :name              , :string     ],
        [ :description       , :text       ],
        [ :sort_order        , :integer    ],
        [ :original_name     , :string     ],
        [ :image             , :attachment ],
        [ :file              , :attachment ],
        [ :processed         , :boolean     , { :default => false }]
      ],      
      Caboose::Modification => [      
        [ :product_id               , :integer ],
        [ :sort_order               , :integer  , { :default => 0 }],
        [ :name                     , :string  ]             
      ],
      Caboose::ModificationValue => [
        [ :modification_id   , :integer  ],
        [ :sort_order        , :integer   , { :default => 0 }],
        [ :value             , :string   ],
        [ :is_default        , :boolean   , { :default => false }],
        [ :price             , :decimal   , { :precision => 8, :scale => 2 }],
        [ :requires_input    , :boolean   , { :default => false }],        
        [ :input_description , :string   ]
      ],
      Caboose::InvoiceTransaction => [
        [ :invoice_id            , :integer  ],
        [ :date_processed        , :datetime ],
        [ :transaction_type      , :string   ],
        [ :amount                , :decimal   , { :precision => 8, :scale => 2 }],        
        [ :transaction_id        , :string   ],
        [ :auth_code             , :string   ],
        [ :response_code         , :string   ],
        [ :success               , :boolean  ]        
      ],
      Caboose::InvoiceDiscount => [
        [ :invoice_id            , :integer ],
        [ :discount_id           , :integer ]
      ],
      Caboose::InvoicePackage => [
        [ :invoice_id           , :integer ],
        [ :shipping_method_id   , :integer ],
        [ :shipping_package_id  , :integer ],
        [ :status               , :string  ],
        [ :tracking_number      , :string  ],
        [ :total                , :decimal  , { :precision => 8, :scale => 2 }]
      ],
      Caboose::Invoice => [
        [ :site_id               , :integer  ],
        [ :invoice_number        , :integer  ],
        [ :alternate_id          , :integer  ],        
        [ :subtotal              , :decimal  , { :precision => 8, :scale => 2 }],
        [ :tax                   , :decimal  , { :precision => 8, :scale => 2 }],
        [ :tax_rate              , :decimal  , { :precision => 8, :scale => 2 }],
        [ :shipping              , :decimal  , { :precision => 8, :scale => 2 }],
        [ :handling              , :decimal  , { :precision => 8, :scale => 2 }],
        [ :gift_wrap             , :decimal  , { :precision => 8, :scale => 2 }],
        [ :custom_discount       , :decimal  , { :precision => 8, :scale => 2 }],
        [ :discount              , :decimal  , { :precision => 8, :scale => 2 }],
        [ :total                 , :decimal  , { :precision => 8, :scale => 2 }],
        [ :cost                  , :decimal  , { :precision => 8, :scale => 2, :default => 0.00 }],
        [ :profit                , :decimal  , { :precision => 8, :scale => 2, :default => 0.00 }],
        [ :customer_id           , :integer  ],
        [ :financial_status      , :string   ],
        [ :shipping_address_id   , :integer  ],
        [ :billing_address_id    , :integer  ],
        [ :notes                 , :text     ],
        [ :status                , :string   ],
        [ :date_created          , :datetime ],
        [ :date_authorized       , :datetime ],
        [ :date_captured         , :datetime ],
        [ :date_shipped          , :datetime ],
        [ :referring_site        , :text     ],
        [ :landing_page          , :string   ],
        [ :landing_page_ref      , :string   ],
        [ :auth_amount           , :decimal  , { :precision => 8, :scale => 2 }],
        [ :gift_message          , :text     ],
        [ :include_receipt       , :boolean  , { :default => true }]
        
        #[ :email                 , :string   ],
        #[ :invoice_number        , :string   ],
        #[ :payment_id            , :integer  ],
        #[ :gateway_id            , :integer  ],
        #[ :date_authorized       , :datetime ],
        #[ :date_captured         , :datetime ],
        #[ :date_cancelled        , :datetime ],                
        #[ :shipping_carrier      , :string   ],
        #[ :shipping_service_code , :string   ],
        #[ :shipping_service_name , :string   ],        
        #[ :transaction_id        , :string   ],
        #[ :transaction_id        , :string   ],
        #[ :transaction_service   , :string   ],
        #[ :amount_discounted     , :numeric  ],
        #[ :auth_code             , :string   ],                
        #[ :date_shipped          , :datetime ],                        
        #[ :decremented           , :boolean  ]
      ],      
      Caboose::Page => [
        [ :site_id               , :integer ],
        [ :parent_id             , :integer ],
        [ :title                 , :string  ],
        [ :menu_title            , :string  ],
        [ :slug                  , :string  ],
        [ :alias                 , :string  ],
        [ :uri                   , :string  ],
        [ :redirect_url          , :string  ],
        [ :hide                  , :boolean , { :default => false }],
        [ :content_format        , :integer , { :default => Caboose::Page::CONTENT_FORMAT_HTML }],
        [ :custom_css            , :text    ],
        [ :custom_js             , :text    ],
        [ :linked_resources      , :text    ],
        [ :layout                , :string  ],
        [ :sort_order            , :integer , { :default => 0                }],
        [ :custom_sort_children  , :boolean , { :default => false            }],
        [ :seo_title             , :string  , { :limit => 70                 }],
        [ :meta_keywords         , :text    ], 
        [ :meta_description      , :string  , { :limit => 156                }],
        [ :meta_robots           , :string  , { :default => 'index, follow'  }],
        [ :canonical_url         , :string  ],
        [ :fb_description        , :string  , { :limit => 156 }],
        [ :gp_description        , :string  , { :limit => 156 }]
      ],
      Caboose::PageCache => [
        [ :page_id               , :integer ],
        [ :render_function       , :text    ],
        [ :block                 , :binary  ],
        [ :refresh               , :boolean , { :default => false }]        
      ],
      Caboose::PageCustomField => [
        [ :site_id           , :integer ],
        [ :key               , :string  ],
        [ :name              , :string  ],
        [ :field_type        , :string  ],
        [ :default_value     , :text    ],
        [ :options           , :text    ],
        [ :sort_order        , :integer  , { :default => 0 }]
      ],
      Caboose::PageCustomFieldValue => [
        [ :page_id              , :integer ],
        [ :page_custom_field_id , :integer ],
        [ :key                  , :string  ],
        [ :value                , :text    ],
        [ :sort_order           , :integer  , { :default => 0 }]
      ],
      Caboose::PagePermission => [
        [ :role_id , :integer  ],
        [ :page_id , :integer  ],
        [ :action  , :string   ]
      ],
      Caboose::PageTag => [        
        [ :page_id , :integer  ],
        [ :tag     , :string   ]
      ],
      Caboose::PermanentRedirect => [
        [ :site_id  , :integer ],
        [ :priority , :integer , { :default => 0 }],
        [ :is_regex , :boolean , { :default => false }],
        [ :old_url  , :string  ],
        [ :new_url  , :string  ]
      ],
      Caboose::Permission => [
        [ :resource , :string ],
        [ :action   , :string ]
      ],
      Caboose::Post => [
        [ :site_id              , :integer    ],
        [ :title                , :text       ],
        [ :subtitle             , :text       ],
        [ :author               , :text       ],
        [ :body                 , :text 		  ],
        [ :preview              , :text       ],
        [ :hide                 , :boolean    ],
        [ :image_url            , :text 		  ],
        [ :published            , :boolean    ],
        [ :created_at           , :datetime   ],
        [ :updated_at           , :datetime   ],
        [ :image                , :attachment ],
        [ :slug                 , :string     ],        
        [ :uri                  , :string     ]
      ],      
      Caboose::PostCategory => [
        [ :site_id  , :integer ],
        [ :name     , :string  ]
      ],
      Caboose::PostCategoryMembership => [
        [ :post_id          , :integer ],
        [ :post_category_id , :integer ]
      ],
      Caboose::PostCustomField => [
        [ :site_id           , :integer ],
        [ :key               , :string  ],
        [ :name              , :string  ],
        [ :field_type        , :string  ],
        [ :default_value     , :text    ],
        [ :options           , :text    ],
        [ :sort_order        , :integer  , { :default => 0 }]
      ],
      Caboose::PostCustomFieldValue => [
        [ :post_id              , :integer ],
        [ :post_custom_field_id , :integer ],
        [ :key                  , :string  ],
        [ :value                , :text    ],
        [ :sort_order           , :integer  , { :default => 0 }]
      ],
      Caboose::Product => [
        [ :site_id               , :integer   ],
        [ :alternate_id          , :string    ],
        [ :title                 , :string    ],
        [ :caption               , :string    ],
        [ :description           , :text      ],
        [ :handle                , :string    ],
        [ :vendor_id             , :integer   ],
        [ :option1               , :string    ],
        [ :option2               , :string    ],
        [ :option3               , :string    ],
        [ :option1_media         , :boolean    , { :default => false }],
        [ :option2_media         , :boolean    , { :default => false }],
        [ :option3_media         , :boolean    , { :default => false }],        
        [ :category_id           , :integer   ],
        [ :status                , :string    ],
        [ :default1              , :string    ],
        [ :default2              , :string    ],
        [ :default3              , :string    ],
        [ :seo_title             , :string    ],
        [ :seo_description       , :string    ],
        [ :alternate_id          , :string    ],
        [ :date_available        , :datetime  ],
        [ :custom_input          , :text      ],
        [ :sort_order            , :integer   ],
        [ :featured              , :boolean   , :default => false ],
        [ :stackable_group_id    , :integer   ],
        [ :on_sale               , :boolean   , { :default => false }],
        [ :allow_gift_wrap       , :boolean   , { :default => false }],
        [ :gift_wrap_price       , :decimal   , { :precision => 8, :scale => 2 }],
        [ :media_category_id     , :integer   ]
      ],         
      Caboose::ProductImage => [
        [ :product_id            , :integer  ],
        [ :alternate_id          , :string   ],
        [ :title                 , :string   ],
        [ :position              , :integer  ],
        [ :image_file_name       , :string   ],
        [ :image_content_type    , :string   ],
        [ :image_file_size       , :integer  ],
        [ :image_updated_at      , :datetime ],
        [ :square_offset_x       , :integer  ],
        [ :square_offset_y       , :integer  ],
        [ :square_scale_factor   , :numeric  ],
        [ :media_id              , :integer  ]
      ],
      Caboose::ProductImageVariant => [
        [ :product_image_id      , :integer ],
        [ :variant_id            , :integer ]
      ],
      Caboose::RetargetingConfig => [
        [ :site_id                 , :integer  ],
        [ :google_conversion_id    , :string   ],                
        [ :google_labels_function  , :text     ],
        [ :fb_pixel_id             , :string   ],
        [ :fb_vars_function        , :text     ]
        #[ :fb_access_token         , :string   ],
        #[ :fb_access_token_expires , :datetime ]        
      ],
      Caboose::Review => [
        [ :product_id            , :integer   ],
        [ :content               , :string    ],
        [ :name                  , :string    ],
        [ :rating                , :decimal   ] 
      ],
      Caboose::Role => [
        [ :site_id              , :integer  ],
        [ :parent_id            , :integer  ],
        [ :name                 , :string   ],
        [ :description          , :string   ]
      ],
      Caboose::RoleMembership => [
        [ :role_id, :integer ],
        [ :user_id, :integer ]
      ],
      Caboose::RolePermission => [
	    	[ :role_id        , :integer ],
	    	[ :permission_id  , :integer ]
	    ],
	    Caboose::SearchFilter => [
        [ :url                   , :string   ],
        [ :title_like            , :string   ],
        [ :search_like           , :string   ],
        [ :category_id           , :integer  ],
        [ :category              , :text     ],
        [ :vendors               , :text     ],
        [ :option1               , :text     ],
        [ :option2               , :text     ],
        [ :option3               , :text     ],        
        [ :prices                , :text     ] 
      ],
      Caboose::Setting => [
        [ :site_id  , :integer ],
        [ :name     , :string  ],
        [ :value    , :text    ]
      ],
      Caboose::ShippingMethod => [        
        [ :carrier          , :string  ],
        [ :service_code     , :string  ],
        [ :service_name     , :string  ]        
      ],      
      Caboose::ShippingPackage => [
        [ :site_id            , :integer ],
        [ :name               , :string  ],
        [ :inside_length      , :decimal ],
        [ :inside_width       , :decimal ],
        [ :inside_height      , :decimal ],
        [ :outside_length     , :decimal ],
        [ :outside_width      , :decimal ],
        [ :outside_height     , :decimal ],        
        [ :volume             , :decimal ],
        [ :empty_weight       , :decimal ],
        [ :cylinder           , :boolean , { :default => false }],
        [ :priority           , :integer , { :default => 1 }],
        [ :flat_rate_price    , :decimal ]
      ],
      Caboose::ShippingPackageMethod => [
        [ :shipping_package_id  , :integer ],
        [ :shipping_method_id   , :integer ]
      ],
      Caboose::Site => [
        [ :name                    , :string     ],
        [ :description             , :text       ],
        [ :under_construction_html , :text       ],
        [ :use_store               , :boolean     , { :default => false }],
        [ :use_fonts               , :boolean     , { :default => true  }],
        [ :logo                    , :attachment ],        
        [ :is_master               , :boolean     , { :default => false }],
        [ :allow_self_registration , :boolean     , { :default => false }],
        [ :analytics_id            , :string     ],        
        [ :use_retargeting         , :boolean     , { :default => false }],
        [ :date_js_updated         , :datetime   ],
        [ :date_css_updated        , :datetime   ],
        [ :default_layout_id       , :integer    ],
        [ :login_fail_lock_count   , :integer     , { :default => 5 }]
      ],
      Caboose::SiteMembership => [
        [ :site_id     , :integer ],
        [ :user_id     , :integer ],
        [ :role        , :string  ]
      ],            
      Caboose::SmtpConfig => [
        [ :site_id              , :integer ],
        [ :address              , :string  , { :default => 'localhost' }],
        [ :port                 , :integer , { :default => 25 }],
        [ :domain               , :string ],
        [ :user_name            , :string ],
        [ :password             , :string ],
        [ :authentication       , :string ], # :plain, :login, :cram_md5.
        [ :enable_starttls_auto , :boolean , { :default => true }],
        [ :from_address         , :string ]
      ],
      Caboose::SocialConfig => [
        [ :site_id              , :integer ],
        [ :facebook_page_id     , :string ],
        [ :twitter_username     , :string ],
        [ :instagram_username   , :string ],
        [ :instagram_user_id    , :string ],
        [ :instagram_access_token , :text ],
        [ :youtube_url          , :string ],
        [ :pinterest_url        , :string ],
        [ :vimeo_url            , :string ],
        [ :rss_url              , :string ],
        [ :google_plus_url      , :string ],
        [ :linkedin_url         , :string ],
        [ :google_analytics_id  , :string ],
        [ :google_analytics_id2 , :string ],
        [ :auto_ga_js           , :boolean , { :default => false }]
      ],
      Caboose::StackableGroup => [       
        [ :name           , :string  ],
        [ :extra_length   , :decimal ],
        [ :extra_width    , :decimal ],
        [ :extra_height   , :decimal ],
        [ :max_length     , :decimal ],
        [ :max_width      , :decimal ],
        [ :max_height     , :decimal ]
      ],
      Caboose::StoreConfig => [
        [ :site_id                     , :integer ],     
        [ :pp_name                     , :string  ],
        [ :pp_testing                  , :boolean , { :default => true }],        
        #[ :pp_username                 , :string  ],
        #[ :pp_password                 , :string  ],                
        #[ :pp_relay_domain             , :string  ],                
        [ :authnet_api_login_id        , :string  ], # pp_username
        [ :authnet_api_transaction_key , :string  ], # pp_password
        [ :authnet_relay_domain        , :string  ], # pp_relay_domain
        [ :stripe_secret_key           , :string  ],
        [ :stripe_publishable_key      , :string  ],
        [ :ups_username                , :string  ],
        [ :ups_password                , :string  ],
        [ :ups_key                     , :string  ],
        [ :ups_origin_account          , :string  ],
        [ :usps_username               , :string  ],
        [ :usps_secret_key             , :string  ],
        [ :usps_publishable_key        , :string  ],                
        [ :fedex_username              , :string  ],
        [ :fedex_password              , :string  ],
        [ :fedex_key                   , :string  ],
        [ :fedex_account               , :string  ],
        [ :ups_min                     , :decimal  , { :precision => 8, :scale => 2 }],
        [ :ups_max                     , :decimal  , { :precision => 8, :scale => 2 }],
        [ :usps_min                    , :decimal  , { :precision => 8, :scale => 2 }],
        [ :usps_max                    , :decimal  , { :precision => 8, :scale => 2 }],
        [ :fedex_min                   , :decimal  , { :precision => 8, :scale => 2 }],                
        [ :fedex_max                   , :decimal  , { :precision => 8, :scale => 2 }],
        [ :taxcloud_api_id             , :string  ],
        [ :taxcloud_api_key            , :string  ],                
        [ :origin_address1             , :string  ],
        [ :origin_address2             , :string  ],
        [ :origin_state                , :string  ],
        [ :origin_city                 , :string  ],
        [ :origin_zip                  , :string  ],
        [ :origin_country              , :string  ],
        [ :fulfillment_email           , :string  ],
        [ :shipping_email              , :string  ],
        [ :handling_percentage         , :string  ],                
        [ :auto_calculate_packages     , :boolean  , { :default => true }],
        [ :auto_calculate_shipping     , :boolean  , { :default => true }],
        [ :auto_calculate_tax          , :boolean  , { :default => true }],
        [ :custom_packages_function    , :text    ],   
        [ :custom_shipping_function    , :text    ],   
        [ :custom_tax_function         , :text    ],
        [ :download_instructions       , :text    ],
        [ :length_unit                 , :string   , { :default => 'in' }],
        [ :weight_unit                 , :string   , { :default => 'oz' }],
        [ :download_url_expires_in     , :string   , { :default => 5    }],
        [ :starting_order_number       , :integer  , { :default => 1000 }]
      ],      
      Caboose::User => [
        [ :site_id                      , :integer    ],
        [ :first_name                   , :string     ],
        [ :last_name                    , :string     ],
        [ :username                     , :string     ],
        [ :email                        , :string     ],
        [ :address                      , :string     ],
        [ :address2                     , :string     ],
        [ :city                         , :string     ],
        [ :state                        , :string     ],
        [ :zip                          , :string     ],
        [ :phone                        , :string     ],
        [ :fax                          , :string     ],        
        [ :timezone                     , :string      , { :default => 'Central Time (US & Canada)' }],        
        [ :password                     , :string     ],
        [ :password_reset_id            , :string     ],
        [ :password_reset_sent          , :datetime   ],
        [ :token                        , :string     ],
        [ :date_created                 , :datetime   ],
        [ :image                        , :attachment ],
        [ :is_guest                     , :boolean     , { :default => false }],
        [ :customer_profile_id          , :string     ],
        [ :payment_profile_id           , :string     ],
        [ :locked                       , :boolean     , { :default => false }],
        [ :authnet_customer_profile_id  , :string     ],
        [ :authnet_payment_profile_id   , :string     ],
        [ :valid_authnet_payment_id     , :boolean     , { :default => false }],
        [ :stripe_customer_id           , :string     ],
        [ :card_last4                   , :string     ],
        [ :card_brand                   , :string     ],  
        [ :card_exp_month               , :integer    ],
        [ :card_exp_year                , :integer    ]
      ],
      Caboose::Variant => [
        [ :product_id                    , :integer  ],
        [ :alternate_id                  , :string   ],
        [ :sku                           , :string   ],
        [ :barcode                       , :string   ],
        [ :cost                          , :decimal   , { :precision => 8, :scale => 2, :default => 0.00 }],
        [ :price                         , :decimal   , { :precision => 8, :scale => 2, :default => 0.00 }],
        [ :sale_price                    , :decimal   , { :precision => 8, :scale => 2 }],
        [ :date_sale_starts              , :datetime ],
        [ :date_sale_ends                , :datetime ],
        [ :date_sale_end                 , :datetime ],        
        [ :clearance                     , :boolean   , { :default => false }],
        [ :clearance_price               , :decimal   , { :precision => 8, :scale => 2 }],
        [ :available                     , :boolean   , { :default => true  }],
        [ :quantity_in_stock             , :integer   , { :default => 0     }],        
        [ :ignore_quantity               , :boolean   , { :default => false }],
        [ :allow_backorder               , :boolean   , { :default => false }],
        [ :weight                        , :decimal  ],
        [ :length                        , :decimal  ],
        [ :width                         , :decimal  ],
        [ :height                        , :decimal  ],
        [ :volume                        , :decimal  ],
        [ :cylinder                      , :boolean   , { :default => false }],
        [ :option1                       , :string   ],
        [ :option2                       , :string   ],
        [ :option3                       , :string   ],        
        [ :option1_media_id              , :integer  ],
        [ :option2_media_id              , :integer  ],
        [ :option3_media_id              , :integer  ],
        [ :requires_shipping             , :boolean   , { :default => true  }],
        [ :taxable                       , :boolean   , { :default => true  }],        
        [ :shipping_unit_value           , :numeric  ],
        [ :flat_rate_shipping            , :boolean   , { :default => false }],
        [ :flat_rate_shipping_package_id , :integer  ],
        [ :flat_rate_shipping_method_id  , :integer  ],
        [ :flat_rate_shipping_single     , :decimal   , { :precision => 8, :scale => 2, :default => 0.0 }],
        [ :flat_rate_shipping_combined   , :decimal   , { :precision => 8, :scale => 2, :default => 0.0 }],      
        [ :status                        , :string   ],
        [ :option1_sort_order            , :integer   , { :default => 0 }],
        [ :option2_sort_order            , :integer   , { :default => 0 }],
        [ :option3_sort_order            , :integer   , { :default => 0 }],
        [ :sort_order                    , :integer   , { :default => 0 }],
        [ :downloadable                  , :boolean   , { :default => false }],
        [ :download_path                 , :string   ]
      ],
      Caboose::Vendor => [
        [ :site_id      , :integer    ],
        [ :alternate_id , :string     ],
        [ :name         , :string     ],
        [ :status       , :string     , { :default => 'Active' }],
        [ :featured     , :boolean    , { :default => false    }],
        [ :image        , :attachment ]
      ]
    }

  end

  # Loads initial data into the database
  def self.load_data

    c = ActiveRecord::Base.connection
    #if c.column_exists?(:pages, :content)
    #  Caboose::Page.reorder(:id).all.each do |p|
    #    Caboose::PageBlock.create( :page_id => p.id, :block_type => 'richtext', :value => p.content )
    #  end
    #  c.remove_column(:pages, :content)
    #end
    
    #c.change_column :store_variants, :taxable, :boolean

    super_admin_user = nil
    if !Caboose::User.exists?(:username => 'superadmin')
      super_admin_user = Caboose::User.create(:first_name => 'Super', :last_name => 'Admin', :username => 'superadmin', :email => 'superadmin@nine.is')
      super_admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
      super_admin_user.save
    end
    super_admin_user = Caboose::User.where(:username => 'superadmin').first if super_admin_user.nil?
    
    admin_user = nil
    if !Caboose::User.exists?(:username => 'admin')
      admin_user = Caboose::User.create(:first_name => 'Admin', :last_name => 'User', :username => 'admin', :email => 'william@nine.is')
      admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
      admin_user.save
    end
    admin_user = Caboose::User.where(:username => 'admin').first if admin_user.nil?

    if !Caboose::User.where(:id => Caboose::User::LOGGED_OUT_USER_ID).exists?
      Caboose::User.create(:id => Caboose::User::LOGGED_OUT_USER_ID, :first_name => 'Logged', :last_name => 'Out', :username => 'elo', :email => 'elo@nine.is')
    end

    Caboose::Role.create(:parent_id => -1           , :name => 'Super Admin'         ) if !Caboose::Role.exists?(:name =>  'Super Admin'         )
    super_admin_role = Caboose::Role.where(:name => 'Super Admin'         ).first
    Caboose::Role.create(:parent_id => -1           , :name => 'Admin'               ) if !Caboose::Role.exists?(:name =>  'Admin'               )
    admin_role       = Caboose::Role.where(:name => 'Admin'               ).first
    Caboose::Role.create(:parent_id => -1           , :name => 'Everyone Logged Out' ) if !Caboose::Role.exists?(:name =>  'Everyone Logged Out' )
    elo_role         = Caboose::Role.where(:name => 'Everyone Logged Out' ).first
    Caboose::Role.create(:parent_id => elo_role.id  , :name => 'Everyone Logged In'  ) if !Caboose::Role.exists?(:name =>  'Everyone Logged In'  )
    eli_role         = Caboose::Role.where(:name => 'Everyone Logged In'  ).first

    Caboose::User.create(:first_name => 'John', :last_name => 'Doe', :username => 'elo', :email => 'william@nine.is') if !Caboose::User.exists?(:username => 'elo')
    elo_user = Caboose::User.where(:username => 'elo').first
        
    Caboose::Permission.create(:resource => 'all'         , :action => 'super'  ) if !Caboose::Permission.exists?(:resource => 'all'	       , :action => 'super'  )
    Caboose::Permission.create(:resource => 'all'         , :action => 'all'    ) if !Caboose::Permission.exists?(:resource => 'all'	       , :action => 'all'    )
    Caboose::Permission.create(:resource => 'users'	      , :action => 'view'   ) if !Caboose::Permission.exists?(:resource => 'users'	     , :action => 'view'   )
    Caboose::Permission.create(:resource => 'users'	      , :action => 'edit'   ) if !Caboose::Permission.exists?(:resource => 'users'	     , :action => 'edit'   )
    Caboose::Permission.create(:resource => 'users'	      , :action => 'delete' ) if !Caboose::Permission.exists?(:resource => 'users'	     , :action => 'delete' )
    Caboose::Permission.create(:resource => 'users'	      , :action => 'add'    ) if !Caboose::Permission.exists?(:resource => 'users'	     , :action => 'add'    )
    Caboose::Permission.create(:resource => 'roles'	      , :action => 'view'   ) if !Caboose::Permission.exists?(:resource => 'roles'	     , :action => 'view'   )
    Caboose::Permission.create(:resource => 'roles'	      , :action => 'edit'   ) if !Caboose::Permission.exists?(:resource => 'roles'	     , :action => 'edit'   )
    Caboose::Permission.create(:resource => 'roles'	      , :action => 'delete' ) if !Caboose::Permission.exists?(:resource => 'roles'	     , :action => 'delete' )
    Caboose::Permission.create(:resource => 'roles'	      , :action => 'add'    ) if !Caboose::Permission.exists?(:resource => 'roles'	     , :action => 'add'    )
    Caboose::Permission.create(:resource => 'permissions' , :action => 'view'   ) if !Caboose::Permission.exists?(:resource => 'permissions' , :action => 'view'   )
    Caboose::Permission.create(:resource => 'permissions' , :action => 'edit'   ) if !Caboose::Permission.exists?(:resource => 'permissions' , :action => 'edit'   )
    Caboose::Permission.create(:resource => 'permissions' , :action => 'delete' ) if !Caboose::Permission.exists?(:resource => 'permissions' , :action => 'delete' )
    Caboose::Permission.create(:resource => 'permissions' , :action => 'add'    ) if !Caboose::Permission.exists?(:resource => 'permissions' , :action => 'add'    )
    
    # Add the super admin user to the super admin role
    Caboose::RoleMembership.create(:user_id => super_admin_user.id, :role_id => super_admin_role.id) if !Caboose::RoleMembership.exists?(:user_id => super_admin_user.id, :role_id => super_admin_role.id)

    # Add the admin user to the admin role
    Caboose::RoleMembership.create(:user_id => admin_user.id, :role_id => admin_role.id) if !Caboose::RoleMembership.exists?(:user_id => admin_user.id, :role_id => admin_role.id)

    # Add the elo to the elo role
    Caboose::RoleMembership.create(:user_id => elo_user.id, :role_id => elo_role.id) if !Caboose::RoleMembership.exists?(:user_id => elo_user.id, :role_id => elo_role.id)

    # Add the all/super permission to the super admin role
    super_admin_perm = Caboose::Permission.where(:resource => 'all', :action => 'super').first
    Caboose::RolePermission.create(:role_id => super_admin_role.id, :permission_id => super_admin_perm.id) if !Caboose::RolePermission.exists?(:role_id => super_admin_role.id, :permission_id => super_admin_perm.id)
    
    # Add the all/all permission to the admin role and super admin role
    admin_perm = Caboose::Permission.where(:resource => 'all', :action => 'all').first
    Caboose::RolePermission.create(:role_id => admin_role.id       , :permission_id => admin_perm.id) if !Caboose::RolePermission.exists?(:role_id => admin_role.id       , :permission_id => admin_perm.id)
    Caboose::RolePermission.create(:role_id => super_admin_role.id , :permission_id => admin_perm.id) if !Caboose::RolePermission.exists?(:role_id => super_admin_role.id , :permission_id => admin_perm.id)

    # Create the necessary pages
    Caboose::Page.create(:title => 'Home'  , :parent_id => -1, :hide => 0, :layout => 'home', :uri => '') if !Caboose::Page.exists?(:title => 'Home')
    home_page = Caboose::Page.where(:title => 'Home', :parent_id => -1).first
    Caboose::Page.create(:title => 'Admin' , :parent_id => home_page.id, :hide => 0, :layout => 'admin', :alias => 'admin', :slug => 'admin', :uri => 'admin') if !Caboose::Page.exists?(:alias => 'admin')
    admin_page = Caboose::Page.where(:alias => 'admin').first
    Caboose::Page.create(:title => 'Login' , :parent_id => home_page.id, :hide => 0, :layout => 'login', :alias => 'login', :slug => 'login', :uri => 'login') if !Caboose::Page.exists?(:alias => 'login')
    login_page = Caboose::Page.where(:alias => 'login').first

    Caboose::PagePermission.create(:role_id => elo_role.id, :page_id => home_page.id  , :action => 'view') if !Caboose::PagePermission.exists?(:role_id => elo_role.id, :page_id => home_page.id  , :action => 'view')
    Caboose::PagePermission.create(:role_id => elo_role.id, :page_id => login_page.id , :action => 'view') if !Caboose::PagePermission.exists?(:role_id => elo_role.id, :page_id => login_page.id , :action => 'view')

    # Create a default post category
    Caboose::PostCategory.create(:name => 'General News') if !Caboose::PostCategory.exists?(:name => 'General News')

    # Create the required settings
    Caboose::Setting.create(:name => 'version'     , :value => Caboose::VERSION        ) if !Caboose::Setting.exists?(:name => 'version'     , :value => Caboose::VERSION        )
    Caboose::Setting.create(:name => 'site_name'   , :value => 'New Caboose Site'      ) if !Caboose::Setting.exists?(:name => 'site_name'   , :value => 'New Caboose Site'      )
    Caboose::Setting.create(:name => 'site_url'    , :value => 'www.mycaboosesite.com' ) if !Caboose::Setting.exists?(:name => 'site_url'    , :value => 'www.mycaboosesite.com' )
    Caboose::Setting.create(:name => 'admin_email' , :value => 'william@nine.is'       ) if !Caboose::Setting.exists?(:name => 'admin_email' , :value => 'william@nine.is'       )

    # Create default block type categories
    btc = Caboose::BlockTypeCategory
    layouts = btc.exists?(:name => 'Layouts') ? btc.where(:name => 'Layouts').first : btc.create(:name => 'Layouts')
    content = btc.exists?(:name => 'Content') ? btc.where(:name => 'Content').first : btc.create(:name => 'Content')
    btc.create(:name => 'Rows', :parent_id => content.id) if !btc.where(:name => 'Rows', :parent_id => content.id).exists?

    # Create default block types
    if !Caboose::BlockType.where(:name => 'layout_basic').exists?
      bt = Caboose::BlockType.create(:name => 'layout_basic', :description => 'Basic', :block_type_category_id => layouts.id, :use_render_function_for_layout => true, :allow_child_blocks => false, :field_type => 'block')
      Caboose::BlockType.create(:name => 'header'  , :description => 'Header'  , :parent_id => bt.id, :field_type => 'block')
      Caboose::BlockType.create(:name => 'content' , :description => 'Content' , :parent_id => bt.id, :field_type => 'block', :allow_child_blocks => true)
      Caboose::BlockType.create(:name => 'footer'  , :description => 'Footer'  , :parent_id => bt.id, :field_type => 'block')
    end

    if !Caboose::BlockType.where(:name => 'layout_left_sidebar').exists?
      bt = Caboose::BlockType.create(:name => 'layout_left_sidebar', :description => 'Left Sidebar', :block_type_category_id => layouts.id, :use_render_function_for_layout => true, :allow_child_blocks => false, :field_type => 'block')
      Caboose::BlockType.create(:name => 'header'  , :description => 'Header'  , :parent_id => bt.id, :field_type => 'block')
      Caboose::BlockType.create(:name => 'sidebar' , :description => 'Sidebar' , :parent_id => bt.id, :field_type => 'block', :allow_child_blocks => true)
      Caboose::BlockType.create(:name => 'content' , :description => 'Content' , :parent_id => bt.id, :field_type => 'block', :allow_child_blocks => true)
      Caboose::BlockType.create(:name => 'footer'  , :description => 'Footer'  , :parent_id => bt.id, :field_type => 'block')
    end

    if !Caboose::BlockType.where(:name => 'layout_right_sidebar').exists?
      bt = Caboose::BlockType.create(:name => 'layout_right_sidebar', :description => 'Right Sidebar', :block_type_category_id => layouts.id, :use_render_function_for_layout => true, :allow_child_blocks => false, :field_type => 'block')
      Caboose::BlockType.create(:name => 'header'  , :description => 'Header'  , :parent_id => bt.id, :field_type => 'block')
      Caboose::BlockType.create(:name => 'sidebar' , :description => 'Sidebar' , :parent_id => bt.id, :field_type => 'block', :allow_child_blocks => true)
      Caboose::BlockType.create(:name => 'content' , :description => 'Content' , :parent_id => bt.id, :field_type => 'block', :allow_child_blocks => true)
      Caboose::BlockType.create(:name => 'footer'  , :description => 'Footer'  , :parent_id => bt.id, :field_type => 'block')
    end

    if !Caboose::BlockType.where(:name => 'heading').exists?
      bt = Caboose::BlockType.create(:name => 'heading', :description => 'Heading', :field_type => 'block')
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'text', :description => 'Text', :field_type => 'text', :default => '', :width => 800, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'size', :description => 'Size', :field_type => 'text', :default =>  1, :width => 800, :fixed_placeholder => false, :options => "1|2|3|4|5|6")
    end

    if !Caboose::BlockType.where(:name => 'text').exists?
      Caboose::BlockType.create(:name => 'text', :description => 'Text', :field_type => 'text', :default => '', :width => 800, :height => 400, :fixed_placeholder => false)
    end
    if !Caboose::BlockType.where(:name => 'richtext').exists?
      Caboose::BlockType.create(:name => 'richtext', :description => 'Rich Text', :field_type => 'richtext', :default => '', :width => 800, :height => 400, :fixed_placeholder => false)
    else
      bt = Caboose::BlockType.where(:name => 'richtext').first
      bt.field_type = 'richtext'
      bt.save
    end
    if !Caboose::BlockType.where(:name => 'richtext2').exists?
      Caboose::BlockType.create(:name => 'richtext2', :description => 'Rich Text (Non-Parsed)', :field_type => 'richtext', :default => '', :width => 800, :height => 400, :fixed_placeholder => false)    
    end
    if !Caboose::BlockType.where(:name => 'image').exists?
      bt = Caboose::BlockType.create(:name => 'image', :description => 'Image', :field_type => 'block')
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'image_src'     , :description => 'Image'         , :field_type => 'image'  , :default => ''      , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'image_style'   , :description => 'Style'         , :field_type => 'select' , :default => 'Thumb' , :width => 400, :fixed_placeholder => false, :options => "Tiny\nThumb\nLarge")
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'link'          , :description => 'Link'          , :field_type => 'text'   , :default => ''      , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'width'         , :description => 'Width'         , :field_type => 'text'   , :default => ''      , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'height'        , :description => 'Height'        , :field_type => 'text'   , :default => ''      , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'margin_top'    , :description => 'Top Margin'    , :field_type => 'text'   , :default => '10'    , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'margin_right'  , :description => 'Right Margin'  , :field_type => 'text'   , :default => '10'    , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'margin_bottom' , :description => 'Bottom Margin' , :field_type => 'text'   , :default => '10'    , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'margin_left'   , :description => 'Left Margin'   , :field_type => 'text'   , :default => '10'    , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'align'         , :description => 'Align'         , :field_type => 'select' , :default => 'None'  , :width => 400, :fixed_placeholder => false, :options => "None\nCenter\nLeft\nRight")
    end
    if !Caboose::BlockType.where(:name => 'file').exists?
      bt = Caboose::BlockType.create(:name => 'file', :description => 'File', :field_type => 'block')
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'file' , :description => 'File' , :field_type => 'file', :default => ''         , :width => 400, :fixed_placeholder => false)
      Caboose::BlockType.create(:parent_id => bt.id, :name => 'text' , :description => 'Text' , :field_type => 'text', :default => 'Download' , :width => 400, :fixed_placeholder => false)
    end
    
    # Make sure a top-level media category for each site exists
    Caboose::Site.all.each do |site|
      cat = Caboose::MediaCategory.where(:site_id => site.id, :parent_id => nil, :name => 'Media').first
      Caboose::MediaCategory.create(:site_id => site.id, :parent_id => nil, :name => 'Media') if cat.nil?      
    end
    
    # Make sure a default category exists for all products
    if !Caboose::Category.exists?(1)
      Caboose::Category.create({
        :id   => 1,
        :name => 'All Products',
        :url  => '/products',
        :slug => 'products'
      })
    end
    
    if Caboose::ShippingMethod.all.count == 0
      Caboose::ShippingMethodLoader.load_shipping_methods
    end
  end
end
