
class Caboose::Schema < Caboose::Utilities::Schema

  # Tables (in order) that were renamed in the development of the gem.
  def self.renamed_tables
    {
      :roles_users             => :role_memberships,
      :permissions_roles       => :role_permissions,
      :page_block_field_values => :fields,
      :page_block_fields       => :field_types,
      :page_block_types        => :block_types,
      :page_blocks             => :blocks
    }
  end

  def self.renamed_columns
    {
      #Caboose::Field     => { :page_block_id        => :block_id,
      #                        :page_block_field_id  => :field_type_id },
      #Caboose::FieldType => { :page_block_type_id   => :block_type_id },
      Caboose::Block     => { :page_block_type_id   => :block_type_id }
    }
  end

  def self.removed_columns
    {
      Caboose::Block => [:block_type],
      #Caboose::FieldType => [:model_binder_options],
      Caboose::AbValue => [:i, :text],
      Caboose::AbOption => [:text],
      Caboose::User => [:timezone],
      #Caboose::Field => [:child_block_id],
      Caboose::BlockType => [:layout_function]
    }
  end

  # Any column indexes that need to exist in the database
  def self.indexes
    {
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
        [ :page_id               , :integer ],
        [ :parent_id             , :integer ],
        [ :block_type_id         , :integer ],
        [ :sort_order            , :integer , { :default => 0 }],
        [ :name                  , :string  ],
        [ :value                 , :text    ],
        [ :file                  , :attachment ],
        [ :image                 , :attachment ]
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
        [ :share                           , :boolean , { :default => true  }],
        [ :downloaded                      , :boolean , { :default => false }]
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
      Caboose::DatabaseSession => [
        [ :session_id  , :string   , :null => false ],
        [ :data        , :text                      ],
        [ :created_at  , :datetime , :null => true  ],
        [ :updated_at  , :datetime , :null => true  ]
      ],
      Caboose::Domain => [
        [ :site_id     , :integer ],
        [ :domain      , :string  ],
        [ :primary     , :boolean, { :default => false }]
      ],
      Caboose::MediaCategory => [
        [ :parent_id         , :integer ],
        [ :site_id           , :integer ],
        [ :name              , :string  ]        
      ],
      Caboose::MediaImage => [
        [ :media_category_id , :integer ],
        [ :name              , :string  ],
        [ :description       , :text    ]
      ],
      Caboose::MediaFile => [
        [ :media_category_id , :integer ],
        [ :name              , :string  ],
        [ :description       , :text    ]
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
      Caboose::PagePermission => [
        [ :role_id , :integer  ],
        [ :page_id , :integer  ],
        [ :action  , :string   ]
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
        [ :title                , :text       ],
        [ :body                 , :text 		   ],
        [ :hide                 , :boolean    ],
        [ :image_url            , :text 		   ],
        [ :published            , :boolean    ],
        [ :created_at           , :datetime   ],
        [ :updated_at           , :datetime   ],
        [ :image                , :attachment ]
      ],
      Caboose::PostCategory => [
        [ :name , :string ]
      ],
      Caboose::PostCategoryMembership => [
        [ :post_id          , :integer ],
        [ :post_category_id , :integer ]
      ],
      Caboose::Role => [
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
      Caboose::Setting => [
        [ :name  , :string ],
        [ :value , :text   ]
      ],
      Caboose::Site => [
        [ :name        , :string ],
        [ :description , :text   ]
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
        [ :enable_starttls_auto , :boolean , { :default => true }]
      ],
      Caboose::Timezone => [
        [ :country_code , :string ],
        [ :name         , :string ]
      ],
      Caboose::TimezoneAbbreviation => [
        [ :abbreviation , :string  ],
        [ :name         , :string  ]
      ],
      Caboose::TimezoneOffset => [
        [ :timezone_id  , :integer  ],
        [ :abbreviation , :string   ],
        [ :time_start   , :integer  ],
        [ :gmt_offset   , :integer  ],
        [ :dst          , :boolean  ]
      ],
      Caboose::User => [
        [ :first_name           , :string     ],
        [ :last_name            , :string     ],
        [ :username             , :string     ],
        [ :email                , :string     ],
        [ :address              , :string     ],
        [ :address2             , :string     ],
        [ :city                 , :string     ],
        [ :state                , :string     ],
        [ :zip                  , :string     ],
        [ :phone                , :string     ],
        [ :fax                  , :string     ],
        [ :utc_offset           , :float      , { :default => -5 }],
        #[ :timezone             , :string     , { :default => 'America/Chicago' }],
        [ :timezone_id          , :integer    , { :defualt => 381 }], # Defaults to 'America/Chicago'
        [ :password             , :string     ],
        [ :password_reset_id    , :string     ],
        [ :password_reset_sent  , :datetime   ],
        [ :token                , :string     ],
        [ :date_created         , :datetime   ],
        [ :image                , :attachment ]
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

    Caboose::Role.create(:parent_id => -1           , :name => 'Admin'               ) if !Caboose::Role.exists?(:name =>  'Admin'               )
    admin_role  = Caboose::Role.where(:name => 'Admin'               ).first
    Caboose::Role.create(:parent_id => -1           , :name => 'Everyone Logged Out' ) if !Caboose::Role.exists?(:name =>  'Everyone Logged Out' )
    elo_role    = Caboose::Role.where(:name => 'Everyone Logged Out' ).first
    Caboose::Role.create(:parent_id => elo_role.id  , :name => 'Everyone Logged In'  ) if !Caboose::Role.exists?(:name =>  'Everyone Logged In'  )
    eli_role    = Caboose::Role.where(:name => 'Everyone Logged In'  ).first

    Caboose::User.create(:first_name => 'John', :last_name => 'Doe', :username => 'elo', :email => 'william@nine.is') if !Caboose::User.exists?(:username => 'elo')
    elo_user = Caboose::User.where(:username => 'elo').first

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

    # Add the admin user to the admin role
    Caboose::RoleMembership.create(:user_id => admin_user.id, :role_id => admin_role.id) if !Caboose::RoleMembership.exists?(:user_id => admin_user.id, :role_id => admin_role.id)

    # Add the elo to the elo role
    Caboose::RoleMembership.create(:user_id => elo_user.id, :role_id => elo_role.id) if !Caboose::RoleMembership.exists?(:user_id => elo_user.id, :role_id => elo_role.id)

    # Add the all/all permission to the admin role
    admin_perm = Caboose::Permission.where(:resource => 'all', :action => 'all').first
    Caboose::RolePermission.create(:role_id => admin_role.id, :permission_id => admin_perm.id) if !Caboose::RolePermission.exists?(:role_id => admin_role.id, :permission_id => admin_perm.id)

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
      cat = Caboose::MediaCategory.where("parent_id is null and site_id = ? and name = ?", site.id, 'Images').first
      Caboose::MediaCategory.create(:site_id => site.id, :name => 'Images') if cat.nil?
      cat = Caboose::MediaCategory.where("parent_id is null and site_id = ? and name = ?", site.id, 'Files').first
      Caboose::MediaCategory.create(:site_id => site.id, :name => 'Files') if cat.nil?
    end

  end
end
