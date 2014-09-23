
class Caboose::SmtpConfig < ActiveRecord::Base
  self.table_name = "smtp_configs"
       
  belongs_to :site      
  attr_accessible :id, 
    :site_id              ,
    :address              ,
    :port                 ,
    :domain               ,
    :user_name            ,
    :password             ,
    :authentication       ,
    :enable_starttls_auto


  AUTH_PLAIN = 'plain'
  AUTH_LOGIN = 'login'
  AUTH_MD5 = 'cram_md5'
  
  def self.configure_mailer_for_site(mailer, site_id)
    c = self.where(:site_id => site_id).first
    
    mailer.smtp_settings['user_name']            = c.user_name
    mailer.smtp_settings['password']             = c.password
    mailer.smtp_settings['address']              = c.address
    mailer.smtp_settings['port']                 = c.port
    mailer.smtp_settings['domain']               = c.domain
    mailer.smtp_settings['authentication']       = c.authentication
    mailer.smtp_settings['enable_starttls_auto'] = c.enable_starttls_auto
    
    return mailer
  end

end
