
var S3 = function(params) {
  for (var thing in params)
    this[thing] = params[thing];    
};

S3.prototype = {    
  access_key_id: '',
  secret_access_key: '',
    
  acl: 'public-read',
  key: '',
  policy: '',
  signature: '',
  redirect: ''
      
  access_key_id: '', // AWSAccessKeyId	
  acl: 'public-read',
  bucket: '',	
  key: '',
  policy: '',
  redirect: '', // success_action_redirect	
  signature: '',
  security_token: '', // x-amz-security-token
  file	

};


