require 'httparty'

class Caboose::Site < ActiveRecord::Base
  self.table_name = "sites"

  has_many :block_type_site_memberships, :class_name => 'Caboose::BlockTypeSiteMembership', :dependent => :delete_all
  has_many :block_types, :through => :block_type_site_memberships
  has_many :site_memberships, :class_name => 'Caboose::SiteMembership', :dependent => :delete_all
  has_many :domains, :class_name => 'Caboose::Domain', :dependent => :delete_all
  has_many :fonts, :class_name => 'Caboose::Font', :dependent => :delete_all
  has_many :post_categories, :class_name => 'Caboose::PostCategory'
  has_one :store_config
  has_attached_file :logo, 
    :path => ':path_prefixsite_logos/:id_:style.:extension',    
    :default_url => 'http://placehold.it/300x300',    
    :styles => {
      :tiny  => '150x200>',
      :thumb => '300x400>',
      :large => '600x800>'
    }
  do_not_validate_attachment_file_type :logo
  attr_accessible :id, :name, :description, :under_construction_html
  
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
    url = "http://#{Caboose::cdn_domain}/assets/#{self.name}/js/custom.js"
    url << "?#{self.date_js_updated.strftime('%Y%m%d%H%M%S')}" if self.date_js_updated
    return url
  end
  
  def custom_css_url
    url = "http://#{Caboose::cdn_domain}/assets/#{self.name}/css/custom.css"
    url << "?#{self.date_css_updated.strftime('%Y%m%d%H%M%S')}" if self.date_css_updated
    return url
  end
    
  def custom_js              
    resp = HTTParty.get(self.custom_js_url)
    if resp.nil? || resp.code.to_i == 403
      self.custom_js = ""
      return ""            
    end
    return resp.body    
  end
  
  def custom_css    
    resp = HTTParty.get(self.custom_css_url)
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
    bucket.objects["assets/#{self.name}/js/custom.js"].write(str, :acl => 'public-read')                        
    self.date_js_updated = DateTime.now.utc
    self.save
  end
  
  def custom_css=(str)    
    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]
    AWS.config(:access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'])
    bucket =  AWS::S3.new.buckets[config['bucket']]                         
    bucket.objects["assets/#{self.name}/css/custom.css"].write(str, :acl => 'public-read')                        
    self.date_css_updated = DateTime.now.utc
    self.save
  end
  
  def init_users_and_roles
        
    admin_user = Caboose::User.where(:username => 'admin', :site_id => self.id).first    
    admin_user = Caboose::User.create(:username => 'admin', :email => 'admin@nine.is', :site_id => self.id, :password => Digest::SHA1.hexdigest(Caboose::salt + 'caboose')) if admin_user.nil?
                          
    admin_role = Caboose::Role.where(:site_id => self.id, :name => 'Admin').first    
    admin_role = Caboose::Role.create(:site_id => self.id, :parent_id => -1, :name => 'Admin') if admin_role.nil?
    
    elo_role = Caboose::Role.where(:site_id => self.id, :name => 'Everyone Logged Out').first
    elo_role = Caboose::Role.create(:site_id => self.id, :parent_id => -1, :name => 'Everyone Logged Out') if elo_role.nil?
    
    eli_role = Caboose::Role.where(:site_id => self.id, :name => 'Everyone Logged In').first
    eli_role = Caboose::Role.create(:site_id => self.id, :parent_id => elo_role.id, :name => 'Everyone Logged In') if eli_role.nil?
    
    # Make sure the admin role has the admin "all" permission
    admin_perm = Caboose::Permission.where(:resource => 'all', :action => 'all').first
    rp = Caboose::RolePermission.where(:role_id => admin_role.id, :permission_id => admin_perm.id).first
    rp = Caboose::RolePermission.create(:role_id => admin_role.id, :permission_id => admin_perm.id) if rp.nil?
    
    # Make sure the admin user is a member of the admin role
    rm = Caboose::RoleMembership.where(:role_id => admin_role.id, :user_id => admin_user.id).first
    rm = Caboose::RoleMembership.create(:role_id => admin_role.id, :user_id => admin_user.id) if rm.nil?
        
  end
  
end
