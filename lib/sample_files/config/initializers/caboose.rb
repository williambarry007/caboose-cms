
# Salt to ensure passwords are encrypted securely
Caboose::salt = '|CABOOSE_SALT|'

# Where page asset files will be uploaded
Caboose::assets_path = Rails.root.join('app', 'assets', 'caboose')

# Register any caboose plugins
#Caboose::plugins << 'MyPlugin'

Caboose::use_url_params = false

Caboose::website_name = "|APP_NAME|"
Caboose::website_domain = "http://mywebsite.com"
Caboose::cdn_domain = "|CDN_URL|"
Caboose::email_from = "contact@mywebsite.com"
#Caboose::authenticator_class = 'Authenticator'
Caboose::use_ab_testing = false
Caboose::session_length = 24 # hours
