
class CabooseHelper
  
  def init_file(filename)
    gem_root = Gem::Specification.find_by_name('caboose-cms').gem_dir
    filename = Rails.root.join(filename)  
    copy_from = File.join(gem_root,'lib','sample_files', Pathname.new(filename).basename)
    
    if (!File.exists?(filename))
      FileUtils.cp(copy_from, filename)
    end  
  end
  
  # Add the gem to the Gemfile
  def init_gem
    print "Adding the caboose gem to the Gemfile... "
    if (File.exists?("#{app_path}/Gemfile"))
      File.open("#{app_path}/Gemfile", 'a') { |f| f.print "gem 'caboose', '= #{Caboose::VERSION}'\n" }
      print "done\n"
    else
      print "file doesn't exist\n"
    end
  end
    
  # Require caboose in the application config
  def init_app_config
    puts "Requiring caboose in the application config..."
    
    filename = Rails.root.join('config','application.rb')
    return if !File.exists?(filename)    
          
    file = File.open("#{app_path}/config/application.rb", 'rb')
    contents = file.read
    file.close    
    if (contents.index("require 'caboose'").nil?)
      arr = contents.split("require 'rails/all'", -1)
      str = arr[0] + "\nrequire 'rails/all'\nrequire 'caboose'\n" + arr[1]
      File.open("#{app_path}/config/application.rb", 'w') { |file| file.write(str) }
    end
  end
  
  # Removes the public/index.html file from the rails app
  def remove_public_index
    print "Removing the public/index.html file... "
    
    filename = Rails.root.join('public','index.html')
    return if !File.exists?(filename)
    File.delete(filename)
  end
  
  # Adds the caboose initializer file  
  def init_initializer
    puts "Adding the caboose initializer file..."
    
    filename = Rails.root.join('config','initializers','caboose.rb')
    return if !File.exists?(filename)
    
    Caboose::salt = Digest::SHA1.hexdigest(DateTime.now.to_s)
    str = ""
    str << "# Salt to ensure passwords are encrypted securely\n"
    str << "Caboose::salt = '#{Caboose::salt}'\n\n"
    str << "# Where page asset files will be uploaded\n"
    str << "Caboose::assets_path = Rails.root.join('app', 'assets', 'caboose')\n\n"
    str << "# Register any caboose plugins\n"
    str << "#Caboose::plugins + ['MyCaboosePlugin']\n\n"
    
    File.open(filename, 'w') {|file| file.write(str) }
  end

  # Adds the routes to the host app to point everything to caboose
  def init_routes
    puts "Adding the caboose routes..."
    
    filename = Rails.root.join('config','routes.rb')
    return if !File.exists?(filename)
    
    str = "" 
    str << "\t# Catch everything with caboose\n"  
    str << "\tmount Caboose::Engine => '/'\n"
    str << "\tmatch '*path' => 'caboose/pages#show'\n"
    str << "\troot :to      => 'caboose/pages#show'\n"    
    file = File.open(filename, 'rb')
    contents = file.read
    file.close    
    if (contents.index(str).nil?)
      arr = contents.split('end', -1)
      str2 = arr[0] + "\n" + str + "\nend" + arr[1]
      File.open(filename, 'w') {|file| file.write(str2) }
    end    
  end
  
  def init_assets
    puts "Adding the javascript files..."
    init_file('app/assets/javascripts/caboose_before.js')
    init_file('app/assets/javascripts/caboose_after.js')
    
    puts "Adding the stylesheet files..."
    init_file('app/assets/stylesheets/caboose_before.css')
    init_file('app/assets/stylesheets/caboose_after.css')
    
    puts "Adding the layout files..."
    init_file('app/views/layouts/layout_default.html.erb')
  end
  
  def init_tinymce
    puts "Adding the tinymce config file..."
    init_file('config/tinymce.yml')
  end
  
  def init_session
    puts "Setting the session config..."    
    
    lines = []
    str = File.open(Rails.root.join('config','initializers','session_store.rb')).read 
    str.gsub!(/\r\n?/, "\n")
    str.each_line do |line|
      line = '#' + line if !line.index(':cookie_store').nil?        && !line.starts_with?('#')
      line[0] = ''      if !line.index(':active_record_store').nil? && line.starts_with?('#')
      lines << line.strip
    end
    str = lines.join("\n")
    File.open(Rails.root.join('config','initializers','session_store.rb'), 'w') {|file| file.write(str) }
  end
  
  def init_schema
    drop_tables
    create_tables
  end
  
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
  
  def init_data
    puts "Loading data into caboose tables..."
    
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
    
    # Create the required settings
    Caboose::Setting.create(name: 'version'     , value: Caboose::VERSION)
    Caboose::Setting.create(name: 'site_name'   , value: 'New Caboose Site')
    Caboose::Setting.create(name: 'site_url'    , value: 'www.mycaboosesite.com')
    Caboose::Setting.create(name: 'admin_email' , value: 'william@nine.is')
    
  end
end
