class Caboose::CorePlugin < Caboose::CaboosePlugin

  def self.admin_nav(nav, user, page, site)    
    return nav if user.nil?
        
    nav << { 'id' => 'logout'       , 'text' => 'Logout'     , 'href' => '/logout'     , 'modal' => false }    
    nav << { 'id' => 'my-account'   , 'text' => 'My Account' , 'href' => '/my-account' , 'modal' => true }
    
    item = { 'id' => 'core', 'text' => 'Settings', 'children' => [] }                        
    item['children'] << { 'id' => 'blocktypes'       , 'text' => 'AB Test Variants'    , 'href' => '/admin/ab-variants'        , 'modal' => false } if user.is_allowed('abvariants'   , 'view')    
    item['children'] << { 'id' => 'blocktypes'       , 'text' => 'Block Types'         , 'href' => '/admin/block-types'        , 'modal' => false } if user.is_allowed('blocktypes'   , 'view') if site.is_master == true
    item['children'] << { 'id' => 'fonts'            , 'text' => 'Fonts'               , 'href' => '/admin/fonts'              , 'modal' => false } if user.is_allowed('fonts'        , 'view') if site.use_fonts == true
    item['children'] << { 'id' => 'redirects'        , 'text' => 'Permanent Redirects' , 'href' => '/admin/redirects'          , 'modal' => false } if user.is_allowed('redirects'    , 'view')
    item['children'] << { 'id' => 'permissions'      , 'text' => 'Permissions'         , 'href' => '/admin/permissions'        , 'modal' => false } if user.is_allowed('permissions'  , 'view')   
    item['children'] << { 'id' => 'post_categories'  , 'text' => 'Post Categories'     , 'href' => '/admin/post-categories'    , 'modal' => false } if user.is_allowed('post_categories', 'view') 
    item['children'] << { 'id' => 'roles'            , 'text' => 'Roles'               , 'href' => '/admin/roles'              , 'modal' => false } if user.is_allowed('roles'        , 'view')
    item['children'] << { 'id' => 'sites'            , 'text' => 'Sites'               , 'href' => '/admin/sites'              , 'modal' => false } if user.is_allowed('sites'        , 'view') if site.is_master == true        
    item['children'] << { 'id' => 'smtp'             , 'text' => 'SMTP (Mail)'         , 'href' => '/admin/smtp'               , 'modal' => false } if user.is_allowed('smtp'         , 'view')
    item['children'] << { 'id' => 'social'           , 'text' => 'Social Media'        , 'href' => '/admin/social'             , 'modal' => false } if user.is_allowed('social'       , 'view')
    item['children'] << { 'id' => 'store'            , 'text' => 'Store'               , 'href' => '/admin/store'              , 'modal' => false } if user.is_allowed('store'        , 'view') if site.use_store == true
    item['children'] << { 'id' => 'users'            , 'text' => 'Users'               , 'href' => '/admin/users'              , 'modal' => false } if user.is_allowed('users'        , 'view')      
    item['children'] << { 'id' => 'variables'        , 'text' => 'Variables'           , 'href' => '/admin/settings'           , 'modal' => false } if user.is_allowed('settings'     , 'view')    
    nav << item if item['children'].count > 0
    
    item = { 'id' => 'content', 'text' => 'Content', 'children' => [] }    
    item['children'] << { 'id' => 'media'        , 'text' => 'Media'       , 'href' => '/admin/media'        , 'modal' => false } if user.is_allowed('media'       , 'view')
    item['children'] << { 'id' => 'pages'        , 'text' => 'Pages'       , 'href' => '/admin/pages'        , 'modal' => false } if user.is_allowed('pages'       , 'view')
    item['children'] << { 'id' => 'posts'        , 'text' => 'Posts'       , 'href' => '/admin/posts'        , 'modal' => false } if user.is_allowed('posts'       , 'view')
    item['children'] << { 'id' => 'calendars'    , 'text' => 'Calendars'   , 'href' => '/admin/calendars'    , 'modal' => false } if user.is_allowed('calendars'   , 'view')  
    nav << item if item['children'].count > 0
    
    if site.use_store      
      item = { 'id' => 'store', 'text' => 'Store', 'children' => [] }
      item['children'] << { 'id' => 'categories'       , 'href' => '/admin/categories'        , 'text' => 'Categories'        , 'modal' => false } if user.is_allowed('categories'       , 'view')
      item['children'] << { 'id' => 'giftcards'        , 'href' => '/admin/gift-cards'        , 'text' => 'Gift Cards'        , 'modal' => false } if user.is_allowed('giftcards'        , 'view')
      item['children'] << { 'id' => 'orders'           , 'href' => '/admin/orders'            , 'text' => 'Orders'            , 'modal' => false } if user.is_allowed('orders'           , 'view')
      item['children'] << { 'id' => 'products'         , 'href' => '/admin/products'          , 'text' => 'Products'          , 'modal' => false } if user.is_allowed('products'         , 'view')
      item['children'] << { 'id' => 'shippingpackages' , 'href' => '/admin/shipping-packages' , 'text' => 'Shipping Packages' , 'modal' => false } if user.is_allowed('shippingpackages' , 'view')
      item['children'] << { 'id' => 'vendors'          , 'href' => '/admin/vendors'           , 'text' => 'Vendors'           , 'modal' => false } if user.is_allowed('vendors'          , 'view')    
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

end
