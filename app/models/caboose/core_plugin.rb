class Caboose::CorePlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page, site)    
    return nav if user.nil?
        
  #  nav << { 'id' => 'logout'       , 'text' => 'Logout'     , 'href' => '/logout'     , 'modal' => false }    
  #  nav << { 'id' => 'my-account'   , 'text' => 'My Account' , 'href' => '/my-account' , 'modal' => true }
    item = { 'id' => 'content', 'text' => 'Content', 'children' => [] }    
    item['children'] << { 'id' => 'media'        , 'text' => 'Media'       , 'href' => '/admin/media'        , 'modal' => false } if user.is_allowed('media'       , 'view')
    item['children'] << { 'id' => 'pages'        , 'text' => 'Pages'       , 'href' => '/admin/pages'        , 'modal' => false } if user.is_allowed('pages'       , 'view')
    item['children'] << { 'id' => 'posts'        , 'text' => 'Posts'       , 'href' => '/admin/posts'        , 'modal' => false } if user.is_allowed('posts'       , 'view')
    item['children'] << { 'id' => 'calendars'    , 'text' => 'Calendars'   , 'href' => '/admin/calendars'    , 'modal' => false } if user.is_allowed('calendars'   , 'view')
    item['children'] << { 'icon' => 'box', 'id' => 'inbox'             , 'text' => 'Inbox'               , 'href' => '/admin/inbox'              , 'modal' => false } if user.is_allowed('contacts'             , 'view') && Caboose::FormSubmission.where(:site_id => site.id).count > 0
    nav << item if item['children'].count > 0
    
    item = { 'id' => 'core', 'text' => 'Settings', 'children' => [] }   
    item['children'] << { 'id' => 'settings'      , 'icon' => 'settings',        'text' => 'Site Settings'               , 'href' => "/admin/sites/#{site.id}"              , 'modal' => false } if user.is_super_admin?         
    item['children'] << { 'id' => 'theme-files'             , 'icon' => 'custom', 'text' => 'Theme Files'               , 'href' => '/admin/theme-files'              , 'modal' => false } if user.is_super_admin? && site.is_master == true                  
    item['children'] << { 'id' => 'blocktypes'        , 'text' => 'Block Types'         , 'href' => '/admin/block-types'        , 'modal' => false } if user.is_allowed('blocktypes'        , 'view') && site.is_master == true
    item['children'] << { 'icon' => 'star', 'id' => 'fonts'             , 'text' => 'Fonts'               , 'href' => '/admin/fonts'              , 'modal' => false } if user.is_allowed('fonts'             , 'view') && site.use_fonts == true
    item['children'] << { 'id' => 'redirects'         , 'text' => 'Permanent Redirects' , 'href' => '/admin/redirects'          , 'modal' => false } if user.is_allowed('redirects'         , 'view')
    item['children'] << { 'id' => 'permissions'       , 'text' => 'Permissions'         , 'href' => '/admin/permissions'        , 'modal' => false } if user.is_allowed('permissions'       , 'view') && site.is_master == true
    item['children'] << { 'id' => 'pagecustomfields'  , 'text' => 'Page Custom Fields'  , 'href' => '/admin/page-custom-fields' , 'modal' => false } if user.is_allowed('pagecustomfields'  , 'view')
    item['children'] << { 'id' => 'post_categories'   , 'text' => 'Post Categories'     , 'href' => '/admin/post-categories'    , 'modal' => false } if user.is_allowed('post_categories'   , 'view')
    item['children'] << { 'id' => 'postcustomfields'  , 'text' => 'Post Custom Fields'  , 'href' => '/admin/post-custom-fields' , 'modal' => false } if user.is_allowed('postcustomfields'  , 'view')
    item['children'] << { 'id' => 'roles'             , 'text' => 'Roles'               , 'href' => '/admin/roles'              , 'modal' => false } if user.is_allowed('roles'             , 'view')
    item['children'] << { 'id' => 'sites'             , 'text' => 'Sites'               , 'href' => '/admin/sites'              , 'modal' => false } if user.is_allowed('sites'             , 'view') && site.is_master == true        
    item['children'] << { 'icon' => 'pages', 'id' => 'templates'             , 'text' => 'Page Templates'               , 'href' => '/admin/templates'              , 'modal' => false } if user.is_allowed('templates'             , 'view') && site.is_master == true  
    item['children'] << { 'id' => 'smtp'              , 'text' => 'SMTP (Mail)'         , 'href' => '/admin/smtp'               , 'modal' => false } if user.is_allowed('smtp'              , 'view')
    item['children'] << { 'id' => 'social'            , 'text' => 'Social Media'        , 'href' => '/admin/social'             , 'modal' => false } if user.is_allowed('social'            , 'view')
    item['children'] << { 'id' => 'users'             , 'text' => 'Users'               , 'href' => '/admin/users'              , 'modal' => false } if user.is_allowed('users'             , 'view')
    item['children'] << { 'id' => 'code'              , 'icon' => 'stack', 'text' => 'Custom Code'         , 'href' => '/admin/code'               , 'modal' => false } if user.is_allowed('code'              , 'edit')
    item['children'] << { 'id' => 'contactinfo'      , 'icon' => 'plane', 'text' => 'Contact Information'         , 'href' => "/admin/sites/#{site.id}/contact"            , 'modal' => false } if user.is_allowed('contactinfo'              , 'edit')
    item['children'] << { 'id' => 'theme'      , 'icon' => 'sites',        'text' => 'Theme'               , 'href' => '/admin/theme'              , 'modal' => false } if user.is_allowed('theme'             , 'view') if !site.theme.nil? && user.is_super_admin?
   # item['children'] << { 'id' => 'variables'         , 'text' => 'Variables'           , 'href' => '/admin/settings'           , 'modal' => false } if user.is_allowed('settings'          , 'view')   
    item['children'] << { 'id' => 'my-account'             , 'text' => 'My Account'               , 'href' => '/my-account'              , 'modal' => false } 
    nav << item if item['children'].count > 0

    
    if site.use_store      
      item = { 'id' => 'store', 'text' => 'Store', 'children' => [] }
      item['children'] << { 'icon' => 'tags', 'id' => 'categories'       , 'href' => '/admin/categories'        , 'text' => 'Categories'        , 'modal' => false } if user.is_allowed('categories'       , 'view')
      item['children'] << { 'icon' => 'paper', 'id' => 'giftcards'        , 'href' => '/admin/gift-cards'        , 'text' => 'Gift Cards'        , 'modal' => false } if user.is_allowed('giftcards'        , 'view')
      item['children'] << { 'icon' => 'money', 'id' => 'invoices'         , 'href' => '/admin/invoices'          , 'text' => 'Invoices'          , 'modal' => false } if user.is_allowed('invoices'         , 'view')
      item['children'] << { 'icon' => 'store', 'id' => 'products'         , 'href' => '/admin/products'          , 'text' => 'Products'          , 'modal' => false } if user.is_allowed('products'         , 'view')
      item['children'] << { 'icon' => 'dropbox', 'id' => 'shippingpackages' , 'href' => '/admin/shipping-packages' , 'text' => 'Shipping Packages' , 'modal' => false } if user.is_allowed('shippingpackages' , 'view')
      item['children'] << { 'icon' => 'roles', 'id' => 'vendors'          , 'href' => '/admin/store/vendors'     , 'text' => 'Vendors'           , 'modal' => false } if user.is_allowed('vendors'          , 'view')    
      item['children'] << { 'icon' => 'reload', 'id' => 'subscriptions'     , 'text' => 'Subscriptions'       , 'href' => '/admin/subscriptions'      , 'modal' => false } if user.is_allowed('subscriptions'         , 'view')
      item['children'] << { 'icon' => 'settings', 'id' => 'store'             , 'text' => 'Store Settings'               , 'href' => '/admin/store'              , 'modal' => false } if user.is_allowed('store'             , 'view')
      nav << item if item['children'].count > 0
    end
                
    return nav
  end

  def self.block_types(block_types)
    block_types << {
      :id => 'heading',
      :name => "Heading",
      :attributes => [        
        { name: 'text' , nice_name: 'Text' , type: 'text'  , default: '', width: 800, fixed_placeholder: false },
        { name: 'size' , nice_name: 'Size' , type: 'select', default: 1, width: 800, fixed_placeholder: false, options: ["1 - Largest", "2", "3", "4", "5", "6"]}        
      ]
    }
    block_types << {
      :id => 'richtext',
      :name => "Rich Text",
      :attributes => [        
        { name: 'text' , nice_name: 'Text' , type: 'richtext', default: '', width: 800, height: 400, fixed_placeholder: false }                
      ]
    }
    return block_types
  end
  
  def self.global_js_assets(files)
    return files
  end
  
  def self.request_protocol(current_value, request)
    return current_value
  end
  
  def self.admin_user_tabs(tabs, user, site)
    return tabs    
  end

end
