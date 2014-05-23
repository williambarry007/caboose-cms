
# Salt to ensure passwords are encrypted securely
Caboose::salt = '79f15ebc0541f4942dc7fb5fa3a27fe96a255c12'

# Where page asset files will be uploaded
Caboose::assets_path = Rails.root.join('app', 'assets', 'caboose')

# Register any caboose plugins
Caboose::plugins << 'RepconnexPlugin'

Caboose::use_url_params = false

Caboose::website_name = "RepConnex"
Caboose::website_domain = "http://tampa.repconnex.com"
Caboose::cdn_domain = "//d3w3nonj6twazr.cloudfront.net"
Caboose::email_from = "contact@repconnex.com"
Caboose::authenticator_class = 'Authenticator'
Caboose::use_ab_testing = false
Caboose::session_length = 24 # hours
