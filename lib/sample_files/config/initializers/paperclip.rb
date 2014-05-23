|APP_NAME|::Application.configure do  
  # Paperclip config for S3 assets
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_credentials => {
      :bucket => '|S3_BUCKET_NAME|',
      :access_key_id => '|S3_ACCESS_KEY_ID|',
      :secret_access_key => '|S3_SECRET_ACCESS_KEY|'
    },
    :url => ':s3_alias_url',
    :s3_host_alias => '|CDN_URL|'    
  }
end