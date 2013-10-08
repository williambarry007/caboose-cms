Caboose::Engine.routes.draw do
  
  get     "admin"                 => "admin#index"
  put     "admin/station"         => "station#index_admin"
  get     "station"               => "station#index"
  get     "station/plugin-count"  => "station#plugin_count"
  
  get     "login"                 => "login#index"
  post    "login"                 => "login#login"
  get     "logout"                => "logout#index"
  get     "register"              => "register#index"
  post    "register"              => "register#register"

  get     "admin/users"                     => "users#index"
  get     "admin/users/options"             => "users#options"
  get     "admin/users/new"                 => "users#new"
  get     "admin/users/:id/edit-password"   => "users#edit_password"
  get     "admin/users/:id/edit"            => "users#edit"
  put     "admin/users/:id"                 => "users#update"
  post    "admin/users"                     => "users#create"
  delete  "admin/users/:id"                 => "users#destroy"
  
  get     "admin/roles"                   => "roles#index"
  get     "admin/roles/options"           => "roles#options"
  get     "admin/roles/new"               => "roles#new"
  get     "admin/roles/:id/edit"          => "roles#edit"
  put     "admin/roles/:id"               => "roles#update"
  post    "admin/roles"                   => "roles#create"
  delete  "admin/roles/:id"               => "roles#destroy"
  
  get     "admin/permissions"             => "permissions#index"
  get     "admin/permissions/options"     => "permissions#options"
  get     "admin/permissions/new"         => "permissions#new"
  get     "admin/permissions/:id/edit"    => "permissions#edit"
  put     "admin/permissions/:id"         => "permissions#update"  
  post    "admin/permissions"             => "permissions#create"
  delete  "admin/permissions/:id"         => "permissions#destroy"
  
  get     "admin/settings"                => "settings#index"
  get     "admin/settings/options"        => "settings#options"
  get     "admin/settings/new"            => "settings#new"
  get     "admin/settings/:id/edit"       => "settings#edit"
  put     "admin/settings/:id"            => "settings#update"  
  post    "admin/settings"                => "settings#create"
  delete  "admin/settings/:id"            => "settings#destroy"
  
  #get     "pages"                           => "pages#index"
  get     "pages/:id"                     => "pages#show"
  get     "pages/:id/redirect"            => "pages#redirect"
  get     "admin/pages/sitemap-options"   => "pages#admin_sitemap_options"
  get     "admin/pages/robots-options"    => "pages#admin_robots_options"
  get     "admin/pages/format-options"    => "pages#admin_content_format_options"
  get     "admin/pages/new"               => "pages#admin_new"  
  get     "admin/pages/:id/sitemap"       => "pages#admin_sitemap"
  get     "admin/pages/:id/edit"          => "pages#admin_edit_general"
  get     "admin/pages/:id/css"           => "pages#admin_edit_css"
  get     "admin/pages/:id/js"            => "pages#admin_edit_js"
  get     "admin/pages/:id/seo"           => "pages#admin_edit_seo" 
  get     "admin/pages/:id/content"       => "pages#admin_edit_content"  
  put     "admin/pages/:id"               => "pages#admin_update"
  get     "admin/pages"                   => "pages#admin_index"
  post    "admin/pages"                   => "pages#admin_create"  
  delete  "admin/pages/:id"               => "pages#admin_destroy"
  
  match '*path' => 'pages#show'
  root :to => 'pages#show'
  
end
