module Caboose
  class LoginMailer < CabooseMailer #ActionMailer::Base

    def forgot_password_email(user)
      @user = user
      mail(:to => user.email, :subject => "#{user.site.description} Forgot Password")
    end

    def locked_account(user)
      @user = user
      admin_email = user.site.contact_email
      mail(:to => admin_email, :subject => "#{user.site.description} Locked Account") if !admin_email.blank?
    end

  end
end