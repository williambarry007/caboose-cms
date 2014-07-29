
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

end
