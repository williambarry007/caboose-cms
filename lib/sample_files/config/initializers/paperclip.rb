# Paperclip config for S3 assets
config.paperclip_defaults = {
  :storage => :s3,
  :s3_credentials => {
    :bucket => '<s3_bucket_name>',
    :access_key_id => '<s3_key_id>',
    :secret_access_key => '<s3_access_key>'
  },
  :url => ':s3_alias_url',
  :s3_host_alias => '<cloudfront_url>'
}
