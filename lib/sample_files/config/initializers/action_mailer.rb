
# Action mailer settings
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: '<outgoing_mail_server>',    
  user_name: '<username>',
  password: '<password>',
  authentication: 'plain'
}
