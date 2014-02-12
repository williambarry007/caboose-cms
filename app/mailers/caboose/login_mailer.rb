module Caboose
  class LoginMailer < ActionMailer::Base
    default :from => Caboose::email_from
            
    def forgot_password_email(user)
      @user = user
      mail(:to => user.email, :subject => "#{Caboose::website_name} Forgot Password")
    end    
  end
end
