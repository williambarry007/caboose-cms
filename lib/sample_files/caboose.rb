#
# Caboose CMS Settings
#

# Salt to ensure passwords are encrypted securely
Caboose::salt = 'CHANGE THIS TO A UNIQUE STRING!!!'

# Where page asset files will be uploaded
Caboose::assets_path = Rails.root.join('app', 'assets', 'caboose')

# Register any caboose plugins
#Caboose::plugins + ['MyCaboosePlugin']
