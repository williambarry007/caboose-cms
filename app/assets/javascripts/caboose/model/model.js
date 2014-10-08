
var Model = function(params) {
  for (var thing in params)
    this[thing] = params[thing];
  
  if (this.options_url)
  {
    for (var attrib in this.options_url)
      this.populate_options(this.options_url[attrib]);
  }
};

Model.prototype = {
  name: false,
  id: false,
  attributes: [],
  attributes_clean: [],
  update_url: false,
  fetch_url: false,
  options_url: false,
  options: false,
  
  save: function(attrib, after) {
    if (!attrib.update_url)
      attrib.update_url = this.update_url;
    attrib.save(after);        
  },
  
  populate_options: function(after, i) {
    if (i == null || i == undefined)
      i = 0;
    if (i >= this.attributes.length)
      after();
    var this2 = this;
    this.attributes[i].populate_options(function() { this2.populate_options(after, i+1); });
  }
};
