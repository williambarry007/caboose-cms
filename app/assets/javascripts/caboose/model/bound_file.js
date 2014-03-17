
BoundFile = BoundControl.extend({
  
  width: 100,
  authenticity_token: false,
  placeholder: false,
 
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
    
    if (!this.attribute.update_url)
      this.attribute.update_url = this.model.update_url;
    this.placeholder = this.el + '_placeholder';
         
    var this2 = this;
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .addClass('mb_container')
      .addClass('mb_file_container')      
    );
    $('#'+this.el+'_container').empty();
    
    $('#'+this.el+'_container')
      .append($('<form target="' + this.el + '_iframe"></form>')
        .addClass('mb_file_form')
        .attr('id', this.el + '_form')        
        .attr('action', this.attribute.update_url)
        .attr('method', 'post')
        .attr('enctype', 'multipart/form-data')
        .attr('encoding', 'multipart/form-data')
        .on('submit', function() {           
           $('#'+this2.el+'_message').html("<p class='loading'>Uploading...</p>");
           $('#'+this2.el+'_iframe').on('load', function() { this2.post_upload(); });
           return true;
        })
      );
    
    if (this.attribute.fixed_placeholder == true)
    {
      $('#'+this.el+'_form').append($('<div/>')        
        .attr('id', this.placeholder)
        .addClass('mb_placeholder')          
        .append($('<span/>').html(this.attribute.nice_name + ': '))
      );
    }
        
    $('#'+this.el+'_form')      
      .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(this.binder.authenticity_token))        
      .append($('<div/>')
        .attr('id', this.el + '_fake_file_input')
        .addClass('mb_fake_file_input')          
        .append($('<input/>')            
          .attr('type', 'button')
          .attr('id', this.el + '_update_button')
          .val(this.attribute.upload_text ? this.attribute.upload_text : 'Update ' + this.attribute.nice_name)
          .click(function() { $('#'+this2.el+'_file').click(); })
        )
        .append($('<input/>')
          .attr('type', 'file')
          .attr('id', this.el + '_file')
          .attr('name', this.attribute.name)            
          .change(function() { $('#'+this2.el+'_form').trigger('submit'); })
        )
        .append($('<input/>')
          .attr('type', 'submit')            
          .val('Submit')
        )
      );
      
    if (this.attribute.value && this.attribute.value != '/files/original/missing.png')
    {
      $('#'+this.el+'_form').append($('<input/>')            
        .attr('type', 'button')
        .attr('id', this.el + '_download_button')
        .val(this.attribute.download_text ? this.attribute.download_text : 'Download current file')
        .click(function() { window.open(this2.timestamped_link(), '_blank'); })
      );
    }

    $('#'+this.el+'_container').append($('<div/>')
      .attr('id', this.el + '_message')
    );
    iframe = $("<iframe name=\"" + this.el + "_iframe\" id=\"" + this.el + "_iframe\" src=''></iframe>");          
    if (this.attribute.debug)      
      iframe.css('width', '100%').css('height', 600).css('background', '#fff');
    else
      iframe.css('width', 0).css('height', 0).css('border', 0);         
    $('#'+this.el+'_container').append(iframe);    
    $('#'+this.el+'_container').append($('<br/>').css('clear', 'both'));
        
    var w = $('#' + this.el + '_update_button').outerWidth(true);
    $('#' + this.el + '_fake_file_input').css('width', '' + w + 'px');                                           
  },
  
  post_upload: function() {
    $('#'+this.el+'_message').empty();
    
    var str = frames[this.el+'_iframe'].document.documentElement.innerHTML;
    str = str.replace(/[\s\S]*?{([\s\S]*?)/, '{$1');
    str = str.substr(0, str.lastIndexOf('}')+1);
    
    var resp = $.parseJSON(str);    
    if (resp.success)
		{
		  if (resp.attributes && resp.attributes[this.attribute.name])
		    for (var thing in resp.attributes[this.attribute.name])
		      this.attribute[thing] = resp.attributes[this.attribute.name][thing];
		  this.attribute.value_clean = this.attribute.value;		  		  
		}
				
    if (resp.error)
      this.error(resp.error);    
  },
    
  timestamped_link: function() {
    var href = this.attribute.value;
    if (href.indexOf('?') > 0)
      href = href.split('?')[0];    
    href = href + '?' + Math.random();
    return href;
  },
  
  error: function(str) {
    if (!$('#'+this.el+'_message').length)
    {
      $('#'+this.el+'_container').append($('<div/>')
        .attr('id', this.el + '_message')
        .css('width', $('#'+this.el).outerWidth())
      );
    }
    $('#'+this.el+'_message').hide();
    $('#'+this.el+'_message').html("<p class='note error'>" + str + "</p>");
    $('#'+this.el+'_message').slideDown();
    var this2 = this;
    setTimeout(function() { $('#'+this2.el+'_message').slideUp(function() { $(this).empty(); }); }, 3000);
  }
  
});
