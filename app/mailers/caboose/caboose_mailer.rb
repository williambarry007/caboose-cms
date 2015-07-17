module Caboose
  class CabooseMailer < ActionMailer::Base
    include AbstractController::Callbacks
    
    default :from => Caboose::email_from
    
    cattr_accessor :site
    @@site = nil
    
    before_filter do |mailer|
      config = SmtpConfig.where(:site_id => @@site.id).first    
      self.smtp_settings['user_name']            = config.user_name
      self.smtp_settings['password']             = config.password
      self.smtp_settings['address']              = config.address
      self.smtp_settings['port']                 = config.port
      self.smtp_settings['domain']               = config.domain
      self.smtp_settings['authentication']       = config.authentication
      self.smtp_settings['enable_starttls_auto'] = config.enable_starttls_auto
    end
    
  end
end
