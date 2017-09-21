module Caboose
  class LetsencryptPluginChallenge < ActiveRecord::Base
    self.table_name = 'letsencrypt_plugin_challenges'
    # t.text :response
  end
end
