
class Caboose::Site < ActiveRecord::Base
  self.table_name = "sites"

  has_many :block_type_site_memberships, :class_name => 'Caboose::BlockTypeSiteMembership', :dependent => :delete_all
  has_many :block_types, :through => :block_type_site_memberships
  has_many :site_memberships, :class_name => 'Caboose::SiteMembership', :dependent => :delete_all
  has_many :domains, :class_name => 'Caboose::Domain', :dependent => :delete_all
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
  
end
