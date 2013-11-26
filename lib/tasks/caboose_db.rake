require "caboose/version"
require "caboose/migrations"

namespace :caboose do

  desc "Creates/verifies that all database tables and fields are correctly added."
  task :db => :environment do
    create_tables
    load_data
  end
  
  desc "Drops all caboose tables"
  task :drop_tables => :environment do drop_tables end

  desc "Creates all caboose tables"
  task :create_tables => :environment do create_tables end

  desc "Loads data into caboose tables"
  task :load_data => :environment do load_data end
  
  #=============================================================================
  
  def drop_tables            
    puts "Dropping any existing caboose tables..."
    c = ActiveRecord::Base.connection  
    c.drop_table :users                if c.table_exists?('users')
    c.drop_table :roles                if c.table_exists?('roles')
    c.drop_table :permissions          if c.table_exists?('permissions')
    c.drop_table :roles_users          if c.table_exists?('roles_users')
    c.drop_table :permissions_roles    if c.table_exists?('permissions_roles')
    c.drop_table :assets               if c.table_exists?('assets')
    c.drop_table :pages                if c.table_exists?('pages')
    c.drop_table :posts                if c.table_exists?('posts')
    c.drop_table :page_permissions     if c.table_exists?('page_permissions')
    c.drop_table :sessions             if c.table_exists?('sessions')
    c.drop_table :settings             if c.table_exists?('settings')
  end

  def create_tables  
    puts "Creating required caboose tables..."
    
    c = ActiveRecord::Base.connection
    
    # Users     
  	c.create_table :users if !c.table_exists?(:users)  	
    c.add_column   :users, :first_name             , :string     if !c.column_exists?(:users, :first_name          )     
    c.add_column   :users, :last_name              , :string     if !c.column_exists?(:users, :last_name           ) 
    c.add_column   :users, :username               , :string     if !c.column_exists?(:users, :username            ) 
    c.add_column   :users, :email                  , :string     if !c.column_exists?(:users, :email               ) 
    c.add_column   :users, :phone                  , :string     if !c.column_exists?(:users, :phone               ) 
    c.add_column   :users, :password               , :string     if !c.column_exists?(:users, :password            ) 
    c.add_column   :users, :password_reset_id      , :string     if !c.column_exists?(:users, :password_reset_id   ) 
    c.add_column   :users, :password_reset_sent    , :datetime   if !c.column_exists?(:users, :password_reset_sent ) 
    c.add_column   :users, :token                  , :string     if !c.column_exists?(:users, :token               ) 
    c.add_column   :users, :date_created           , :datetime   if !c.column_exists?(:users, :date_created        ) 
    
    # Roles
    c.create_table :roles if !c.table_exists?(:roles)
    c.add_column   :roles, :parent_id    , :integer  if !c.column_exists?(:roles, :parent_id   ) 
    c.add_column   :roles, :name         , :string   if !c.column_exists?(:roles, :name        )
    c.add_column   :roles, :description  , :string   if !c.column_exists?(:roles, :description )
    
    # Permissions
    c.create_table :permissions if !c.table_exists?(:permissions)
    c.add_column   :permissions, :resource , :string if !c.column_exists?(:permissions, :resource ) 
    c.add_column   :permissions, :action   , :string if !c.column_exists?(:permissions, :action   )     
    
    # Role membership
    c.rename_table :roles_users, :role_memberships if c.table_exists?(:roles_users)
    c.create_table :role_memberships if !c.table_exists?(:role_memberships)
    c.add_column   :role_memberships, :role_id, :integer if !c.column_exists?(:role_memberships, :role_id)
    c.add_column   :role_memberships, :user_id, :integer if !c.column_exists?(:role_memberships, :user_id)    
    c.add_index    :role_memberships, :role_id           if !c.index_exists?( :role_memberships, :role_id)
    c.add_index    :role_memberships, :user_id           if !c.index_exists?( :role_memberships, :user_id)
    
    # Role permissions    
    c.rename_table :permissions_roles, :role_permissions if c.table_exists?(:permissions_roles)
    c.create_table :role_permissions if !c.table_exists?(:role_permissions)
		c.add_column   :role_permissions, :role_id        , :integer if !c.column_exists?(:role_permissions, :role_id       )
		c.add_column   :role_permissions, :permission_id  , :integer if !c.column_exists?(:role_permissions, :permission_id )		
		c.add_index    :role_permissions, :role_id                   if !c.index_exists?( :role_permissions, :role_id       )
		c.add_index    :role_permissions, :permission_id             if !c.index_exists?( :role_permissions, :permission_id )
    
    # Assets
    c.create_table :assets if !c.table_exists?(:assets)
    c.add_column   :assets, :page_id        , :integer    if !c.column_exists?(:assets, :page_id       )  
    c.add_column   :assets, :user_id        , :integer    if !c.column_exists?(:assets, :user_id       ) 
    c.add_column   :assets, :date_uploaded  , :datetime   if !c.column_exists?(:assets, :date_uploaded ) 
    c.add_column   :assets, :name           , :string     if !c.column_exists?(:assets, :name          ) 
    c.add_column   :assets, :filename       , :string     if !c.column_exists?(:assets, :filename      ) 
    c.add_column   :assets, :description    , :string     if !c.column_exists?(:assets, :description   ) 
    c.add_column   :assets, :extension      , :string     if !c.column_exists?(:assets, :extension     ) 
    
    # Pages
    c.create_table :pages if !c.table_exists?(:pages)
    c.add_column   :pages, :parent_id             , :integer                                                    if !c.column_exists?(:pages, :parent_id            ) 
    c.add_column   :pages, :title                 , :string                                                     if !c.column_exists?(:pages, :title                )
    c.add_column   :pages, :menu_title            , :string                                                     if !c.column_exists?(:pages, :menu_title           )
    c.add_column   :pages, :content               , :text                                                       if !c.column_exists?(:pages, :content              )
    c.add_column   :pages, :slug                  , :string                                                     if !c.column_exists?(:pages, :slug                 )
    c.add_column   :pages, :alias                 , :string                                                     if !c.column_exists?(:pages, :alias                )
    c.add_column   :pages, :uri                   , :string                                                     if !c.column_exists?(:pages, :uri                  )
    c.add_column   :pages, :redirect_url          , :string                                                     if !c.column_exists?(:pages, :redirect_url         )
    c.add_column   :pages, :hide                  , :boolean , :default => false                                if !c.column_exists?(:pages, :hide                 )
    c.add_column   :pages, :content_format        , :integer , :default => Caboose::Page::CONTENT_FORMAT_HTML   if !c.column_exists?(:pages, :content_format       )
    c.add_column   :pages, :custom_css            , :text                                                       if !c.column_exists?(:pages, :custom_css           )
    c.add_column   :pages, :custom_js             , :text                                                       if !c.column_exists?(:pages, :custom_js            )
    c.add_column   :pages, :linked_resources      , :text                                                       if !c.column_exists?(:pages, :linked_resources     )
    c.add_column   :pages, :layout                , :string                                                     if !c.column_exists?(:pages, :layout               )
    c.add_column   :pages, :sort_order            , :integer , :default => 0                                    if !c.column_exists?(:pages, :sort_order           )
    c.add_column   :pages, :custom_sort_children  , :boolean , :default => false                                if !c.column_exists?(:pages, :custom_sort_children )
    c.add_column   :pages, :seo_title             , :string  , :limit => 70                                     if !c.column_exists?(:pages, :seo_title            )
    c.add_column   :pages, :meta_description      , :string  , :limit => 156                                    if !c.column_exists?(:pages, :meta_description     )
    c.add_column   :pages, :meta_robots           , :string  , :default => 'index, follow'                      if !c.column_exists?(:pages, :meta_robots          )
    c.add_column   :pages, :canonical_url         , :string                                                     if !c.column_exists?(:pages, :canonical_url        )
    c.add_column   :pages, :fb_description        , :string  , :limit => 156                                    if !c.column_exists?(:pages, :fb_description       )
    c.add_column   :pages, :gp_description        , :string  , :limit => 156                                    if !c.column_exists?(:pages, :gp_description       )
    
    # Posts
    c.create_table :posts if !c.table_exists?(:posts)
    c.add_column   :posts, :title       , :text     if !c.column_exists?(:posts, :title      )  		 	 
    c.add_column   :posts, :body        , :text 		if !c.column_exists?(:posts, :body       )  	 
    c.add_column   :posts, :hide        , :boolean  if !c.column_exists?(:posts, :hide       ) 	 
    c.add_column   :posts, :image_url   , :text 		if !c.column_exists?(:posts, :image_url  )
    c.add_column   :posts, :created_at  , :datetime if !c.column_exists?(:posts, :created_at )
    c.add_column   :posts, :updated_at  , :datetime if !c.column_exists?(:posts, :updated_at )
    
    # Post categories
    c.create_table :post_categories if !c.table_exists?(:post_categories)
    c.add_column   :post_categories, :name , :string if !c.column_exists?(:post_categories, :name)
    
    # Post category membership
    c.create_table :post_category_memberships if !c.table_exists?(:post_category_memberships)
    c.add_column   :post_category_memberships, :post_id          , :integer if !c.column_exists?(:post_category_memberships, :post_id          )
    c.add_column   :post_category_memberships, :post_category_id , :integer if !c.column_exists?(:post_category_memberships, :post_category_id )    
    c.add_index    :post_category_memberships, :post_id                     if !c.index_exists?( :post_category_memberships, :post_id          )
    c.add_index    :post_category_memberships, :post_category_id            if !c.index_exists?( :post_category_memberships, :post_category_id )

    # Page permissions
    c.create_table :page_permissions if !c.table_exists?(:page_permissions)
    c.add_column   :page_permissions, :role_id , :integer  if !c.column_exists?(:page_permissions, :role_id )  
    c.add_column   :page_permissions, :page_id , :integer  if !c.column_exists?(:page_permissions, :page_id )
    c.add_column   :page_permissions, :action  , :string   if !c.column_exists?(:page_permissions, :action  )   
    
    # Sessions
    c.create_table :sessions if !c.table_exists?(:sessions)
    c.add_column   :sessions, :session_id  , :string   , :null => false if !c.column_exists?(:sessions, :session_id )
    c.add_column   :sessions, :data        , :text                      if !c.column_exists?(:sessions, :data       )
    c.add_column   :sessions, :created_at  , :datetime , :null => true  if !c.column_exists?(:sessions, :created_at )
    c.add_column   :sessions, :updated_at  , :datetime , :null => true  if !c.column_exists?(:sessions, :updated_at )    
    c.add_index    :sessions, :session_id                               if !c.index_exists?( :sessions, :session_id )
    c.add_index    :sessions, :updated_at                               if !c.index_exists?( :sessions, :updated_at )
    
    # Settings
    c.create_table :settings if !c.table_exists?(:settings)
    c.add_column   :settings, :name  , :string if !c.column_exists?(:settings, :name  )
    c.add_column   :settings, :value , :text   if !c.column_exists?(:settings, :value )    
		
  end
  
  def load_data
    puts "Loading data into caboose tables..."
    
    admin_user = nil
    if !Caboose::User.exists?(:username => 'admin')
      admin_user = Caboose::User.create(:first_name => 'Admin', :last_name => 'User', :username => 'admin', :email => 'william@nine.is')
      admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
      admin_user.save
    end
    admin_user = Caboose::User.where(:username => 'admin').first if admin_user.nil?
    
    Caboose::Role.create(:parent_id => -1           , :name => 'Admin'               ) if !Caboose::Role.exists?(:name =>  'Admin'               ) 
    Caboose::Role.create(:parent_id => -1           , :name => 'Everyone Logged Out' ) if !Caboose::Role.exists?(:name =>  'Everyone Logged Out' ) 
    Caboose::Role.create(:parent_id => elo_role.id  , :name => 'Everyone Logged In'  ) if !Caboose::Role.exists?(:name =>  'Everyone Logged In'  ) 
    
    admin_role  = Caboose::Role.where(:name => 'Admin'               ).first
    elo_role    = Caboose::Role.where(:name => 'Everyone Logged Out' ).first
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
