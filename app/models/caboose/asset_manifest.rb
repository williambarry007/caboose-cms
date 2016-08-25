module Caboose
  class AssetManifest < ActiveRecord::Base
    self.table_name = "asset_manifests"  
    attr_accessible :id, :name

  end
end
