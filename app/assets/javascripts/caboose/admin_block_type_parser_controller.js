
var AdminBlockTypeParserController = function(params) { this.init(params); };

AdminBlockTypeParserController.prototype = {
  
  container: 'block_type_parser',
  authenticity_token: false,
  //original_html: "<div data-num='30' data-thumb='assets/minimalist-basic/thumbnails/p02.png' data-cat='0,13'>\n  <div class='row clearfix'>\n    <div class='column half'>\n      <div class='display'>\n        <h1>Beautiful content. Responsive.</h1>\n        <p>Lorem Ipsum is simply dummy text.</p>\n        <div style='margin:1em 0 2.5em;'>\n          <a href='#' class='btn btn-primary edit'>Read More</a>\n        </div>\n      </div>\n    </div>\n    <div class='column half'>\n      <img src='assets/minimalist-basic/p02-1.jpg'>\n    </div>\n  </div>\n</div>\n",
  //original_html: "<div data-num='1' data-thumb='assets/minimalist-basic/thumbnails/a01.png' data-cat='1'>\n  <div class='row clearfix'>\n    <div class='column full'>\n      <h1 class='size-96 is-title1-96 is-title-lite'>Lorem Ipsum</h1>\n    </div>\n  </div>\n</div>\n",
  //original_html: "" +
  //  "<div data-num='30' data-thumb='assets/minimalist-basic/thumbnails/p02.png' data-cat='0,13'>\n" +
  //  "  <div class='row clearfix'>\n" +
  //  "    <div class='column half'>\n" +
  //  "      <div class='display'>\n" +
  //  "        <h1>Beautiful content. Responsive.</h1>\n" +
  //  "        <p>Lorem Ipsum is simply dummy text.</p>\n" +
  //  "        <div style='margin:1em 0 2.5em;'>\n" +
  //  "          <a href='#' class='btn btn-primary edit'>Read More</a>\n" +
  //  "        </div>\n" +
  //  "      </div>\n" +
  //  "    </div>\n" +
  //  "    <div class='column half'>\n" +
  //  "      <img src='assets/minimalist-basic/p02-1.jpg'>\n" +
  //  "    </div>\n" +
  //  "	</div>\n" +
  //  "</div>\n",
  original_html: "",
  parsable_tags: { heading: 'Headings' , richtext: 'Rich Text' , img: 'Images' , link: 'Links' },
  tags_to_parse: { heading: true       , richtext: true        , img: true     , link: true    },
  render_function: false,
  children: false,
  
  init: function(params) {
    var that = this;
    for (var i in params)
      this[i] = params[i];
    
    that.html_form();   
  },
  
  html_form: function()
  {
    var that = this;
        
    var tr = $('<tr/>');
    var all_checked = true;
    $.each(that.parsable_tags, function(tag, name) { if (!that.tags_to_parse[tag]) { all_checked = false; return false; }});    
    tr.append($('<td/>').append($('<input/>').attr('type', 'checkbox').attr('id', 'all').prop('checked', all_checked).click(function() {
        var checked = $(this).is(':checked');
        $.each(that.parsable_tags, function(tag, name) { $('#'+tag).prop('checked', checked); });                 
      })))      
      .append($('<td/>').append($('<label/>').attr('for', 'all').append('All')));        
    $.each(that.parsable_tags, function(tag, name) {      
      tr.append($('<td/>').append($('<input/>').attr('type', 'checkbox').attr('id', tag).val('1').prop('checked', that.tags_to_parse[tag])))
        .append($('<td/>').append($('<label/>').attr('for', tag).append(name)));
    });
    var tags_table = $('<table/>').append($('<tbody/>').append(tr));
                
    var div = $('<div/>')      
      .append(tags_table)
      .append($('<p/>').append($('<textarea/>').attr('id', 'html').css('width', '90%').css('height', '400px').attr('placeholder', 'HTML or JSON to Parse').html(that.original_html)))            
      .append($('<div/>').attr('id', 'message'))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val("Parse as HTML").click(function() {
          that.original_html = $('#html').val();
          $.each(that.parsable_tags, function(tag, name) { that.tags_to_parse[tag] = $('#'+tag).is(':checked'); }); 
          that.parse_html(function() { that.render_function_form(); }); 
        })).append(' ')        
        .append($('<input/>').attr('type', 'button').val("Parse as JSON"     ).click(function() {          
          var resp = false;              
          try { resp = JSON.parse($('#html').val()); }
          catch (ex) {
            $('#message').html("<p class='note error'>There was an error parsing the JSON. It doesn't appear to be valid.</p>");
            return;
          }
          that.last_response   = resp;              
          that.original_html   = resp.original_html;
          that.render_function = resp.render_function;
          that.children        = resp.children;
          that.render_function_form();
        }))                              
      );                  
    $('#'+that.container).empty().append(div);    
  },
  
  parse_html: function(callback)
  {
    var that = this;   
    if (!that.original_html || that.original_html.trim().length == 0)
    {
      $('#message').html("<p class='note error'>HTML to parse can't be empty.</p>");
      return;
    }
        
    var tags = [];
    $.each(that.tags_to_parse, function(tag, checked) { if (checked) tags.push(tag); });
    $.ajax({
      url: '/admin/block-types/parse-tags',
      type: 'post',
      data: {
        html: that.original_html,
        tags: tags,
        children: that.children
      },
      success: function(resp) {
        that.last_response = resp;              
        that.original_html   = resp.original_html;
        that.render_function = resp.render_function;
        that.children        = resp.children;
      },
      async: false
    });
    if (callback)
      callback();
  },
  
  render_function_form: function()
  {
    var that = this;    
    var tbody = $('<tbody/>')
      .append($('<tr/>')
        .append($('<th/>').append('Name'))                
        .append($('<th/>').append('Description'))        
        .append($('<th/>').append('Default Value'))
        .append($('<th/>').append('Field Type'))
      );      
      
    var field_types = {
      heading:  'Heading',   
      image2:   'Image',
      button:   'Link',
      richtext: 'Rich Text'
    };            
    $.each(that.children, function(i, v) {
      
      tbody.append($('<tr/>')
        .append($('<td/>').append($('<input/>').data('i', i).val(v.name        ).on('keyup', function(e) { var x = $(this).val().toLowerCase().replace(' ', '_'); $(this).val(x); that.children[parseInt($(this).data('i'))].name        = x; })))                
        .append($('<td/>').append($('<input/>').data('i', i).val(v.description ).on('keyup', function(e) { that.children[parseInt($(this).data('i'))].description = $(this).val(); })))        
        .append($('<td/>').append($('<input/>').data('i', i).val(v.default     ).on('keyup', function(e) { that.children[parseInt($(this).data('i'))].default     = $(this).val(); })))
        .append($('<td/>').append(field_types[v.field_type]))
      );
        
      if (v.child_values)
      {
        $.each(v.child_values, function(k,v) {
          tbody.append($('<tr/>')
            .append($('<td/>').append(' - ' + k))
            .append($('<td/>').html("&nbsp;"))                        
            .append($('<td/>').append($('<input/>').data('i', i).data('k', k).val(v).on('keyup', function(e) { that.children[parseInt($(this).data('i'))].child_values[$(this).data('k')] = $(this).val(); })))
            .append($('<td/>').html("&nbsp;"))
          )
        });
      }      
    });                
    var vars_table = $('<table/>').append(tbody);
              
    $('#'+that.container).empty()
      .append($('<h2/>').append("Variables"))
      .append(vars_table)
      .append($('<h2/>').append("Render Function"))
      .append($('<textarea/>').attr('id', 'parsed').css('width', '90%').css('height', '200px').html(that.render_function))
      .append($('<h2/>').append("JSON"))
      .append($('<p/>').append('Copy to save for future use.'))
      .append($('<textarea/>').attr('id', 'json'  ).css('width', '90%').css('height', '100px').html(JSON.stringify(that.last_response)))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val("< Back to HTML").click(function() { that.html_form(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val("Re-parse HTML with Updated Variables" ).click(function() { that.parse_html(function() { that.render_function_form(); }); })).append(' ')
      );
  }            
};



