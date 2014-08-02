
class Caboose::Site < ActiveRecord::Base
  self.table_name = "sites"
       
  has_many :site_memberships, :class_name => 'Caboose::SiteMembership', :dependent => :delete_all
  has_many :domains, :class_name => 'Caboose::Domain', :dependent => :delete_all
  attr_accessible :id, :name, :description
  
  def smtp_config
    c = Caboose::SmtpConfig.where(:site_id => self.id).first
  end
  
  def self.id_for_domain(domain)
    d = Caboose::Domain.where(:domain => domain).first
    return nil if d.nil?
    return d.site_id
  end
  
end
