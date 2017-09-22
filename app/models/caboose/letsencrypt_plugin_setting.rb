module Caboose
  class LetsencryptPluginSetting < ActiveRecord::Base
    self.table_name = 'letsencrypt_plugin_settings'
    # t.text :private_key
  end
end
