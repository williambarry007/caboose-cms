
class CreateCaboose < ActiveRecord::Migration
  
  def up
    create_tables
    load_data
  end
  
  def down
    drop_table :users
    drop_table :roles
    drop_table :permissions
    drop_table :roles_users
    drop_table :permissions_roles
  end
  
  #=============================================================================
  
  def create_tables

    # User/Role/Permissions    
  	create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :username
      t.string :email
      t.string :password
      t.string :password_reset_id
      t.datetime :password_reset_sent
      t.string :token     
    end
    create_table :roles do |t|
      t.integer :parent_id
      t.string :name
      t.string :description
    end
    create_table :permissions do |t|
      t.string :resource
      t.string :action
    end
    
    # Role membership
    create_table :roles_users do |t|
      t.references :role
      t.references :user
    end
    add_index :roles_users, :role_id
    add_index :roles_users, :user_id
    
    # Role permissions    
    create_table :permissions_roles do |t|
			t.references :role
			t.references :permission
		end
		add_index :permissions_roles, :role_id
		add_index :permissions_roles, :permission_id
    
    # Pages and Assets
    create_table :assets do |t|
      t.references  :page
      t.references  :user
      t.datetime    :date_uploaded
      t.string      :name
      t.string      :filename
      t.string      :description
      t.string      :extension      
    end
    create_table :pages do |t|
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
    create_table :page_permissions do |t|
      t.references  :role
      t.references  :page
      t.string      :action
    end
		
  end
  
  #=============================================================================
  
  def load_data
    
    admin_user = Caboose::User.create(first_name: 'Admin', last_name: 'User', username: 'admin', email: 'william@nine.is')
    admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
    admin_user.save
    
    admin_role  = Caboose::Role.create(parent_id: -1, name: 'Admin')
    elo_role    = Caboose::Role.create(parent_id: -1, name: 'Everyone Logged Out')
    eli_role    = Caboose::Role.create(parent_id: elo_role.id, name: 'Everyone Logged In')
    
    elo_user = Caboose::User.create(first_name: 'John', last_name: 'Doe', username: 'elo', email: 'william@nine.is')
    
    admin_perm = Caboose::Permission.create(resource: 'all', action: 'all')
    Caboose::Permission.create(resource: 'users'	      , action: 'view')
    Caboose::Permission.create(resource: 'users'	      , action: 'edit')
    Caboose::Permission.create(resource: 'users'	      , action: 'delete')
    Caboose::Permission.create(resource: 'users'	      , action: 'add')
    Caboose::Permission.create(resource: 'roles'	      , action: 'view')
    Caboose::Permission.create(resource: 'roles'	      , action: 'edit')
    Caboose::Permission.create(resource: 'roles'	      , action: 'delete')
    Caboose::Permission.create(resource: 'roles'	      , action: 'add')
    Caboose::Permission.create(resource: 'permissions'	, action: 'view')
    Caboose::Permission.create(resource: 'permissions'	, action: 'edit')
    Caboose::Permission.create(resource: 'permissions'	, action: 'delete')
    Caboose::Permission.create(resource: 'permissions'	, action: 'add')

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
    
  end
end
