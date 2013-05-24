class DropAllCaboose < ActiveRecord::Migration  
  def up
    drop_table :users                if table_exists?('users')
    drop_table :roles                if table_exists?('roles')
    drop_table :permissions          if table_exists?('permissions')
    drop_table :roles_users          if table_exists?('roles_users')
    drop_table :permissions_roles    if table_exists?('permissions_roles')
    drop_table :assets               if table_exists?('assets')
    drop_table :pages                if table_exists?('pages')
    drop_table :page_permissions     if table_exists?('page_permissions')
  end
  
  def down
    
  end
end