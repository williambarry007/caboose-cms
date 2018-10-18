
BoundImage = BoundControl.extend({

  //el: false,
  //model: false,
  //attribute: false,
  //binder: false,
  
  width: 100,
  style: 'medium',
  authenticity_token: false,
 
  init: function(params) {
    for (var thing in params)
      this[thing] = params[thing];
    
    this.el = this.el ? this.el : this.model.name.toLowerCase() + '_' + this.model.id + '_' + this.attribute.name;
    
    if (!this.attribute.update_url)
      this.attribute.update_url = this.model.update_url;

    var awidth = this.attribute.width ? this.attribute.width : this.width;
         
    var this2 = this;
    $('#'+this.el).wrap($('<div/>')
      .attr('id', this.el + '_container')
      .addClass('mb_container model-image')
      .css('position', 'relative')
    );
    $('#'+this.el+'_container').empty();
    
    $('#'+this.el+'_container').append( $("<div/>").addClass('img-holder').css('float','left').css('width',awidth).css('margin-right',10).append($('<img/>')
      .attr('src', this.attribute.value).css('display','block').css('max-width','100%')
    ));    
    $('#'+this.el+'_container')
      .append($('<form target="' + this.el + '_iframe"></form>')
        .attr('id', this.el + '_form')
        .attr('action', this.attribute.update_url)
        .attr('method', 'post')
        .attr('enctype', 'multipart/form-data')
        .attr('encoding', 'multipart/form-data')
        //.attr('target', this.el + '_iframe')
        .on('submit', function() {           
           $('#'+this2.el+'_message').html("<p class='loading'>Uploading...</p>");
           $('#'+this2.el+'_iframe').on('load', function() { this2.post_upload(); });
           return true;
        })
        .append($('<input/>').attr('type', 'hidden').attr('name', 'authenticity_token').val(this.binder.authenticity_token))        
        .append($('<div/>')
          .attr('id', this.el + '_fake_file_input')
          .addClass('mb_fake_file_input')          
          .append($('<input/>')            
            .attr('type', 'button')
            .attr('id', this.el + '_update_button')
            .val('Update ' + this.attribute.nice_name)
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
        )
      );
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
    else
    {
      if (this.attribute.image_refresh_delay)
      {
        var that = this;
        setTimeout(function() { that.refresh_image(); }, this.attribute.image_refresh_delay);
      }
      else
      {
        this.refresh_image();
      }        
    }
  },
  
  refresh_image: function() {
    var src = this.attribute.value;
    if (src.indexOf('?') > 0)
      src = src.split('?')[0];    
    src = src + '?' + Math.random();    
    $('#'+this.el+'_container img').attr('src', src);
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
