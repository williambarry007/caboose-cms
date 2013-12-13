
class Caboose::Schema < Caboose::Utilities::Schema
    
  # Tables (in order) that were renamed in the development of the gem.
  def self.renamed_tables
    {
      :roles_users       => :role_memberships,
      :permissions_roles => :role_permissions
    }
  end
  
  # Any column indexes that need to exist in the database
  def self.indexes
    {    
      :role_memberships          => [ :role_id    , :user_id          ],
      :role_permissions          => [ :role_id    , :permission_id    ],
      :post_category_memberships => [ :post_id    , :post_category_id ],
      :sessions                  => [ :session_id , :updated_at       ]
    }
  end      
  
  # The schema of the database
  # { Model => [[name, data_type, options]] }
  def self.schema      
    {
      Caboose::User => [  	
        [ :first_name           , :string     ],     
        [ :last_name            , :string     ], 
        [ :username             , :string     ], 
        [ :email                , :string     ], 
        [ :phone                , :string     ], 
        [ :password             , :string     ], 
        [ :password_reset_id    , :string     ], 
        [ :password_reset_sent  , :datetime   ], 
        [ :token                , :string     ], 
        [ :date_created         , :datetime   ]
      ],
      Caboose::Role => [    
        [ :parent_id            , :integer  ], 
        [ :name                 , :string   ],
        [ :description          , :string   ]
      ],
      Caboose::Permission => [    
        [ :resource , :string ], 
        [ :action   , :string ]
      ],
      Caboose::RoleMembership => [    
        [ :role_id, :integer ],
        [ :user_id, :integer ]
      ],
      Caboose::RolePermission => [
	    	[ :role_id        , :integer ],
	    	[ :permission_id  , :integer ]		
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
      Caboose::Page => [        
        [ :parent_id             , :integer ], 
        [ :title                 , :string  ],
        [ :menu_title            , :string  ],
        [ :content               , :text    ],
        [ :slug                  , :string  ],
        [ :alias                 , :string  ],
        [ :uri                   , :string  ],
        [ :redirect_url          , :string  ],
        [ :hide                  , :boolean , :default => false ],
        [ :content_format        , :integer , :default => Caboose::Page::CONTENT_FORMAT_HTML ],
        [ :custom_css            , :text    ],
        [ :custom_js             , :text    ],
        [ :linked_resources      , :text    ],
        [ :layout                , :string  ],
        [ :sort_order            , :integer , :default => 0                ],
        [ :custom_sort_children  , :boolean , :default => false            ],
        [ :seo_title             , :string  , :limit => 70                 ],
        [ :meta_description      , :string  , :limit => 156                ],
        [ :meta_robots           , :string  , :default => 'index, follow'  ],
        [ :canonical_url         , :string  ],
        [ :fb_description        , :string  , :limit => 156 ],
        [ :gp_description        , :string  , :limit => 156 ]
      ],
      Caboose::PageBlock => [        
        [ :page_id               , :integer ], 
        [ :block_type            , :string  , :default => 'p' ],
        [ :sort_order            , :integer , :default => 0   ],
        [ :name                  , :string  ],
        [ :value                 , :text    ]        
      ],      
      Caboose::Post => [  
        [ :title       , :text     ],  		 	 
        [ :body        , :text 		 ],  	 
        [ :hide        , :boolean  ], 	 
        [ :image_url   , :text 		 ],
        [ :created_at  , :datetime ],
        [ :updated_at  , :datetime ]
      ],
      Caboose::PostCategory => [
        [ :name , :string ]
      ],    
      Caboose::PostCategoryMembership => [    
        [ :post_id          , :integer ],
        [ :post_category_id , :integer ]
      ],    
      Caboose::PagePermission => [
        [ :role_id , :integer  ],  
        [ :page_id , :integer  ],
        [ :action  , :string   ]
      ],
      Caboose::DatabaseSession => [
        [ :session_id  , :string   , :null => false ],
        [ :data        , :text                      ],
        [ :created_at  , :datetime , :null => true  ],
        [ :updated_at  , :datetime , :null => true  ]
      ],    
      Caboose::Setting => [    
        [ :name  , :string ],
        [ :value , :text   ]
      ]
    }

  end
  
  # Loads initial data into the database
  def self.load_data

    c = ActiveRecord::Base.connection    
    if c.column_exists?(:pages, :content)
      Caboose::Page.reorder(:id).all.each do |p|
        Caboose::PageBlock.create( :page_id => p.id, :block_type => 'richtext', :value => p.content )        
      end      
      c.remove_column(:pages, :content)
    end
    
    admin_user = nil
    if !Caboose::User.exists?(:username => 'admin')
      admin_user = Caboose::User.create(:first_name => 'Admin', :last_name => 'User', :username => 'admin', :email => 'william@nine.is')
      admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
      admin_user.save
    end
    admin_user = Caboose::User.where(:username => 'admin').first if admin_user.nil?
    
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
    
  end
end
