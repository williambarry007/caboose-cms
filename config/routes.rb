Caboose::Engine.routes.draw do
  
  get     "admin"                 => "admin#index"
  put     "admin/station"         => "station#index_admin"
  get     "station"               => "station#index"
  get     "station/plugin-count"  => "station#plugin_count"
  
  get "modal"      => "modal#layout"
  get "modal/:url" => "modal#index", :constraints => {:url => /.*/}
  
  get     "login/forgot-password"           => "login#forgot_password_form"
  post    "login/forgot-password"           => "login#send_reset_email"  
  get     "login/reset-password/:reset_id"  => "login#reset_password_form"
  post    "login/reset-password"            => "login#reset_password"  
  get     "login"                           => "login#index"
  post    "login"                           => "login#login"  
  get     "logout"                          => "logout#index"
  get     "register"                        => "register#index"
  post    "register"                        => "register#register"

  get     "my-account"                      => "users#my_account"
  put     "my-account"                      => "users#update_my_account"
  
  post    "admin/sites/:id/members"            => "sites#admin_add_member"
  delete  "admin/sites/:id/members/:user_id"   => "sites#admin_remove_member"
   
  post    "admin/sites/:site_id/domains"     => "domains#admin_add"
  put     "admin/sites/:site_id/domains/:id" => "domains#admin_update"
  delete  "admin/sites/:site_id/domains/:id" => "domains#admin_delete"
                                                                                                                                     
  get     "admin/sites/options"              => "sites#options"
  get     "admin/sites"                      => "sites#admin_index"    
  get     "admin/sites/new"                  => "sites#admin_new"  
  get     "admin/sites/:id"                  => "sites#admin_edit"  
  put     "admin/sites/:id"                  => "sites#admin_update"  
  post    "admin/sites"                      => "sites#admin_add"  
  delete  "admin/sites/:id"                  => "sites#admin_delete"
    
  get     "admin/redirects"      => "redirects#admin_index"    
  get     "admin/redirects/new"  => "redirects#admin_new"  
  get     "admin/redirects/:id"  => "redirects#admin_edit"  
  put     "admin/redirects/:id"  => "redirects#admin_update"  
  post    "admin/redirects"      => "redirects#admin_add"  
  delete  "admin/redirects/:id"  => "redirects#admin_delete"
  
  get     "admin/users"                     => "users#index"  
  get     "admin/users/options"             => "users#options"
  get     "admin/users/new"                 => "users#new"
  get     "admin/users/import"              => "users#import_form"
  post    "admin/users/import"              => "users#import"  
  get     "admin/users/:id/su"              => "users#admin_su"
  get     "admin/users/:id/edit-password"   => "users#edit_password"
  get     "admin/users/:id"                 => "users#edit"  
  put     "admin/users/:id"                 => "users#update"
  post    "admin/users"                     => "users#create"
  delete  "admin/users/:id"                 => "users#destroy"
  
  post    "admin/users/:id/roles/:role_id"  => "users#add_to_role"  
  delete  "admin/users/:id/roles/:role_id"  => "users#remove_from_role"
  
  get     "admin/roles"                   => "roles#index"
  get     "admin/roles/options"           => "roles#options"
  get     "admin/roles/new"               => "roles#new"
  get     "admin/roles/:id"               => "roles#edit"
  put     "admin/roles/:id"               => "roles#update"
  post    "admin/roles"                   => "roles#create"
  delete  "admin/roles/:id"               => "roles#destroy"
  
  post    "admin/roles/:id/permissions/:permission_id"  => "roles#add_permission"  
  delete  "admin/roles/:id/permissions/:permission_id"  => "roles#remove_permission"
  
  get     "admin/images"                => "images#admin_index"
  get     "admin/images/s3"             => "images#admin_sign_s3"
  get     "admin/images/s3-result"      => "images#admin_s3_result"  
  get     "admin/images/new"            => "images#admin_new"
  get     "admin/images/json"           => "images#admin_json"
  get     "admin/images/:id/process"    => "images#admin_process"
  get     "admin/images/:id/finished"   => "images#admin_process_finished"
  get     "admin/images/:id"            => "images#admin_edit"  
  put     "admin/images/:id"            => "images#admin_update"
  post    "admin/images/:id/image"      => "images#admin_update_image"  
  post    "admin/images"                => "images#admin_add"
  delete  "admin/images/:id"            => "images#admin_delete"
  
  post    "admin/media-categories"      => "media_categories#admin_add"
  put     "admin/media-categories/:id"  => "media_categories#admin_update"      
  delete  "admin/media-categories/:id"  => "media_categories#admin_delete"
  
  get     "admin/permissions"             => "permissions#index"
  get     "admin/permissions/options"     => "permissions#options"
  get     "admin/permissions/new"         => "permissions#new"
  get     "admin/permissions/:id"         => "permissions#edit"
  put     "admin/permissions/:id"         => "permissions#update"  
  post    "admin/permissions"             => "permissions#create"
  delete  "admin/permissions/:id"         => "permissions#destroy"
  
  get     "admin/settings"                => "settings#index"
  get     "admin/settings/options"        => "settings#options"
  get     "admin/settings/new"            => "settings#new"
  get     "admin/settings/:id"            => "settings#edit"
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
  get     "admin/pages/:id/block-options" => "pages#admin_block_options"
  get     "admin/pages/:id/uri"           => "pages#admin_page_uri"
  get     "admin/pages/:id/delete"        => "pages#admin_delete_form"  
  get     "admin/pages/:id/sitemap"       => "pages#admin_sitemap"  
  get     "admin/pages/:id/permissions"   => "pages#admin_edit_permissions"
  get     "admin/pages/:id/css"           => "pages#admin_edit_css"
  get     "admin/pages/:id/js"            => "pages#admin_edit_js"
  get     "admin/pages/:id/seo"           => "pages#admin_edit_seo" 
  get     "admin/pages/:id/block-order"   => "pages#admin_edit_block_order"
  put     "admin/pages/:id/block-order"   => "pages#admin_update_block_order"
  get     "admin/pages/:id/child-order"   => "pages#admin_edit_child_sort_order"
  put     "admin/pages/:id/child-order"   => "pages#admin_update_child_sort_order"
  get     "admin/pages/:id/new-blocks"    => "pages#admin_new_blocks"
  get     "admin/pages/:id/content"       => "pages#admin_edit_content"
  get     "admin/pages/:id/layout"        => "pages#admin_edit_layout"
  put     "admin/pages/:id/layout"        => "pages#admin_update_layout"
  put     "admin/pages/:id/viewers"       => "pages#admin_update_viewers"
  put     "admin/pages/:id/editors"       => "pages#admin_update_editors"
  get     "admin/pages/:id"               => "pages#admin_edit_general"  
  put     "admin/pages/:id"               => "pages#admin_update"
  get     "admin/pages"                   => "pages#admin_index"
  post    "admin/pages"                   => "pages#admin_create"  
  delete  "admin/pages/:id"               => "pages#admin_delete"
  
  post    "admin/page-permissions"        => "page_permissions#admin_add"  
  delete  "admin/page-permissions"        => "page_permissions#admin_delete"
  delete  "admin/page-permissions/:id"    => "page_permissions#admin_delete"  
    
  get     "admin/pages/:page_id/blocks/new"                  => "blocks#admin_new"  
  get     "admin/pages/:page_id/blocks/tree"                 => "blocks#admin_tree"
  get     "admin/pages/:page_id/blocks/render"               => "blocks#admin_render_all"
  get     "admin/pages/:page_id/blocks/render-second-level"  => "blocks#admin_render_second_level"
  get     "admin/pages/:page_id/blocks/:id/render"           => "blocks#admin_render"
  get     "admin/pages/:page_id/blocks/:id/tree"             => "blocks#admin_tree"
  get     "admin/pages/:page_id/blocks/:id/render"           => "blocks#admin_render"  
  get     "admin/pages/:page_id/blocks/:id/edit"             => "blocks#admin_edit"
  get     "admin/pages/:page_id/blocks/:id/advanced"         => "blocks#admin_edit_advanced"
  put     "admin/pages/:page_id/blocks/:id/move-up"          => "blocks#admin_move_up"
  put     "admin/pages/:page_id/blocks/:id/move-down"        => "blocks#admin_move_down"
  get     "admin/pages/:page_id/blocks/:id"                  => "blocks#admin_show"
  get     "admin/pages/:page_id/blocks"                      => "blocks#admin_index"  
  post    "admin/pages/:page_id/blocks"                      => "blocks#admin_create"
  get     "admin/pages/:page_id/blocks/:id/new"              => "blocks#admin_new"
  post    "admin/pages/:page_id/blocks/:id"                  => "blocks#admin_create"  
  put     "admin/pages/:page_id/blocks/:id"                  => "blocks#admin_update"
  delete  "admin/pages/:page_id/blocks/:id"                  => "blocks#admin_delete"
  
  put     "admin/pages/:page_id/blocks/:id"        => "blocks#admin_update"
  post    "admin/pages/:page_id/blocks/:id/image"  => "blocks#admin_update_image"
  post    "admin/pages/:page_id/blocks/:id/file"   => "blocks#admin_update_file"
  
  #put     "admin/blocks/:id"                       => "fields#admin_update"
  #post    "admin/blocks/:id/image"                 => "fields#admin_update_image"
  #post    "admin/blocks/:id/file"                  => "fields#admin_update_file"    
  
  get     "admin/block-types/store/sources"              => "block_type_sources#admin_index"
  get     "admin/block-types/store/sources/new"          => "block_type_sources#admin_new"
  get     "admin/block-types/store/sources/options"      => "block_type_sources#admin_options"
  get     "admin/block-types/store/sources/:id/edit"     => "block_type_sources#admin_edit"    
  get     "admin/block-types/store/sources/:id/refresh"  => "block_type_sources#admin_refresh"
  post    "admin/block-types/store/sources"              => "block_type_sources#admin_create"
  put     "admin/block-types/store/sources/:id"          => "block_type_sources#admin_update"
  delete  "admin/block-types/store/sources/:id"          => "block_type_sources#admin_delete"
  
  get     "admin/block-types/store/:block_type_summary_id/download"  => "block_type_store#admin_download"  
  get     "admin/block-types/store/:block_type_summary_id"           => "block_type_store#admin_details"  
  get     "admin/block-types/store"                                  => "block_type_store#admin_index"
      
  get     "admin/block-types/site-options"         => "block_types#admin_site_options"
  get     "admin/block-types/field-type-options"   => "block_types#admin_field_type_options"
  get     "admin/block-types/tree-options"         => "block_types#admin_tree_options"
  get     "admin/block-types/options"              => "block_types#admin_options"
  get     "admin/block-types/new"                  => "block_types#admin_new"
  get     "admin/block-types/json"                 => "block_types#admin_json"
  get     "admin/block-types/:id/json"             => "block_types#admin_json_single"  
  get     "admin/block-types/:id/new"              => "block_types#admin_new"
  get     "admin/block-types/:id/options"          => "block_types#admin_value_options"
  get     "admin/block-types/:id/icon"             => "block_types#admin_edit_icon"
  get     "admin/block-types/:id"                  => "block_types#admin_edit"            
  put     "admin/block-types/:id"                  => "block_types#admin_update"
  delete  "admin/block-types/:id"                  => "block_types#admin_delete"
  get     "admin/block-types"                      => "block_types#admin_index"
  post    "admin/block-types"                      => "block_types#admin_create"
  
  get     "admin/block-type-categories/tree-options" => "block_type_categories#admin_tree_options"
    
  get     "posts"                                 => "posts#index"
  get     "posts/:id"                             => "posts#detail"
  get     "admin/posts/category-options"          => "posts#admin_category_options"
  get     "admin/posts/new"                       => "posts#admin_new"
  get     "admin/posts/:id/delete"                => "posts#admin_delete_form"
  get     "admin/posts/:id/edit"                  => "posts#admin_edit_general"
  get     "admin/posts/:id/content"               => "posts#admin_edit_content"
  get     "admin/posts/:id/categories"            => "posts#admin_edit_categories"
  get     "admin/posts/:id/add-to-category"       => "posts#admin_add_to_category"
  get     "admin/posts/:id/remove-from-category"  => "posts#admin_remove_from_category"
  get     "admin/posts/:id/delete"                => "posts#admin_delete_form"
  put     "admin/posts/:id"                       => "posts#admin_update"
  post    "admin/posts/:id/image"                 => "posts#admin_update_image"
  get     "admin/posts"                           => "posts#admin_index"
  post    "admin/posts"                           => "posts#admin_add"  
  delete  "admin/posts/:id"                       => "posts#admin_delete"
  
  get     "admin/calendars"                         => "calendars#admin_index"
  get     "admin/calendars/:id"                     => "calendars#admin_edit"
  put     "admin/calendars/:id"                     => "calendars#admin_update"
  post    "admin/calendars"                         => "calendars#admin_add"
  delete  "admin/calendars"                         => "calendars#admin_delete"
  
  get     "admin/calendars/:calendar_id/events"     => "events#admin_index"
  get     "admin/calendars/:calendar_id/events/new" => "events#admin_new"
  get     "admin/calendars/:calendar_id/events/:id" => "events#admin_edit"
  put     "admin/calendars/:calendar_id/events/:id" => "events#admin_update"
  post    "admin/calendars/:calendar_id/events"     => "events#admin_add"
  delete  "admin/calendars/:calendar_id/events/:id" => "events#admin_delete"
  
  put     "admin/calendars/:calendar_id/event-groups/:id" => "event_groups#admin_update"
  get     "admin/event-groups/period-options"             => "event_groups#admin_period_options"
  get     "admin/event-groups/frequency-options"          => "event_groups#admin_frequency_options"
  get     "admin/event-groups/repeat-by-options"          => "event_groups#admin_repeat_by_options"

  get     "admin/ab-variants"                     => "ab_variants#admin_index"
  get     "admin/ab-variants/new"                 => "ab_variants#admin_new"
  get     "admin/ab-variants/:id"                 => "ab_variants#admin_edit"
  put     "admin/ab-variants/:id"                 => "ab_variants#admin_update"
  post    "admin/ab-variants"                     => "ab_variants#admin_create"  
  delete  "admin/ab-variants/:id"                 => "ab_variants#admin_delete"
  
  get     "admin/ab-variants/:variant_id/options" => "ab_options#admin_index"    
  put     "admin/ab-options/:id"                  => "ab_options#admin_update"
  post    "admin/ab-variants/:variant_id/options" => "ab_options#admin_create"
  delete  "admin/ab-options/:id"                  => "ab_options#admin_delete"
  
  # Cart  
  get    '/cart'            => 'cart#index'
  get    '/cart/items'      => 'cart#list'
  get    '/cart/item-count' => 'cart#item_count'
  post   '/cart/items'      => 'cart#add'
  put    '/cart/items/:id'  => 'cart#update'
  delete '/cart/items/:id'  => 'cart#remove'
  
  # Checkout  
  get  '/checkout'                 => 'checkout#index'
  get  '/checkout/step-one'        => 'checkout#step_one'
  get  '/checkout/step-two'        => 'checkout#step_two'
  get  '/checkout/step-three'      => 'checkout#step_three'
  get  '/checkout/step-four'       => 'checkout#step_four'
  get  '/checkout/thanks'          => 'checkout#thanks'
    
  put  '/checkout/address'         => 'checkout#update_address'
  post '/checkout/attach-user'     => 'checkout#attach_user'
  post '/checkout/attach-guest'    => 'checkout#attach_guest'  
  put  '/checkout/shipping'        => 'checkout#update_shipping'  
  get  '/checkout/relay/:order_id' => 'checkout#relay'
  post '/checkout/relay/:order_id' => 'checkout#relay'  
  get  '/checkout/empty'           => 'checkout#empty'
  
  # Products  
  get  '/products/:id/info' => 'products#info'
  get  '/products/:id'      => 'products#index', :constraints => { :id => /.*/ }
  get  '/products'          => 'products#index'

  post '/variants/find-by-options'   => 'variants#find_by_options'
  get  '/variants/:id/display-image' => 'variants#display_image'
  
  get '/admin/variants/group'        => 'variants#admin_group'
  
  get  '/admin/products/:id/variants/group'        => 'products#admin_group_variants'
  post '/admin/products/:id/variants/add'          => 'products#admin_add_variants'
  post '/admin/products/:id/variants/remove'       => 'products#admin_remove_variants'
  post '/admin/products/:id/variants/add-multiple' => 'products#admin_add_multiple_variants'
  
  get  '/admin/products/add-upcs' => 'products#admin_add_upcs'
  
  get  '/admin/vendors/status-options' => 'vendors#status_options'    
  get  '/admin/vendors/new'            => 'vendors#admin_new'
  get  '/admin/vendors/:id'            => 'vendors#admin_edit'
  put  '/admin/vendors/:id'            => 'vendors#admin_update'
  post '/admin/vendors'                => 'vendors#admin_add'  
  get  '/admin/vendors'                => 'vendors#admin_index'
  
  # Orders
  
  get  '/admin/orders/:id/void'                => 'orders#admin_void'
  get  '/admin/orders/:id/refund'              => 'orders#admin_refund'
  post '/admin/orders/:id/resend-confirmation' => 'orders#admin_resend_confirmation'
  
  post    "/reviews/add"                                => "reviews#add"  

  get     "/admin/products"                                 => "products#admin_index"
  get     "/admin/products/json"                            => "products#admin_json"
  get     '/admin/products/sort'                            => 'products#admin_sort'
  put     '/admin/products/update-sort-order'               => 'products#admin_update_sort_order'  
  put     "/admin/products/update-vendor-status/:id"        => "products#admin_update_vendor_status"
  get     "/admin/products/new"                             => "products#admin_new"
  get     "/admin/products/status-options"                  => "products#admin_status_options"    
  get     "/admin/products/:id/general"                     => "products#admin_edit_general"    
  get     "/admin/products/:id/description"                 => "products#admin_edit_description"
  get     "/admin/products/:id/categories"                  => "products#admin_edit_categories"
  post    "/admin/products/:id/categories"                  => "products#admin_add_to_category"
  delete  "/admin/products/:id/categories/:category_id"     => "products#admin_remove_from_category"
  get     "/admin/products/:id/variants"                    => "products#admin_edit_variants"
  get     "/admin/products/:id/variants/json"               => "products#admin_variants_json"
  get     "/admin/products/:id/variant-cols"                => "products#admin_edit_variant_columns"
  put     "/admin/products/:id/variant-cols"                => "products#admin_update_variant_columns"
  get     "/admin/products/:id/variants/sort-order"         => "products#admin_edit_variant_sort_order"
  put     '/admin/products/:id/variants/option1-sort-order' => 'products#admin_update_variant_option1_sort_order'
  put     '/admin/products/:id/variants/option2-sort-order' => 'products#admin_update_variant_option2_sort_order'
  put     '/admin/products/:id/variants/option3-sort-order' => 'products#admin_update_variant_option3_sort_order'
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
  
  get     "/admin/products/:product_id/variants/:variant_id/edit"   => "variants#admin_edit"
  get     "/admin/variants/status-options"            => "variants#admin_status_options"
  get     "/admin/variants/:variant_id/edit"          => "variants#admin_edit"
  put     "/admin/variants/:id/attach-to-image"       => "variants#admin_attach_to_image"
  put     "/admin/variants/:id/unattach-from-image"   => "variants#admin_unattach_from_image"
  put     "/admin/variants/:id"                       => "variants#admin_update"  
  get     "/admin/products/:id/variants/new"          => "variants#admin_new"  
  post    "/admin/products/:id/variants"              => "variants#admin_add"
  delete  "/admin/variants/:id"                       => "variants#admin_delete"
  
  get     "/admin/categories"                         => "categories#admin_index"
  get     "/admin/categories/new"                     => "categories#admin_new"
  get     "/admin/categories/options"                 => "categories#admin_options"  
  get     "/admin/categories/:id"                     => "categories#admin_edit"  
  put     "/admin/categories/:id"                     => "categories#admin_update"  
  get     '/admin/categories/status-options'          => 'categories#admin_status_options'
  post    "/admin/categories/:id"                     => "categories#admin_update"  
  post    "/admin/categories"                         => "categories#admin_add"
  delete  "/admin/categories/:id"                     => "categories#admin_delete"
  
  get     "/admin/product-images/:id/variant-ids"     => "product_images#admin_variant_ids"
  get     "/admin/product-images/:id/variants"        => "product_images#admin_variants"
  delete  "/admin/product-images/:id"                 => "product_images#admin_delete"
  get     "/variant-images/:id"                       => "product_images#variant_images"
  
  get     "/admin/orders"                             => "orders#admin_index"
  get     "/admin/orders/test-info"                   => "orders#admin_mail_test_info"
  get     "/admin/orders/test-gmail"                  => "orders#admin_mail_test_gmail"
  get     "/admin/orders/line-item-status-options"    => "orders#admin_line_item_status_options"
  get     "/admin/orders/status-options"              => "orders#admin_status_options"
  get     "/admin/orders/new"                         => "orders#admin_new"
  get     "/admin/orders/:id/capture"                 => "orders#capture_funds"  
  get     "/admin/orders/:id/json"                    => "orders#admin_json"
  get     "/admin/orders/:id/print"                   => "orders#admin_print"
  get     "/admin/orders/:id/send-to-quickbooks"      => "orders#admin_send_to_quickbooks"
  get     "/admin/orders/:id"                         => "orders#admin_edit"        
  put     "/admin/orders/:id"                         => "orders#admin_update"
  put     "/admin/orders/:order_id/line-items/:id"    => "orders#admin_update_line_item"
  delete  "/admin/orders/:id"                         => "orders#admin_delete"
	
  # API
  get "/api/products"               => "products#api_index"
  get "/api/products/:id"           => "products#api_details"
  get "/api/products/:id/variants"  => "products#api_variants"
  
  get "caboose/block-types"         => "block_types#api_block_type_list"
  get "caboose/block-types/:name"   => "block_types#api_block_type"
        
  match '*path' => 'pages#show'
  root :to => 'pages#show'
  
end
