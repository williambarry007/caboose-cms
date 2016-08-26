module Caboose
  class AssetManifest < ActiveRecord::Base
    self.table_name = "asset_manifests"  
    attr_accessible :id, :name
    
    #def save_asset(path, value)
    #  resp = StdClass.new
    #  
    #  config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]                      
    #  AWS.config({ :access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'] })
    #  bucket = AWS::S3::Bucket.new(config['bucket'])                      
    #  obj = bucket.objects[path]
    #  
    #  return { :error => "Can't find file."     } if obj.nil?
    #  return { :error => "Can't write to file." } if !obj.write(value)
    #  
    #  # Compile the new file      
    #  dest = "#{Rails.root}/vendor/assets/javascripts/compiled/"
    #  filename = path.split('/').pop
    #  ext = filename.split('.').pop
    #  File.write(dest + js_asset, Uglifier.compile(Rails.application.assets.find_asset(js_asset).to_s))
    #
    #end
      

  end
end
