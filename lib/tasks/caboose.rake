require "caboose/version"
require "caboose/migrations"

namespace :caboose do

  desc "Initializes the database for a caboose installation"
  task :db => :environment do
    drop_tables
    create_tables
    load_data
  end

  desc "Drops all caboose tables"
  task :drop_tables => :environment do drop_tables end

  desc "Creates all caboose tables"
  task :create_tables => :environment do create_tables end

  desc "Loads data into caboose tables"
  task :load_data => :environment do load_data end

  desc "Resets the admin password to 'caboose'"
  task :reset_admin_pass => :environment do reset_admin_pass end

  desc "Performs caboose migrations to transition from the first to the second version. (Unsafe.)"
  task :migrate_between, [:from_version, :to_version] => :environment do |t, args|
    args.with_defaults(from_version: nil, to_version: nil)
    migrate_tables(args[:from_version], args[:to_version])
  end
  
  desc "Performs caboose migrations to transition from the current version to the given version"
  task :migrate_to, [:to_version] => :migrate_between
  
  desc "Performs caboose migrations to transition from the current version to the latest installed version"
  task :migrate => :migrate_between

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
    
    # User/Role/Permissions    
  	c.create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :username
      t.string :email
      t.string :password
      t.string :password_reset_id
      t.datetime :password_reset_sent
      t.string :token     
    end
    c.create_table :roles do |t|
      t.integer :parent_id
      t.string :name
      t.string :description
    end
    c.create_table :permissions do |t|
      t.string :resource
      t.string :action
    end
    
    # Role membership
    c.create_table :roles_users do |t|
      t.references :role
      t.references :user
    end
    c.add_index :roles_users, :role_id
    c.add_index :roles_users, :user_id
    
    # Role permissions    
    c.create_table :permissions_roles do |t|
			t.references :role
			t.references :permission
		end
		c.add_index :permissions_roles, :role_id
		c.add_index :permissions_roles, :permission_id
    
    # Pages and Assets
    c.create_table :assets do |t|
      t.references  :page
      t.references  :user
      t.datetime    :date_uploaded
      t.string      :name
      t.string      :filename
      t.string      :description
      t.string      :extension      
    end
    c.create_table :pages do |t|
      t.integer :parent_id
      t.string  :title
      t.string  :menu_title
      t.text    :content
      t.string  :slug
      t.string  :alias
      t.string  :uri
      t.string  :redirect_url
      t.boolean :hide, :default => false
      t.integer :content_format, :default => Caboose::Page::CONTENT_FORMAT_HTML
      t.text    :custom_css
      t.text    :custom_js
      t.text    :linked_resources
      t.string  :layout
      t.integer :sort_order, :default => 0
      t.boolean :custom_sort_children, :default => false
      t.string  :seo_title, :limit => 70
      t.string  :meta_description, :limit => 156
      t.string  :meta_robots, :default => 'index, follow' # Multi-select options: none, noindex, nofollow, nosnippet, noodp, noarchive
      t.string  :canonical_url
      t.string  :fb_description, :limit => 156
      t.string  :gp_description, :limit => 156
    end
    c.create_table :posts do |t|
	  	t.text 		 	 :title
	  	t.text 		 	 :body
	  	t.boolean  	 :hide
	  	t.text 		 	 :image_url 
	  	t.timestamps
	  end
    c.create_table :page_permissions do |t|
      t.references  :role
      t.references  :page
      t.string      :action
    end
    c.create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
    c.add_index :sessions, :session_id
    c.add_index :sessions, :updated_at
    c.change_column :sessions, :created_at, :datetime, :null => true
    c.change_column :sessions, :updated_at, :datetime, :null => true
    c.create_table :settings do |t|
      t.string    :name
      t.text      :value
    end
		
  end
  
  def load_data
    puts "Loading data into caboose tables..."
    
    admin_user = Caboose::User.create(first_name: 'Admin', last_name: 'User', username: 'admin', email: 'william@nine.is')
    admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
    admin_user.save
    
    admin_role  = Caboose::Role.create(parent_id: -1, name: 'Admin')
    elo_role    = Caboose::Role.create(parent_id: -1, name: 'Everyone Logged Out')
    eli_role    = Caboose::Role.create(parent_id: elo_role.id, name: 'Everyone Logged In')
    
    elo_user = Caboose::User.create(first_name: 'John', last_name: 'Doe', username: 'elo', email: 'william@nine.is')
    
    admin_perm = Caboose::Permission.create(resource: 'all', action: 'all')
    Caboose::Permission.create(resource: 'users'	     , action: 'view')
    Caboose::Permission.create(resource: 'users'	     , action: 'edit')
    Caboose::Permission.create(resource: 'users'	     , action: 'delete')
    Caboose::Permission.create(resource: 'users'	     , action: 'add')
    Caboose::Permission.create(resource: 'roles'	     , action: 'view')
    Caboose::Permission.create(resource: 'roles'	     , action: 'edit')
    Caboose::Permission.create(resource: 'roles'	     , action: 'delete')
    Caboose::Permission.create(resource: 'roles'	     , action: 'add')
    Caboose::Permission.create(resource: 'permissions' , action: 'view')
    Caboose::Permission.create(resource: 'permissions' , action: 'edit')
    Caboose::Permission.create(resource: 'permissions' , action: 'delete')
    Caboose::Permission.create(resource: 'permissions' , action: 'add')

    # Add the admin user to the admin role
    admin_user.roles.push(admin_role)
    admin_user.save
    
    # Add the elo to the elo role
    elo_user.roles.push(elo_role)
    elo_user.save

    # Add the all/all permission to the admin role
    admin_role.permissions.push(admin_perm)
    admin_role.save
    
    # Create the home page
    home_page  = Caboose::Page.create(title: 'Home'  , parent_id: -1, hide: 0, layout: 'home'   , uri: '')
    admin_page = Caboose::Page.create(title: 'Admin' , parent_id: home_page.id, hide: 0, layout: 'admin', alias: 'admin', slug: 'admin', uri: 'admin')
    login_page = Caboose::Page.create(title: 'Login' , parent_id: home_page.id, hide: 0, layout: 'login', alias: 'login', slug: 'login', uri: 'login')
    Caboose::PagePermission.create(role_id: elo_role.id, page_id: home_page.id, action: 'view') 
    Caboose::PagePermission.create(role_id: elo_role.id, page_id: login_page.id, action: 'view')
    
    # Create the required settings
    Caboose::Setting.create(name: 'version'     , value: Caboose::VERSION)
    Caboose::Setting.create(name: 'site_name'   , value: 'New Caboose Site')
    Caboose::Setting.create(name: 'site_url'    , value: 'www.mycaboosesite.com')
    Caboose::Setting.create(name: 'admin_email' , value: 'william@nine.is')
    
  end
  
  def reset_admin_pass
    admin_user = Caboose::User.where(username: 'admin').first
    admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
    admin_user.save
  end

  def migrate_tables(from_version, to_version)
    version_setting = Caboose::Setting.where(name: 'version').first
    versions = Caboose::VERSIONS
  
    from_version = version_setting.value if from_version.nil?
    to_version = Caboose::VERSION if to_version.nil?
    version_regex = /[0-9]+(\.[0-9]+)*/
  
    raise "from_version '#{from_version}' was invalid" if not version_regex.match(from_version)
    raise "to_version '#{to_version}' was invalid" if not version_regex.match(to_version)
  
    c = ActiveRecord::Base.connection
    from_to_compare = Caboose::Version.compare_version_strings(from_version, to_version)
  
    if from_to_compare < 0
      versions.select{ |v| v > from_version && v <= to_version }.each{ |v| v.up(c) }
    elsif from_to_compare > 0
      versions.select{ |v| v > to_version && v <= from_version }.reverse_each{ |v| v.down(c) }
    end
  
    version_setting.value = to_version
    version_setting.save
  end
end
