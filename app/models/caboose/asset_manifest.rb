module Caboose
  class AssetManifest
    
    #def AssetManifest.bucket
    #  if @@bucket.nil?        
    #    config = YAML.load(File.read(Rails.root.join('config', 'aws.yml')))[Rails.env]                      
    #    AWS.config({ :access_key_id => config['access_key_id'], :secret_access_key => config['secret_access_key'] })
    #    @@bucket = AWS::S3::Bucket.new(config['bucket'])
    #  end
    #  return @@bucket
    #end
    #    
    #def AssetManifest.save_asset(path, str, reset = true)
    #
    #  file = self.bucket.objects[path]      
    #  return { :error => "Can't find file." } if file.nil?
    #                        
    #  # Save the contents into the source file
    #  return { :error => "Can't write to file." } if !file.write(str)
    #  
    #  # Compile the file
    #  str_compiled = Uglifier.compile(str)
    #  
    #  # Compute the digest for the compiled file            
    #  digest = Digest::SHA2.hexdigest(str_compiled)
    #  
    #  # See if the digest file for the compiled file exists
    #  digest_path = self.path_with_digest(path, digest)
    #  if self.bucket.objects[digest_path].exists?
    #    digest_file = bucket.objects[digest_path]
    #    digest_file.write(str_compiled)
    #  end
    #  
    #  # See if the digest is in the manifest
    #  manifest = self.bucket.objects['assets/manifest.yml']
    #  changed = false
    #  new_lines = []
    #  manifest.read.split("\n").each do|line|
    #    if line.starts_with?("#{path}: ") && line != "#{path}: #{digest_path}"
    #      new_lines << "#{path}: #{digest_path}"
    #      changed = true
    #    else
    #      new_lines << line
    #    end
    #  end
    #  
    #  # If the digest has changed, update the manifest and set the app asset digests
    #  if changed
    #    manifest.write(new_lines.join("\n"))        
    #    self.reset_asset_digests(new_lines) if reset
    #  end
    #  
    #  return { :sucess => true }
    #end
    #
    #def AssetManifest.reset_asset_digests(lines = nil)
    #  lines = self.bucket.objects['assets/manifest.yml'].read.split("\n") if lines.nil?       
    #  lines.each do|line|                  
    #    arr = line.split(": ")                    
    #    Rails.application.config.assets.digests[arr[0]] = arr[1]                
    #  end            
    #end
    #
    #def AssetManifest.path_with_digest(path, digest)
    #  arr = path.split('/')
    #  filename = arr.pop
    #  filename = filename.split('.')
    #  ext = filename.pop
    #  filename = "#{filename.join('.')}-#{digest}.#{ext}"
    #  return filename if arr.count == 0
    #  return "#{arr.join('/')}/#{filename}"
    #end

  end
end
