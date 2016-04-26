Caboose::Engine.routes.draw do
  
  #if Caboose::use_comment_routes
  #  eval(Caboose::CommentRoutes.controller_routes)      
  #end
  
  #=============================================================================
  # Front end
  #=============================================================================
  
  get  "/admin"                           => "admin#index"
  put  "/admin/station"                   => "station#index_admin"
  get  "/station"                         => "station#index"
  get  "/station/plugin-count"            => "station#plugin_count"  
  get  "/modal"                           => "modal#layout"
  get  "/modal/:url"                      => "modal#index", :constraints => {:url => /.*/}  
  get  "/login/forgot-password"           => "login#forgot_password_form"
  post "/login/forgot-password"           => "login#send_reset_email"  
  get  "/login/reset-password/:reset_id"  => "login#reset_password_form"
  post "/login/reset-password"            => "login#reset_password"  
  get  "/login"                           => "login#index"
  post "/login"                           => "login#login"  
  get  "/logout"                          => "logout#index"
  get  "/register"                        => "register#index"
  post "/register"                        => "register#register"
  
  #=============================================================================
  # My Account
  #=============================================================================
    
  get  "/my-account/orders/:order_id/line-items/:id/download"  => "my_account_line_items#download"
  get  "/my-account/orders/:order_id/line-items/:id"           => "my_account_line_items#edit"
  get  "/my-account/orders/:order_id/line-items"               => "my_account_line_items#index"

  get  "/my-account/orders/:order_id/billing-address/json"     => "billing_addresses#my_account_json"      
  put  "/my-account/orders/:order_id/billing-address"          => "billing_addresses#my_account_update"
  get  "/my-account/orders/:order_id/shipping-address/json"    => "shipping_addresses#my_account_json"      
  put  "/my-account/orders/:order_id/shipping-address"         => "shipping_addresses#my_account_update"
        
  get  "/my-account/orders/authnet-relay"        => "my_account_orders#authnet_relay"
  post "/my-account/orders/authnet-relay"        => "my_account_orders#authnet_relay"
  get  "/my-account/orders/:id/authnet-response" => "my_account_orders#authnet_response"
  post "/my-account/orders/:id/authnet-response" => "my_account_orders#authnet_response"
  get  "/my-account/orders/:id/payment-form"     => "my_account_orders#payment_form"  
  get  "/my-account/orders/:id/json"             => "my_account_orders#order_json"
  get  "/my-account/orders/:id/json"             => "my_account_orders#order_json"
  get  "/my-account/orders/:id"                  => "my_account_orders#edit"
  get  "/my-account/orders"                      => "my_account_orders#index"
  
  get  "/my-account" => "my_account#index"
  put  "/my-account" => "my_account#update"
  
  #=============================================================================
  # Retargeting
  #=============================================================================
       
  get     "/admin/sites/:site_id/retargeting"       => "retargeting#admin_edit"
  put     "/admin/sites/:site_id/retargeting"       => "retargeting#admin_update"
  
  #=============================================================================
  # Sites
  #=============================================================================  
                               
  get     "/admin/sites/options"                    => "sites#options"            
  get     "/admin/sites/new"                        => "sites#admin_new"
  get     "/admin/sites/:id/default-layout-options" => "sites#admin_default_layout_options"
  get     "/admin/sites/:id/css"                    => "sites#admin_edit_css"
  get     "/admin/sites/:id/js"                     => "sites#admin_edit_js"
  get     "/admin/sites/:id/block-types"            => "sites#admin_edit_block_types"
  get     "/admin/sites/:id/delete"                 => "sites#admin_delete_form"
  get     "/admin/sites/:id"                        => "sites#admin_edit"
  get     "/admin/sites"                            => "sites#admin_index"
  
  post    "/admin/sites"                            => "sites#admin_add"
  post    "/admin/sites/:id/logo"                   => "sites#admin_update_logo"
  put     "/admin/sites/:id"                        => "sites#admin_update"      
  delete  "/admin/sites/:id"                        => "sites#admin_delete"
  post    "/admin/sites/:id/members"                => "sites#admin_add_member"
  delete  "/admin/sites/:id/members/:user_id"       => "sites#admin_remove_member"

  post    "/admin/sites/:site_id/domains"           => "domains#admin_add"
  put     "/admin/sites/:site_id/domains/:id"       => "domains#admin_update"
  delete  "/admin/sites/:site_id/domains/:id"       => "domains#admin_delete"
  put     "/admin/sites/:site_id/domains/:id/set-primary" => "domains#admin_set_primary"
        
  #=============================================================================
  # Login Logs
  #=============================================================================
    
  get "/admin/login-logs/json"      => "login_logs#admin_json"  
  get "/admin/login-logs"           => "login_logs#admin_index"
    
  #=============================================================================
  # Store
  #=============================================================================  
    
  get     "/admin/store/shipping-method-options"    => "store#shipping_method_options"
  get     "/admin/store/payment-processor-options"  => "store#payment_processor_options"        
  get     "/admin/store/length-unit-options"        => "store#length_unit_options"
  get     "/admin/store/weight-unit-options"        => "store#weight_unit_options"
  get     "/admin/store/json"                       => "store#admin_json_single"
  get     "/admin/store/payment"                    => "store#admin_edit_payment"
  get     "/admin/store/shipping"                   => "store#admin_edit_shipping"
  get     "/admin/store/tax"                        => "store#admin_edit_tax"
  get     "/admin/store/packages"                   => "store#admin_edit_packages"
  get     "/admin/store"                            => "store#admin_edit_general"  
  put     "/admin/store"                            => "store#admin_update"
  
  #=============================================================================
  # SMTP
  #=============================================================================  
  
  get     "/admin/smtp/auth-options"  => "smtp#auth_options"   
  get     "/admin/smtp"               => "smtp#admin_edit"  
  put     "/admin/smtp"               => "smtp#admin_update"
    
  #=============================================================================
  # Social
  #=============================================================================  
  
  get     "/admin/social"               => "social#admin_edit"  
  put     "/admin/social"               => "social#admin_update"
  get     "/admin/analytics"            => "social#analytics"

  #=============================================================================
  # Amazon SNS
  #=============================================================================

  get    "/admin/sns/confirm" => "sns#admin_confirm"
  post   "/admin/sns/confirm" => "sns#admin_confirm"
  get    "/admin/sns"         => "sns#admin_index"      
  post   "/admin/sns"         => "sns#admin_add"
  put    "/admin/sns/:id"     => "sns#admin_update"
  delete "/admin/sns/:id"     => "sns#admin_delete"                        
    
  #=============================================================================
  # Fonts
  #=============================================================================  
  
  get     "/admin/fonts"               => "fonts#admin_index"
  put     "/admin/fonts"               => "fonts#admin_update"

  #=============================================================================
  # Shipping Packages
  #=============================================================================
  
  get     "/admin/shipping-packages/options"                     => "shipping_packages#admin_options"    
  get     "/admin/shipping-packages/json"                        => "shipping_packages#admin_json"
  get     "/admin/shipping-packages/:id/json"                    => "shipping_packages#admin_json_single"
  get     "/admin/shipping-packages/:id/shipping-method-options" => "shipping_packages#admin_shipping_method_options"
  get     "/admin/shipping-packages/package-method-options"      => "shipping_packages#admin_package_method_options"
  get     "/admin/shipping-packages/:id"                         => "shipping_packages#admin_edit"
  get     "/admin/shipping-packages"                             => "shipping_packages#admin_index"  
  put     "/admin/shipping-packages/bulk"                        => "shipping_packages#admin_bulk_update"
  put     "/admin/shipping-packages/:id"                         => "shipping_packages#admin_update"
  post    "/admin/shipping-packages/bulk"                        => "shipping_packages#admin_bulk_add"
  post    "/admin/shipping-packages"                             => "shipping_packages#admin_add"
  delete  "/admin/shipping-packages/bulk"                        => "shipping_packages#admin_bulk_delete"
  delete  "/admin/shipping-packages/:id"                         => "shipping_packages#admin_delete"
  get     "/admin/shipping-methods/options"                      => "shipping_packages#admin_shipping_method_options"
  
  #=============================================================================
  # 301 Redirects
  #=============================================================================
  
  get     "/admin/redirects"      => "redirects#admin_index"    
  get     "/admin/redirects/new"  => "redirects#admin_new"  
  get     "/admin/redirects/:id"  => "redirects#admin_edit"  
  put     "/admin/redirects/:id"  => "redirects#admin_update"  
  post    "/admin/redirects"      => "redirects#admin_add"  
  delete  "/admin/redirects/:id"  => "redirects#admin_delete"
  
  #=============================================================================
  # Users
  #=============================================================================
  
  get     "/admin/users"                     => "users#admin_index"
  get     "/admin/users/json"                => "users#admin_json"        
  get     "/admin/users/options"             => "users#admin_options"
  get     "/admin/users/new"                 => "users#admin_new"
  get     "/admin/users/import"              => "users#admin_import_form"
  post    "/admin/users/import"              => "users#admin_import"
  get     "/admin/users/:id/json"            => "users#admin_json_single"
  get     "/admin/users/:id/su/:token"       => "users#admin_su_token"
  get     "/admin/users/:id/su"              => "users#admin_su"
  get     "/admin/users/:id/edit-password"   => "users#admin_edit_password"
  get     "/admin/users/:id"                 => "users#admin_edit"  
  put     "/admin/users/:id"                 => "users#admin_update"
  post    "/admin/users"                     => "users#admin_add"
  delete  "/admin/users/:id"                 => "users#admin_delete"
  
  post    "/admin/users/:id/roles/:role_id"  => "users#admin_add_to_role"  
  delete  "/admin/users/:id/roles/:role_id"  => "users#admin_remove_from_role"
  
  #=============================================================================
  # Roles
  #=============================================================================
  
  get     "/admin/roles"                   => "roles#index"
  get     "/admin/roles/options"           => "roles#options"
  get     "/admin/roles/new"               => "roles#new"
  get     "/admin/roles/:id"               => "roles#edit"
  put     "/admin/roles/:id"               => "roles#update"
  post    "/admin/roles"                   => "roles#create"
  delete  "/admin/roles/:id"               => "roles#destroy"
  
  post    "/admin/roles/:id/permissions/:permission_id"  => "roles#add_permission"  
  delete  "/admin/roles/:id/permissions/:permission_id"  => "roles#remove_permission"
  
  #=============================================================================
  # Permissions
  #=============================================================================
  
  get     "/admin/permissions"             => "permissions#index"
  get     "/admin/permissions/options"     => "permissions#options"
  get     "/admin/permissions/new"         => "permissions#new"
  get     "/admin/permissions/:id"         => "permissions#edit"
  put     "/admin/permissions/:id"         => "permissions#update"  
  post    "/admin/permissions"             => "permissions#create"
  delete  "/admin/permissions/:id"         => "permissions#destroy"
  
  #=============================================================================
  # Images
  #=============================================================================

  get     "/admin/media/last-upload-processed" => "media#admin_last_upload_processed"
  post    "/admin/media/pre-upload"            => "media#admin_pre_upload"
  get     "/admin/media"                       => "media#admin_index"    
  get     "/admin/media/new"                   => "media#admin_new"
  get     "/admin/media/json"                  => "media#admin_json"
  get     "/admin/media/:id/process"           => "media#admin_process"
  get     "/admin/media/:id/finished"          => "media#admin_process_finished"
  get     "/admin/media/:id/description"       => "media#admin_edit_description"
  get     "/admin/media/:id"                   => "media#admin_edit"  
  put     "/admin/media/:id"                   => "media#admin_update"
  post    "/admin/media/:id/image"             => "media#admin_update_image"
  #post    "/admin/media/edit-image"           => "media#admin_edit_image"  
  post    "/admin/media"                       => "media#admin_add"  
  delete  "/admin/media/bulk"                  => "media#admin_bulk_delete"
  delete  "/admin/media/:id"                   => "media#admin_delete"
  
  
  get     "/admin/media-categories/json"       => "media_categories#admin_json"
  get     "/admin/media-categories/options"    => "media_categories#admin_options"
  get     "/admin/media-categories/flat-tree"  => "media_categories#admin_flat_tree"
  get     "/admin/media-categories/tree"       => "media_categories#admin_tree"    
  post    "/admin/media-categories"            => "media_categories#admin_add"
  post    "/admin/media-categories/:id/attach" => "media_categories#admin_attach"
  put     "/admin/media-categories/:id/sort-order" => "media_categories#admin_update_sort_order"    
  put     "/admin/media-categories/:id"        => "media_categories#admin_update"      
  delete  "/admin/media-categories/:id"        => "media_categories#admin_delete"
  
  #=============================================================================
  # Settings
  #=============================================================================
    
  get     "/admin/settings"                => "settings#index"
  get     "/admin/settings/options"        => "settings#options"
  get     "/admin/settings/new"            => "settings#new"
  get     "/admin/settings/:id"            => "settings#edit"
  put     "/admin/settings/:id"            => "settings#update"  
  post    "/admin/settings"                => "settings#create"
  delete  "/admin/settings/:id"            => "settings#destroy"
  
  #=============================================================================
  # Pages
  #=============================================================================
  
  get     "/pages/:id"                     => "pages#show"
  get     "/pages/:id/redirect"            => "pages#redirect"    
  get     "/admin/pages/sitemap-options"   => "pages#admin_sitemap_options"
  get     "/admin/pages/robots-options"    => "pages#admin_robots_options"
  get     "/admin/pages/format-options"    => "pages#admin_content_format_options"
  get     "/admin/pages/new"               => "pages#admin_new"
  get     "/admin/pages/:id/block-options" => "pages#admin_block_options"  
  get     "/admin/pages/:id/uri"           => "pages#admin_page_uri"
  get     "/admin/pages/:id/duplicate"     => "pages#admin_duplicate_form"
  post    "/admin/pages/:id/duplicate"     => "pages#admin_duplicate"
  get     "/admin/pages/:id/delete"        => "pages#admin_delete_form"  
  get     "/admin/pages/:id/sitemap"       => "pages#admin_sitemap"  
  get     "/admin/pages/:id/custom-fields" => "pages#admin_edit_custom_fields"
  get     "/admin/pages/:id/permissions"   => "pages#admin_edit_permissions"
  get     "/admin/pages/:id/css"           => "pages#admin_edit_css"
  get     "/admin/pages/:id/js"            => "pages#admin_edit_js"
  get     "/admin/pages/:id/seo"           => "pages#admin_edit_seo" 
  get     "/admin/pages/:id/block-order"   => "pages#admin_edit_block_order"
  put     "/admin/pages/:id/block-order"   => "pages#admin_update_block_order"
  get     "/admin/pages/:id/child-order"   => "pages#admin_edit_child_sort_order"
  put     "/admin/pages/:id/child-order"   => "pages#admin_update_child_sort_order"
  get     "/admin/pages/:id/new-blocks"    => "pages#admin_new_blocks"
  get     "/admin/pages/:id/content"       => "pages#admin_edit_content"
  get     "/admin/pages/:id/layout"        => "pages#admin_edit_layout"
  put     "/admin/pages/:id/layout"        => "pages#admin_update_layout"
  put     "/admin/pages/:id/viewers"       => "pages#admin_update_viewers"
  put     "/admin/pages/:id/editors"       => "pages#admin_update_editors"
  get     "/admin/pages/:id"               => "pages#admin_edit_general"
  put     "/admin/pages/:id/update-child-permissions" => "pages#admin_update_child_permissions"  
  put     "/admin/pages/:id"               => "pages#admin_update"  
  get     "/admin/pages"                   => "pages#admin_index"
  post    "/admin/pages"                   => "pages#admin_create"  
  delete  "/admin/pages/:id"               => "pages#admin_delete"
  
  post    "/admin/page-permissions"        => "page_permissions#admin_add"  
  delete  "/admin/page-permissions"        => "page_permissions#admin_delete"
  delete  "/admin/page-permissions/:id"    => "page_permissions#admin_delete"  
    
  get     "/admin/pages/:page_id/blocks/new"                  => "blocks#admin_new"  
  get     "/admin/pages/:page_id/blocks/tree"                 => "blocks#admin_tree"
  get     "/admin/pages/:page_id/blocks/render"               => "blocks#admin_render_all"
  get     "/admin/pages/:page_id/blocks/render-second-level"  => "blocks#admin_render_second_level"
  get     "/admin/pages/:page_id/blocks/:id/render"           => "blocks#admin_render"
  get     "/admin/pages/:page_id/blocks/:id/tree"             => "blocks#admin_tree"
  get     "/admin/pages/:page_id/blocks/:id/render"           => "blocks#admin_render"  
  get     "/admin/pages/:page_id/blocks/:id/edit"             => "blocks#admin_edit"
  get     "/admin/pages/:page_id/blocks/:id/advanced"         => "blocks#admin_edit_advanced"
  put     "/admin/pages/:page_id/blocks/:id/move-up"          => "blocks#admin_move_up"
  put     "/admin/pages/:page_id/blocks/:id/move-down"        => "blocks#admin_move_down"
  get     "/admin/pages/:page_id/blocks/:id"                  => "blocks#admin_show"
  get     "/admin/pages/:page_id/blocks"                      => "blocks#admin_index"  
  post    "/admin/pages/:page_id/blocks"                      => "blocks#admin_create"
  get     "/admin/pages/:page_id/blocks/:id/new"              => "blocks#admin_new"
  post    "/admin/pages/:page_id/blocks/:id"                  => "blocks#admin_create"  
  put     "/admin/pages/:page_id/blocks/:id"                  => "blocks#admin_update"
  delete  "/admin/pages/:page_id/blocks/:id"                  => "blocks#admin_delete"  
  put     "/admin/pages/:page_id/blocks/:id"                  => "blocks#admin_update"
  post    "/admin/pages/:page_id/blocks/:id/image"            => "blocks#admin_update_image"
  post    "/admin/pages/:page_id/blocks/:id/file"             => "blocks#admin_update_file"
  
  get     "/admin/posts/:post_id/blocks/new"                  => "blocks#admin_new"  
  get     "/admin/posts/:post_id/blocks/tree"                 => "blocks#admin_tree"
  get     "/admin/posts/:post_id/blocks/render"               => "blocks#admin_render_all"
  get     "/admin/posts/:post_id/blocks/render-second-level"  => "blocks#admin_render_second_level"
  get     "/admin/posts/:post_id/blocks/:id/render"           => "blocks#admin_render"
  get     "/admin/posts/:post_id/blocks/:id/tree"             => "blocks#admin_tree"
  get     "/admin/posts/:post_id/blocks/:id/render"           => "blocks#admin_render"  
  get     "/admin/posts/:post_id/blocks/:id/edit"             => "blocks#admin_edit"  
  get     "/admin/posts/:post_id/blocks/:id/advanced"         => "blocks#admin_edit_advanced"
  put     "/admin/posts/:post_id/blocks/:id/move-up"          => "blocks#admin_move_up"
  put     "/admin/posts/:post_id/blocks/:id/move-down"        => "blocks#admin_move_down"
  get     "/admin/posts/:post_id/blocks/:id"                  => "blocks#admin_show"
  get     "/admin/posts/:post_id/blocks"                      => "blocks#admin_index"  
  post    "/admin/posts/:post_id/blocks"                      => "blocks#admin_create"
  get     "/admin/posts/:post_id/blocks/:id/new"              => "blocks#admin_new"
  post    "/admin/posts/:post_id/blocks/:id"                  => "blocks#admin_create"  
  put     "/admin/posts/:post_id/blocks/:id"                  => "blocks#admin_update"
  delete  "/admin/posts/:post_id/blocks/:id"                  => "blocks#admin_delete"  
  put     "/admin/posts/:post_id/blocks/:id"                  => "blocks#admin_update"
  post    "/admin/posts/:post_id/blocks/:id/image"            => "blocks#admin_update_image"
  post    "/admin/posts/:post_id/blocks/:id/file"             => "blocks#admin_update_file"
  
  #=============================================================================
  # Block types
  #=============================================================================
  
  get     "/admin/block-types/store/sources"              => "block_type_sources#admin_index"
  get     "/admin/block-types/store/sources/new"          => "block_type_sources#admin_new"
  get     "/admin/block-types/store/sources/options"      => "block_type_sources#admin_options"
  get     "/admin/block-types/store/sources/:id/edit"     => "block_type_sources#admin_edit"    
  get     "/admin/block-types/store/sources/:id/refresh"  => "block_type_sources#admin_refresh"
  post    "/admin/block-types/store/sources"              => "block_type_sources#admin_create"
  put     "/admin/block-types/store/sources/:id"          => "block_type_sources#admin_update"
  delete  "/admin/block-types/store/sources/:id"          => "block_type_sources#admin_delete"
  
  get     "/admin/block-types/store/:block_type_summary_id/download"  => "block_type_store#admin_download"  
  get     "/admin/block-types/store/:block_type_summary_id"           => "block_type_store#admin_details"  
  get     "/admin/block-types/store"                                  => "block_type_store#admin_index"
            
  get     "/admin/block-types/new"                  => "block_types#admin_new"
  get     "/admin/block-types/json"                 => "block_types#admin_json"    
  get     "/admin/block-types/options"              => "block_types#admin_options"
  get     "/admin/block-types/:field-options"       => "block_types#admin_options"
  get     "/admin/block-types/:id/options"          => "block_types#admin_options"
  get     "/admin/block-types/:id/json"             => "block_types#admin_json_single"  
  get     "/admin/block-types/:id/new"              => "block_types#admin_new"                  
  get     "/admin/block-types/:id/icon"             => "block_types#admin_edit_icon"
  get     "/admin/block-types/:id"                  => "block_types#admin_edit"            
  put     "/admin/block-types/:id"                  => "block_types#admin_update"
  delete  "/admin/block-types/:id"                  => "block_types#admin_delete"
  get     "/admin/block-types"                      => "block_types#admin_index"
  post    "/admin/block-types"                      => "block_types#admin_create"
  
  get     "/admin/block-type-categories/tree-options" => "block_type_categories#admin_tree_options"
      
  #=============================================================================
  # Posts
  #=============================================================================

  get     "/posts"                                 => "posts#index"
  get     "/posts/:id"                             => "posts#show"
  get     "/posts/:year/:month/:day/:slug"         => "posts#show"
  get     "/admin/posts/category-options"          => "posts#admin_category_options"
  get     "/admin/posts/new"                       => "posts#admin_new"  
  get     "/admin/posts/:id/json"                  => "posts#admin_json_single"  
  get     "/admin/posts/:id/edit"                  => "posts#admin_edit_general"
  get     "/admin/posts/:id/delete"                => "posts#admin_delete_form"
  get     "/admin/posts/:id/preview"               => "posts#admin_edit_preview"
  get     "/admin/posts/:id/content"               => "posts#admin_edit_content"
  get     "/admin/posts/:id/layout"                => "posts#admin_edit_layout"
  put     "/admin/posts/:id/layout"                => "posts#admin_update_layout"
  get     "/admin/posts/:id/categories"            => "posts#admin_edit_categories"
  get     "/admin/posts/:id/add-to-category"       => "posts#admin_add_to_category"
  get     "/admin/posts/:id/remove-from-category"  => "posts#admin_remove_from_category"
  get     "/admin/posts/:id/delete"                => "posts#admin_delete_form"
  get     "/admin/posts/:id"                       => "posts#admin_edit_general"
  put     "/admin/posts/:id"                       => "posts#admin_update"
  post    "/admin/posts/:id/image"                 => "posts#admin_update_image"
  get     "/admin/posts"                           => "posts#admin_index"
  post    "/admin/posts"                           => "posts#admin_add"  
  delete  "/admin/posts/:id"                       => "posts#admin_delete"

  #=============================================================================
  # Post Categories
  #=============================================================================

  get     "/admin/post-categories"                         => "post-categories#admin_index"
  get     "/admin/post-categories/new"                     => "post-categories#admin_new"
  get     "/admin/post-categories/options"                 => "post-categories#admin_options"
  get     '/admin/post-categories/status-options'          => 'post-categories#admin_status_options'
  get     "/admin/post-categories/:id/sort-children"       => "post-categories#admin_sort_children"
  put     "/admin/post-categories/:id/children/sort-order" => "post-categories#admin_update_sort_order"
  get     "/admin/post-categories/:id/products/json"       => "post-categories#admin_category_products"  
  get     "/admin/post-categories/:id"                     => "post-categories#admin_edit"  
  put     "/admin/post-categories/:id"                     => "post-categories#admin_update"    
  post    "/admin/post-categories/:id"                     => "post-categories#admin_update"  
  post    "/admin/post-categories"                         => "post-categories#admin_add"
  delete  "/admin/post-categories/:id"                     => "post-categories#admin_delete"
        
  #=============================================================================
  # Post Custom Fields and Values
  #=============================================================================
  
  put    "/admin/post-custom-field-values/:id"      => "post_custom_field_values#admin_update"
  get    "/admin/post-custom-fields/json"           => "post_custom_fields#admin_json"
  get    "/admin/post-custom-fields/:field-options" => "post_custom_fields#admin_options"  
  get    "/admin/post-custom-fields/:id/json"       => "post_custom_fields#admin_json_single"  
  get    "/admin/post-custom-fields/:id"            => "post_custom_fields#admin_edit"
  put    "/admin/post-custom-fields/:id"            => "post_custom_fields#admin_update"
  get    "/admin/post-custom-fields"                => "post_custom_fields#admin_index"        
  post   "/admin/post-custom-fields"                => "post_custom_fields#admin_add"
  delete "/admin/post-custom-fields/:id"            => "post_custom_fields#admin_delete"
  
  #=============================================================================
  # Page Custom Fields and Values
  #=============================================================================
  
  put    "/admin/page-custom-field-values/:id"      => "page_custom_field_values#admin_update"
  get    "/admin/page-custom-fields/json"           => "page_custom_fields#admin_json"
  get    "/admin/page-custom-fields/:field-options" => "page_custom_fields#admin_options"  
  get    "/admin/page-custom-fields/:id/json"       => "page_custom_fields#admin_json_single"  
  get    "/admin/page-custom-fields/:id"            => "page_custom_fields#admin_edit"
  put    "/admin/page-custom-fields/:id"            => "page_custom_fields#admin_update"
  get    "/admin/page-custom-fields"                => "page_custom_fields#admin_index"        
  post   "/admin/page-custom-fields"                => "page_custom_fields#admin_add"
  delete "/admin/page-custom-fields/:id"            => "page_custom_fields#admin_delete"
        
  #=============================================================================
  # Google Spreadsheets
  #=============================================================================
  
  get     "/google-spreadsheets/:spreadsheet_id/csv" => "google_spreadsheets#csv_data"
      
  #=============================================================================
  # Calendar
  #=============================================================================
  
  get     "/admin/calendars"                         => "calendars#admin_index"
  get     "/admin/calendars/:id"                     => "calendars#admin_edit"
  put     "/admin/calendars/:id"                     => "calendars#admin_update"
  post    "/admin/calendars"                         => "calendars#admin_add"
  delete  "/admin/calendars"                         => "calendars#admin_delete"
  
  get     "/admin/calendars/:calendar_id/events"     => "events#admin_index"
  get     "/admin/calendars/:calendar_id/events/new" => "events#admin_new"
  get     "/admin/calendars/:calendar_id/events/:id" => "events#admin_edit"
  put     "/admin/calendars/:calendar_id/events/:id" => "events#admin_update"
  post    "/admin/calendars/:calendar_id/events"     => "events#admin_add"
  delete  "/admin/calendars/:calendar_id/events/:id" => "events#admin_delete"
  
  put     "/admin/calendars/:calendar_id/event-groups/:id" => "event_groups#admin_update"
  get     "/admin/event-groups/period-options"             => "event_groups#admin_period_options"
  get     "/admin/event-groups/frequency-options"          => "event_groups#admin_frequency_options"
  get     "/admin/event-groups/repeat-by-options"          => "event_groups#admin_repeat_by_options"

  #=============================================================================
  # AB Testing
  #=============================================================================
  
  get     "/admin/ab-variants"                     => "ab_variants#admin_index"
  get     "/admin/ab-variants/new"                 => "ab_variants#admin_new"
  get     "/admin/ab-variants/:id"                 => "ab_variants#admin_edit"
  put     "/admin/ab-variants/:id"                 => "ab_variants#admin_update"
  post    "/admin/ab-variants"                     => "ab_variants#admin_create"  
  delete  "/admin/ab-variants/:id"                 => "ab_variants#admin_delete"
  
  get     "/admin/ab-variants/:variant_id/options" => "ab_options#admin_index"    
  put     "/admin/ab-options/:id"                  => "ab_options#admin_update"
  post    "/admin/ab-variants/:variant_id/options" => "ab_options#admin_create"
  delete  "/admin/ab-options/:id"                  => "ab_options#admin_delete"
  
  #=============================================================================
  # Reviews  
  #=============================================================================
  
  post    "/reviews/add"        => "reviews#add"
  
  #=============================================================================
  # Cart  
  #=============================================================================
  
  get     '/cart'                         => 'cart#index'
  get     '/cart/items'                   => 'cart#list'
  get     '/cart/item-count'              => 'cart#item_count'
  post    '/cart'                         => 'cart#add'
  post    '/cart/gift-cards'              => 'cart#add_gift_card'
  delete  '/cart/discounts/:discount_id'  => 'cart#remove_discount'
  put     '/cart/:line_item_id'           => 'cart#update'
  delete  '/cart/:line_item_id'           => 'cart#remove'
  
  #=============================================================================
  # Checkout  
  #=============================================================================
  
  get  '/checkout'                 => 'checkout#index'
  get  '/checkout/total'           => 'checkout#verify_total'  
  post '/checkout/attach-user'     => 'checkout#attach_user'
  post '/checkout/attach-guest'    => 'checkout#attach_guest'
  get  '/checkout/addresses'       => 'checkout#addresses'
  put  '/checkout/addresses'       => 'checkout#update_addresses'
  get  '/checkout/shipping'        => 'checkout#shipping'
  put  '/checkout/shipping'        => 'checkout#update_shipping'
  get  '/checkout/gift-cards'      => 'checkout#gift_cards'  
  get  '/checkout/payment'         => 'checkout#payment'
  get  '/checkout/confirm'         => 'checkout#confirm_without_payment'
  post '/checkout/confirm'         => 'checkout#confirm'  
  get  '/checkout/thanks'          => 'checkout#thanks'
  get  '/checkout/test-email'      => 'checkout#test_email'

  get  '/checkout/authnet-profile-form'       => 'checkout#authnet_profile_form'          
  get  '/checkout/authnet-relay/:order_id'    => 'checkout#authnet_relay'
  post '/checkout/authnet-relay/:order_id'    => 'checkout#authnet_relay'
  get  '/checkout/authnet-relay'              => 'checkout#authnet_relay'
  post '/checkout/authnet-relay'              => 'checkout#authnet_relay'
  get  '/checkout/authnet-response/:order_id' => 'checkout#authnet_response'
  post '/checkout/authnet-response/:order_id' => 'checkout#authnet_response'      
  get  '/checkout/empty'                      => 'checkout#empty'
  
  #=============================================================================
  # Product Modifications  
  #=============================================================================
  
  get    "/admin/products/:product_id/modifications/:mod_id/values/json"        => "modification_values#admin_json"
  get    "/admin/products/:product_id/modifications/:mod_id/values/:id/json"    => "modification_values#admin_json_single"
  put    "/admin/products/:product_id/modifications/:mod_id/values/:id"         => "modification_values#admin_update"
  post   "/admin/products/:product_id/modifications/:mod_id/values"             => "modification_values#admin_add"
  delete "/admin/products/:product_id/modifications/:mod_id/values/:id"         => "modification_values#admin_delete"
  put    "/admin/products/:product_id/modifications/:mod_id/values/sort-order"  => "modification_values#admin_update_sort_order"            

  get    "/admin/products/:product_id/modifications/json"        => "modifications#admin_json"
  get    "/admin/products/:product_id/modifications/:id/json"    => "modifications#admin_json_single"
  put    "/admin/products/:product_id/modifications/:id"         => "modifications#admin_update"
  post   "/admin/products/:product_id/modifications"             => "modifications#admin_add"
  delete "/admin/products/:product_id/modifications/:id"         => "modifications#admin_delete"
  put    "/admin/products/:product_id/modifications/sort-order"  => "modifications#admin_update_sort_order"            

    
  #=============================================================================
  # Products  
  #=============================================================================
    
  get     '/products/:id/info' => 'products#info'
  get     '/products/:id'      => 'products#index', :constraints => { :id => /.*/ }
  get     '/products'          => 'products#index'

  post    '/variants/find-by-options'   => 'variants#find_by_options'
  get     '/variants/:id/display-image' => 'variants#display_image'
                                                                               
  get     "/admin/products"                                 => "products#admin_index"
  get     "/admin/products/json"                            => "products#admin_json"
  get     '/admin/products/sort'                            => 'products#admin_sort'  
  put     "/admin/categories/:category_id/products/sort-order" => "products#admin_update_sort_order"  
  put     "/admin/products/update-vendor-status/:id"        => "products#admin_update_vendor_status"
  get     "/admin/products/new"                             => "products#admin_new"
  get     "/admin/products/status-options"                  => "products#admin_status_options"    
  get     "/admin/products/:id/general"                     => "products#admin_edit_general"    
  get     "/admin/products/:id/description"                 => "products#admin_edit_description"
  get     "/admin/products/:id/categories"                  => "products#admin_edit_categories"  
  post    "/admin/products/:id/categories"                  => "products#admin_add_to_category"
  delete  "/admin/products/:id/categories/:category_id"     => "products#admin_remove_from_category"

  get     "/admin/products/:product_id/variants"                         => "variants#admin_index"
  get     "/admin/products/:product_id/variants/json"                    => "variants#admin_json"  
  get     "/admin/products/:product_id/variants/option1-media"           => "variants#admin_edit_option1_media"
  get     "/admin/products/:product_id/variants/option2-media"           => "variants#admin_edit_option2_media"
  get     "/admin/products/:product_id/variants/option3-media"           => "variants#admin_edit_option3_media"
  get     "/admin/products/:product_id/variants/sort-order"              => "variants#admin_edit_sort_order"
  put     '/admin/products/:product_id/variants/option1-sort-order'      => 'variants#admin_update_option1_sort_order'
  put     '/admin/products/:product_id/variants/option2-sort-order'      => 'variants#admin_update_option2_sort_order'
  put     '/admin/products/:product_id/variants/option3-sort-order'      => 'variants#admin_update_option3_sort_order'      
  put     "/admin/products/:product_id/variants/:id/attach-to-image"     => "variants#admin_attach_to_image"
  put     "/admin/products/:product_id/variants/:id/unattach-from-image" => "variants#admin_unattach_from_image"
  get     "/admin/products/:product_id/variants/:id/download-url"        => "variants#admin_download_url"
  get     "/admin/products/:product_id/variants/:id/json"                => "variants#admin_json_single"
  get     "/admin/products/:product_id/variants/:id"                     => "variants#admin_edit"  
  put     '/admin/products/:product_id/variants/bulk'                    => 'variants#admin_bulk_update'
  put     "/admin/products/:product_id/variants/:id"                     => "variants#admin_update"  
  get     "/admin/products/:product_id/variants/new"                     => "variants#admin_new"
  post    '/admin/products/:product_id/variants/bulk'                    => 'variants#admin_bulk_add'  
  post    "/admin/products/:product_id/variants"                         => "variants#admin_add"    
  delete  '/admin/products/:product_id/variants/bulk'                    => 'variants#admin_bulk_delete'
  delete  "/admin/products/:product_id/variants/:id"                     => "variants#admin_delete"  
  get     "/admin/variants/status-options"                               => "variants#admin_status_options"
  get     '/admin/variants/group'                                        => 'variants#admin_group'  
  
  get     "/admin/products/:id/images"                      => "products#admin_edit_images"
  post    "/admin/products/:id/images"                      => "products#admin_add_image"
  get     "/admin/products/:id/collections"                 => "products#admin_edit_collections"
  get     "/admin/products/:id/seo"                         => "products#admin_edit_seo"
  get     "/admin/products/:id/options"                     => "products#admin_edit_options"
  get     "/admin/products/:id/delete"                      => "products#admin_delete_form"
  get     "/admin/products/:id/json"                        => "products#admin_json_single"
  get     "/admin/products/:id"                             => "products#admin_edit_general"
  put     "/admin/products/:id"                             => "products#admin_update"
  post    "/admin/products"                                 => "products#admin_add"
  delete  "/admin/products/:id"                             => "products#admin_delete"
  put     "/admin/products/:id/update-vendor"               => "products#admin_update_vendor"
  
  put     "/admin/product-images/sort-order"          => "product_images#admin_update_sort_order"      
  get     "/admin/product-images/:id/variant-ids"     => "product_images#admin_variant_ids"
  get     "/admin/product-images/:id/variants"        => "product_images#admin_variants"
  delete  "/admin/product-images/:id"                 => "product_images#admin_delete"
  get     "/variant-images/:id"                       => "product_images#variant_images"
  
  #=============================================================================
  # Stackable groups
  #=============================================================================
  
  get     "/admin/stackable-groups/options"   => "stackable_groups#admin_options"  
  get     "/admin/stackable-groups/json"      => "stackable_groups#admin_json"
  get     "/admin/stackable-groups/:id/json"  => "stackable_groups#admin_json_single"
  get     "/admin/stackable-groups"           => "stackable_groups#admin_index"
  put     "/admin/stackable-groups/:id"       => "stackable_groups#admin_update"
  post    "/admin/stackable-groups"           => "stackable_groups#admin_add"
  delete  "/admin/stackable-groups/bulk"      => "stackable_groups#admin_bulk_delete"
  delete  "/admin/stackable-groups/:id"       => "stackable_groups#admin_delete"    

  #=============================================================================
  # Categories
  #=============================================================================
          
  

  get     "/admin/categories"                         => "categories#admin_index"
  get     "/admin/categories/new"                     => "categories#admin_new"
  get     "/admin/categories/options"                 => "categories#admin_options"
  get     '/admin/categories/status-options'          => 'categories#admin_status_options'
  get     "/admin/categories/:id/sort-children"       => "categories#admin_sort_children"
  put     "/admin/categories/:id/children/sort-order" => "categories#admin_update_sort_order"
  get     "/admin/categories/:id/products/json"       => "categories#admin_category_products"  
  get     "/admin/categories/:id"                     => "categories#admin_edit"  
  put     "/admin/categories/:id"                     => "categories#admin_update"    
  post    "/admin/categories/:id"                     => "categories#admin_update"  
  post    "/admin/categories"                         => "categories#admin_add"
  delete  "/admin/categories/:id"                     => "categories#admin_delete"
  
  #=============================================================================  
  # Orders
  #=============================================================================
  
  get     "/admin/orders/city-report"                 => "orders#admin_city_report"
  get     "/admin/orders/summary-report"              => "orders#admin_summary_report"
  get     "/admin/orders/weird-test"                  => "orders#admin_weird_test"
  get     "/admin/orders"                             => "orders#admin_index"
  get     "/admin/orders/test-info"                   => "orders#admin_mail_test_info"
  get     "/admin/orders/test-gmail"                  => "orders#admin_mail_test_gmail"  
  get     "/admin/orders/status-options"              => "orders#admin_status_options"
  get     "/admin/orders/new"                         => "orders#admin_new"
  get     "/admin/orders/print-pending"               => "orders#admin_print_pending"  
  get     "/admin/orders/:id/calculate-tax"           => "orders#admin_calculate_tax"
  get     "/admin/orders/:id/calculate-handling"      => "orders#admin_calculate_handling"      
  get     "/admin/orders/:id/send-for-authorization"  => "orders#admin_send_for_authorization"
  get     "/admin/orders/:id/capture"                 => "orders#capture_funds"  
  get     "/admin/orders/:id/json"                    => "orders#admin_json"
  get     "/admin/orders/:id/print"                   => "orders#admin_print"
  get     "/admin/orders/:id/send-to-quickbooks"      => "orders#admin_send_to_quickbooks"
  get     "/admin/orders/:id"                         => "orders#admin_edit"        
  put     "/admin/orders/:id"                         => "orders#admin_update"
  delete  "/admin/orders/:id"                         => "orders#admin_delete"
  get     '/admin/orders/:id/void'                    => 'orders#admin_void'
  get     '/admin/orders/:id/refund'                  => 'orders#admin_refund'
  post    '/admin/orders/:id/resend-confirmation'     => 'orders#admin_resend_confirmation'
  post    '/admin/orders'                             => 'orders#admin_add'
  
  get     "/admin/orders/line-items/status-options"           => "line_items#admin_status_options"
  get     "/admin/orders/line-items/product-stubs"            => "line_items#admin_product_stubs"
  get     "/admin/orders/:order_id/line-items/new"            => "line_items#admin_new"
  get     "/admin/orders/:order_id/line-items/json"           => "line_items#admin_json"  
  post    "/admin/orders/:order_id/line-items"                => "line_items#admin_add"
  get     "/admin/orders/:order_id/line-items/:id/highlight"  => "line_items#admin_highlight"  
  put     "/admin/orders/:order_id/line-items/:id"            => "line_items#admin_update"  
  delete  "/admin/orders/:order_id/line-items/:id"            => "line_items#admin_delete"
  
  get     "/admin/orders/:order_id/packages/json"               => "order_packages#admin_json"
  get     "/admin/orders/:order_id/packages/:id/calculate-shipping" => "order_packages#calculate_shipping"    
  get     "/admin/orders/:order_id/packages/:id/shipping-rates" => "order_packages#shipping_rates"
  put     "/admin/orders/:order_id/packages/:id"                => "order_packages#admin_update"
  post    "/admin/orders/:order_id/packages"                    => "order_packages#admin_add"
  delete  "/admin/orders/:order_id/packages/:id"                => "order_packages#admin_delete"    
    
  get     "/admin/orders/:order_id/packages/json"     => "line_items#admin_json"  
  put     "/admin/orders/:order_id/line-items/:id"    => "line_items#admin_update"
  delete  "/admin/orders/:order_id/line-items/:id"    => "line_items#admin_delete"
  
  get     "/admin/orders/:order_id/billing-address/json"   => "billing_addresses#admin_json"      
  put     "/admin/orders/:order_id/billing-address"        => "billing_addresses#admin_update"
  get     "/admin/orders/:order_id/shipping-address/json"  => "shipping_addresses#admin_json"      
  put     "/admin/orders/:order_id/shipping-address"       => "shipping_addresses#admin_update"
  
  #=============================================================================
  # Gift cards
  #=============================================================================
  
  get    "/admin/gift-cards"                   => "gift_cards#admin_index"  
  get    "/admin/gift-cards/json"              => "gift_cards#admin_json"
  get    "/admin/gift-cards/new"               => "gift_cards#admin_new"        
  get    "/admin/gift-cards/status-options"    => "gift_cards#admin_status_options"
  get    "/admin/gift-cards/card-type-options" => "gift_cards#admin_card_type_options"
  get    "/admin/gift-cards/:id/json"          => "gift_cards#admin_json_single"
  get    "/admin/gift-cards/:id"               => "gift_cards#admin_edit"
  put    "/admin/gift-cards/bulk"              => "gift_cards#admin_bulk_update"  
  put    "/admin/gift-cards/:id"               => "gift_cards#admin_update"
  post   "/admin/gift-cards/bulk"              => "gift_cards#admin_bulk_add"  
  post   "/admin/gift-cards"                   => "gift_cards#admin_add"
  delete "/admin/gift-cards/bulk"              => "gift_cards#admin_bulk_delete"
  delete "/admin/gift-cards/:id"               => "gift_cards#admin_delete"
      
  #=============================================================================
  # Vendors
  #=============================================================================
  
  get     '/admin/vendors/options'        => 'vendors#options'
  get     '/admin/vendors/status-options' => 'vendors#status_options'    
  get     '/admin/vendors/new'            => 'vendors#admin_new'
  get     '/admin/vendors/:id'            => 'vendors#admin_edit'
  get     '/admin/vendors'                => 'vendors#admin_index'
  post    '/admin/vendors/:id/image'      => 'vendors#admin_update_image'
  put     '/admin/vendors/:id'            => 'vendors#admin_update'
  post    '/admin/vendors'                => 'vendors#admin_add'
  delete  '/admin/vendors/:id'            => 'vendors#admin_delete'
    	
  #=============================================================================
  # API
  #=============================================================================
  
  get "/api/products"               => "products#api_index"
  get "/api/products/:id"           => "products#api_details"
  get "/api/products/:id/variants"  => "products#api_variants"  
  get "caboose/block-types"         => "block_types#api_block_type_list"
  get "caboose/block-types/:name"   => "block_types#api_block_type"
        
  #=============================================================================
  # Catch all
  #=============================================================================
  
  match '*path' => 'pages#show'
  root :to => 'pages#show'
  
end
