
var S3 = function(params) {
  for (var thing in params)
    this[thing] = params[thing];    
};

S3.prototype = {
  bucket: '',
  access_key_id: '',      
  acl: 'public-read',
  policy: '',
  signature: '',
  key: ''
};
