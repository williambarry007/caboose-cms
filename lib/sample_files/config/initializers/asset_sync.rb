AssetSync.configure do |config| 
  config.fog_provider = 'AWS'
  config.fog_directory = '<bucket_name>'
  config.aws_access_key_id = '<s3_key_id>'
  config.aws_secret_access_key = '<s3_access_key>'  
  config.run_on_precompile = true 
end
