module Caboose
  class LoginMailer < CabooseMailer #ActionMailer::Base

    def forgot_password_email(user)
      @user = user
      mail(:to => user.email, :subject => "#{Caboose::website_name} Forgot Password")
    end

    def locked_account(user)
      @user = user
      mail(:to => user.email, :subject => "#{Caboose::website_name} Locked Account")
    end    

  end
end
