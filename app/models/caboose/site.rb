require 'httparty'

class Caboose::Site < ActiveRecord::Base
  self.table_name = "sites"

  has_many :block_type_site_memberships, :class_name => 'Caboose::BlockTypeSiteMembership', :dependent => :delete_all
  has_many :block_types, :through => :block_type_site_memberships
  has_many :site_memberships, :class_name => 'Caboose::SiteMembership', :dependent => :delete_all
  has_many :domains, :class_name => 'Caboose::Domain', :dependent => :delete_all
  has_many :fonts, :class_name => 'Caboose::Font', :dependent => :delete_all
  has_many :post_categories, :class_name => 'Caboose::PostCategory'
  has_one  :store_config

  has_attached_file :logo, 
    :path => ':caboose_prefixsite_logos/:id_:style.:extension',    
    :default_url => 'http://placehold.it/300x300',    
    :styles => {
      :tiny  => '150x200>',
      :thumb => '300x400>',
      :large => '600x800>'
    }
  do_not_validate_attachment_file_type :logo

  has_attached_file :favicon, 
    :path => ':caboose_prefixfavicons/:id_:style.:extension',    
    :default_url => 'https://assets.caboosecms.com/site_logos/ninefavicon.png',    
    :styles => {
      :tiny  => '100x100>',
      :thumb => '300x300>'
    }
  do_not_validate_attachment_file_type :favicon

  attr_accessible :id        ,         
    :name                    ,
    :description             ,
    :under_construction_html ,
    :use_store               ,
    :use_fonts               ,
    :logo                    ,
    :is_master               ,
    :allow_self_registration ,
    :analytics_id            ,
    :use_retargeting         ,
    :use_dragdrop            ,
    :date_js_updated         ,
    :date_css_updated        ,
    :default_layout_id       ,
    :login_fail_lock_count   ,
    :sitemap_xml             ,
    :robots_txt              ,
    :theme_color             ,
    :assets_url              ,
    :theme_id                ,
    :cl_logo_version         ,
    :cl_favicon_version      
            
  before_save :validate_presence_of_store_config

  def theme
    Caboose::Theme.where(:id => self.theme_id).first
  end

  def update_cloudinary_logo
    if Caboose::use_cloudinary
      result = Cloudinary::Uploader.upload("https:#{self.logo.url(:large)}" , :public_id => "caboose/site_logos/#{self.id}_large", :overwrite => true)
      self.cl_logo_version = result['version'] if result && result['version']
      self.save
    end
  end

  def update_cloudinary_favicon
    if Caboose::use_cloudinary
      result = Cloudinary::Uploader.upload("https:#{self.favicon.url(:thumb)}" , :public_id => "caboose/favicons/#{self.id}_thumb", :overwrite => true)
      self.cl_favicon_version = result['version'] if result && result['version']
      self.save
    end
  end

  def build_new_site
   # if defined?(SuiteBuilder) == 'constant' && SuiteBuilder.class == Class  
      helper = Caboose::SiteBuilder.new(self.name)
      helper.create_site_blocks(self.id)
   # end
  #  self.init_users_and_roles
  end
  
  def validate_presence_of_store_config
    if self.use_store && !Caboose::StoreConfig.where(:site_id => self.id).exists?
      Caboose::StoreConfig.create(:site_id => self.id)
    end
  end
  
  def default_layout    
    return Caboose::BlockType.where(:id => self.default_layout_id).first if self.default_layout_id
    return Caboose::BlockType.where(:name => 'layout_basic').first
  end
  
  def smtp_config
    c = Caboose::SmtpConfig.where(:site_id => self.id).first
    c = Caboose::SmtpConfig.create(:site_id => self.id) if c.nil?
    return c
  end

  def social_config
    s = Caboose::SocialConfig.where(:site_id => self.id).first
    s = Caboose::SocialConfig.create(:site_id => self.id) if s.nil?
    return s
  end
  
  def retargeting_config
    c = Caboose::RetargetingConfig.where(:site_id => self.id).first
    c = Caboose::RetargetingConfig.create(:site_id => self.id) if c.nil?      
    return c      
  end
  
  def product_default
    pd = Caboose::ProductDefault.where(:site_id => self.id).first
    pd = Caboose::ProductDefault.create(:site_id => self.id) if pd.nil?
    return pd    
  end
  
  def variant_default
    vd = Caboose::VariantDefault.where(:site_id => self.id).first
    vd = Caboose::VariantDefault.create(:site_id => self.id) if vd.nil?
    return vd
  end
  
  def self.id_for_domain(domain)
    d = Caboose::Domain.where(:domain => domain).first
    return nil if d.nil?
    return d.site_id
  end
  
  def self.sanitize_name(name)
    self.name = self.name.downcase.gsub(' ', '_')
  end
  
  def primary_domain
    Caboose::Domain.where(:site_id => self.id, :primary => true).first
  end
  
  def custom_js_url
    url = "//#{Caboose::cdn_domain}/assets/#{self.name}/js/custom.js"
    url << "?#{self.date_js_updated.strftime('%Y%m%d%H%M%S')}" if self.date_js_updated
    return url
  end
  
  def custom_css_url
    url = "//#{Caboose::cdn_domain}/assets/#{self.name}/css/custom.css"
    url << "?#{self.date_css_updated.strftime('%Y%m%d%H%M%S')}" if self.date_css_updated
    return url
  end
    
  def custom_js
    resp = HTTParty.get('https:' + self.custom_js_url)
    if resp.nil? || resp.code.to_i == 403
      self.custom_js = ""
      return ""            
    end
    return resp.body    
  end
  
  def custom_css    
    resp = HTTParty.get('https:' + self.custom_css_url)
    if resp.nil? || resp.code.to_i == 403
      self.custom_css = ""
      return ""            
    end
    return resp.body    
  end
  
  def custom_js=(str)    
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
    AWS.config(:access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'])
    bucket =  AWS::S3.new.buckets[config['bucket']]                         
    bucket.objects["assets/#{self.name}/js/custom.js"].write(str, :acl => 'public-read', :content_type => 'application/javascript')                        
    self.date_js_updated = DateTime.now.utc
    self.save
  end
  
  def custom_css=(str)    
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
    AWS.config(:access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'])
    bucket =  AWS::S3.new.buckets[config['bucket']]                         
    bucket.objects["assets/#{self.name}/css/custom.css"].write(str, :acl => 'public-read', :content_type => 'text/css')                        
    self.date_css_updated = DateTime.now.utc
    self.save
  end
  
  def init_users_and_roles
        
    admin_user = Caboose::User.where( :site_id => self.id, :username => 'admin').first    
    admin_user = Caboose::User.create(:site_id => self.id, :username => 'admin', :email => 'admin@nine.is', :password => Digest::SHA1.hexdigest(Caboose::salt + 'caboose')) if admin_user.nil?                          
    admin_role = Caboose::Role.where( :site_id => self.id, :name => 'Admin').first    
    admin_role = Caboose::Role.create(:site_id => self.id, :parent_id => -1, :name => 'Admin') if admin_role.nil?    
    elo_user   = Caboose::User.where( :site_id => self.id, :username => 'elo').first    
    elo_user   = Caboose::User.create(:site_id => self.id, :username => 'elo', :email => 'elo@nine.is') if elo_user.nil?    
    elo_role   = Caboose::Role.where( :site_id => self.id, :name => 'Everyone Logged Out').first
    elo_role   = Caboose::Role.create(:site_id => self.id, :name => 'Everyone Logged Out', :parent_id => -1) if elo_role.nil?    
    eli_user   = Caboose::User.where( :site_id => self.id, :username => 'eli').first    
    eli_user   = Caboose::User.create(:site_id => self.id, :username => 'eli', :email => 'eli@nine.is') if eli_user.nil?    
    eli_role   = Caboose::Role.where( :site_id => self.id, :name => 'Everyone Logged In').first
    eli_role   = Caboose::Role.create(:site_id => self.id, :name => 'Everyone Logged In', :parent_id => elo_role.id) if eli_role.nil?
    
    # Make sure the admin role has the admin "all" permission
    admin_perm = Caboose::Permission.where(:resource => 'all', :action => 'all').first
    rp = Caboose::RolePermission.where(:role_id => admin_role.id, :permission_id => admin_perm.id).first
    rp = Caboose::RolePermission.create(:role_id => admin_role.id, :permission_id => admin_perm.id) if rp.nil?
    
    # Make sure the admin user is a member of the admin role
    rm = Caboose::RoleMembership.where(:role_id => admin_role.id, :user_id => admin_user.id).first
    rm = Caboose::RoleMembership.create(:role_id => admin_role.id, :user_id => admin_user.id) if rm.nil?
    
    # Make sure the elo user is a member of the elo role
    rm = Caboose::RoleMembership.where( :role_id => elo_role.id, :user_id => elo_user.id).first
    rm = Caboose::RoleMembership.create(:role_id => elo_role.id, :user_id => elo_user.id) if rm.nil?
    
    # Make sure the eli user is a member of the eli role
    rm = Caboose::RoleMembership.where( :role_id => eli_role.id, :user_id => eli_user.id).first
    rm = Caboose::RoleMembership.create(:role_id => eli_role.id, :user_id => eli_user.id) if rm.nil?
        
  end
  
end
