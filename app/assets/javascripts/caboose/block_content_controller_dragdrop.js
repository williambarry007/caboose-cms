 
var BlockContentController = function(params) { this.init(params); };

BlockContentController.prototype = {

  post_id: false,
  page_id: false,    
  new_block_type_id: false,
  selected_block_ids: [],
  blocks: false,
  assets_path: false,
  included_assets: false,
  mc: false,
  editing_block: false,
  inline_classes: ['rtedit'],
  
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
    that.add_dropzones();
    that.mc = new ModalController({ parent_controller: this, assets_path: that.assets_path });
    CKEDITOR.disableAutoInline = true;
    that.init_inline_editor();
 //   that.add_all_new_child_blocks();
  },

  edit_block: function(block_id) {
    var that = this;
    var url = that.base_url() + '/' + block_id + '/api-info';
    $.ajax({
      url: url,
      type: 'get',
      success: function(resp) {
        that.editing_block = block_id;
        that.show_edit_modal(block_id, resp.use_js_for_modal, resp.field_type, resp.block_name, resp.bt_name );
      }
    });
  },

  is_modified: function() {
    $("#tiny_header").removeClass('published').addClass('unpublished');
  },

  init_inline_editor: function() {
    var that = this;
    $.each(that.inline_classes, function(k1, c) {
      $.each($('.' + c), function(k2, b) {
       // var el = $(b).find('.value').first();
        if ( !$(b).hasClass('cke_editable') && $(b).closest("#the_modal").length == 0 ) {
  
          $(b).attr('contenteditable','true');
          var target_id = $(b).data('rtid');
          var editor = CKEDITOR.inline( $(b).attr('id') );

          var is_saved = true;

          editor.on('change', function(ev) {
            that.is_modified();
            $(b).css('background-color','#ffffd0').css('color','black');
            is_saved = false;
          });

          editor.on('blur', function(ev) {
            if ( !is_saved ) {
              $(b).find("span > span[contenteditable='false']").remove();
              var html = $(b).html();
              $.ajax({
                url: that.base_url() + '/' + target_id + '/value',
                type: 'put',
                data: { value: html },
                success: function(resp) { 
                  $(b).css('background-color','').css('color','');
                  is_saved = true;
                }
              });
            }
          });

          $(b).on('mouseleave', function(ev) {
            if ( !is_saved ) {
              $(b).find("span > span[contenteditable='false']").remove();
              var html = $(b).html();
              $.ajax({
                url: that.base_url() + '/' + target_id + '/value',
                type: 'put',
                data: { value: html },
                success: function(resp) { 
                  $(b).css('background-color','').css('color','');
                  is_saved = true;
                }
              });
            }
          });

        }
      });
    });
  },

  show_edit_modal: function(block_id, use_js_for_modal, field_type, bname, btname) {
    var that = this;
    var ft = field_type;
    var modal_controller = '';    
    if (use_js_for_modal == true) { modal_controller = bname ? bname : btname; }      
    else if (ft == 'image')          { modal_controller = 'media';    }
    else if (ft == 'file')           { modal_controller = 'media';    }
    else if (ft == 'richtext')       { modal_controller = 'richtext'; }
    else    { modal_controller = 'block';    }
    var filename = modal_controller == 'block' ? 'block_dd' : modal_controller;
    var new_modal_eval_string = "new " + that.underscores_to_camelcase(modal_controller) + "ModalController({ " +
      "  " + (that.page_id && that.page_id != null ? "page_id: " + that.page_id : "post_id: " + that.post_id) + ", " +
      "  block_id: " + block_id + ", " + 
      "  authenticity_token: '" + that.authenticity_token + "', " + 
      "  parent_controller: that, " +
      "  assets_path: '" + that.assets_path + "'" +
      "})";
    var js_file = 'caboose/block_modal_controllers/' + filename + '_modal_controller.js';
    if (!that.mc.asset_included(js_file))    
    {    
      $(document).on(modal_controller + '_modal_controller_loaded', function() { that.modal = eval(new_modal_eval_string); });
      that.mc.include_assets(js_file);                  
    }
    else // We're good, go ahead and instantiate
    {      
      that.modal = eval(new_modal_eval_string);
    }
  },
  
  underscores_to_camelcase: function(str)
  {
    var str2 = '';
    $.each(str.split('_'), function(j, word) { str2 += word.charAt(0).toUpperCase() + word.toLowerCase().slice(1); });
    return str2;
  },

  block_url: function(parent_id, b)
  {
    var that = this;    
    if (!b) return that.base_url() + '/' + parent_id;    
    return that.base_url(b) + '/' + b.id;     
  },

  render_block: function(block_id) {
    var that = this;
  //  console.log("rendering block " + block_id + "...");
    var url = that.base_url() + '/' + block_id + '/render';
    that.is_modified();
    $.ajax({
      url: url,
      type: 'get',
      success: function(html) {
        $('#block_' + block_id).replaceWith(html);
        that.is_loading(false, 'Loading...');
        that.add_dropzones();
        that.init_inline_editor();
      }
    });
  },

  add_block_to_page: function(block_id, block_type_id, parent_id, before_block_id, after_block_id) {
    var that = this;
    var new_div = $('<div />').attr('id','block_' + block_id);
    if (before_block_id)
      $('#block_' + before_block_id).before(new_div);
    else if (after_block_id)
      $('#block_' + after_block_id).after(new_div);
    else if (parent_id) {
      var el = $('#block_' + parent_id).find('.content_body').first();
      var first_parent_block = el.parents("[id^='block_']").first();
      if ( ('block_' + parent_id) == first_parent_block.attr('id') && el.children('.new_block_link.np').length > 0 ) {
        el.children('.new_block_link.np').remove();
        el.append(new_div);
      }
      else
        $('#block_' + parent_id).append(new_div);
    }
    that.render_block(block_id);
  },

  create_block: function(block_type_id, parent_id, before_block_id, after_block_id, child_block_count) {
    var that = this;
    that.is_loading(true, 'Creating block...');
    that.is_modified();
    var h = {                      
      authenticity_token: that.authenticity_token,
      block_type_id: block_type_id,
      before_id: before_block_id,
      after_id: after_block_id,
      child_count: child_block_count
    };
    $.ajax({
      url: that.block_url(parent_id, null),
      type: 'post',
      data: h,
      success: function(resp) {
        that.add_block_to_page(resp.new_id, block_type_id, parent_id, before_block_id, after_block_id);
      }
    });
  },

  is_loading: function(loading, message) {
    var that = this;
    if ( loading == true )
      $("#caboose-loading").fadeIn().find('h4').text(message);
    else
      $("#caboose-loading").fadeOut();
  },

  move_block: function(block_id, parent_id, before_block_id, after_block_id) {
    var that = this;
    var block_id = block_id.replace('block_','');
    that.is_modified();
    if ( before_block_id != block_id && after_block_id != block_id && parent_id != block_id ) {
      var original = $('#block_' + block_id);
      if ( original.data('ui-draggable') ) { original.draggable('destroy'); }
      var el = original.detach();
      el.removeClass('ui-draggable-dragging, block_over');
      el.css({'left':'auto','right':'auto','bottom':'auto','top':'auto','height':'auto','width':'auto'});
      if (before_block_id)
        $('#block_' + before_block_id).before(el);
      else if (after_block_id)
        $('#block_' + after_block_id).after(el);
      else if (parent_id) {
        var el2 = $('#block_' + parent_id).find('.content_body').first();
        var first_parent_block = el2.parents("[id^='block_']").first();
        if ( ('block_' + parent_id) == first_parent_block.attr('id') && el2.children('.new_block_link.np').length > 0 ) {
          el2.children('.new_block_link.np').remove();
          el2.append(el);
        }
        else
          $('#block_' + parent_id).append(el);
      }
      if ( el.data('height') ) { el.css('height', el.data('height')); }
      if ( el.data('width') ) { el.css('width', el.data('width')); }
      that.move_block_save(block_id, parent_id, before_block_id, after_block_id);
    }
  },

  move_block_save: function(block_id, parent_id, before_block_id, after_block_id) {
    var that = this;
    var block_id = block_id.replace('block_','');
    var h = {                      
      authenticity_token: that.authenticity_token,
      parent_id: parent_id,
      before_id: before_block_id,
      after_id: after_block_id
    };
    $.ajax({
      url: that.base_url() + '/' + block_id + '/move',
      type: 'post',
      data: h,
      success: function(resp) { that.add_dropzones(); }
    });
  },
  
  select_block: function(block_id)
  {            
    i = this.selected_block_ids.indexOf(block_id);
    if (i == -1) // Not there
    {
      this.selected_block_ids.push(block_id);
      $('#block_' + block_id).addClass('selected');
    }
    else
    {
      this.selected_block_ids.splice(i, 1);
      $('#block_' + block_id).removeClass('selected');
    }    
  },
  
  delete_block: function(block_id, confirm)
  {
    var that = this;
    if (this.selected_block_ids.indexOf(block_id) == -1)
      this.selected_block_ids.push(block_id);
    var other_count = this.selected_block_ids.length - 1;
    if (!confirm)
    {
      var message = "Are you sure you want to delete this block";      
      if (other_count > 0)
        message += " and the " + other_count + " other selected block" + (other_count == 1 ? '' : 's');
      message += "?<br />";
      var p = $('<p/>')
        .addClass('caboose_note delete')
        .append(message)
        .append($('<input/>').attr('type', 'button').val('Yes').click(function(e) { e.preventDefault(); e.stopPropagation(); that.delete_block(block_id, true); })).append(" ")
        .append($('<input/>').attr('type', 'button').val('No').click(function(e) { e.preventDefault(); e.stopPropagation(); that.render_block(block_id); }));
      $('#block_' + block_id).attr('onclick','').unbind('click');
      $('#block_' + block_id).empty().append(p);
      return;
    }
    else {
      $.each( this.selected_block_ids, function(k1,v1) {
        $('#block_' + v1).remove();
        that.delete_block_save(v1);
      });
      that.selected_block_ids = [];
      that.add_dropzones();
      that.is_modified();
    }
  },

  delete_block_save: function(block_id) {
    var that = this;
    $.ajax({
      url: that.base_url() + '/' + block_id,
      type: 'delete',
      async: false,
      success: function(resp) {}
    });
  },

  duplicate_block: function(block_id)
  {
    var that = this;
    var el = $('#block_' + block_id).clone();
    el.find("[id^='handle_']").remove();
    var fake_id = 'db' + Math.floor((Math.random() * 1000) + 1);
    el.attr('id','new_block_' + fake_id).addClass('duplicated-block');
    $('#block_' + block_id).after(el);
    that.is_modified();
    that.duplicate_block_save(block_id, fake_id);
  },

  duplicate_block_save: function(block_id, fake_id) {
    var that = this;
    $.ajax({
      url: that.base_url() + '/' + block_id + '/duplicate',
      type: 'put',
      success: function(resp) {        
        $('.duplicated-block#new_block_' + fake_id).attr('id','block_' + resp.new_id).removeClass('duplicated-block');
    //    that.add_dropzones();
        that.render_block(resp.new_id);
      }
    });
  },

  /*****************************************************************************
  Block Rendering
  *****************************************************************************/
  
  render_parent_blocks: function(block_id) {
    var that = this;
 //   console.log("rendering parent blocks for " + block_id + "...");
    $.ajax({
      url: that.base_url() + '/' + block_id + '/parent-block',
      type: 'get',
      success: function(resp) {
   //     console.log(resp);
        if ( resp && resp.parent_id ) { that.render_block(resp.parent_id) };
        if ( resp && resp.grandparent_id ) { that.render_block(resp.grandparent_id) };
      }
    });
  },

  render_blocks: function(before_render) 
  {
    var that = this;
    if ( that.editing_block ) {
 //     console.log("rendering blocks for " + that.editing_block + "...");
      that.render_block( that.editing_block );
      that.render_parent_blocks( that.editing_block );
    }
  },                                                                                                                               

  add_dropzones: function() {
    var that = this;
    $('.new_block_link').remove();
    $("[id^='block_']").each(function(k,v) {

      var is_unit = $(v).hasClass('flex-grid-unit');
      var is_grid = $(v).hasClass('flex-grid-container');
      var bid = $(v).attr('id').replace('block_','');
      var dropclass = (is_unit && is_unit == true ? 'column-dropper' : 'regular-dropper');

      // empty post, page, column, grid, or text area
      if ( $(v).find('.content_body').length > 0 && $(v).find('.content_body').first().children().length == 0 ) {
        var msg = (is_grid && is_grid == true ? '<p>Empty grid. Drag a column here.</p>' : '<p>Empty content area. Drag blocks here.</p>');
        var el = $(v).find('.content_body').first();
        if ( $(v).find('.flexbox').length > 0 && $(v).find('.flexbox').first().children().length == 0 )
          $(v).addClass('empty');
        var first_parent_block = el.parents("[id^='block_']").first();
        if ( first_parent_block.attr('id') == $(v).attr('id') ) {
          el.html($('<div/>')
            .addClass('new_block_link np ' + (is_grid && is_grid == true ? 'column-dropper' : 'regular-dropper'))
            .append($('<div/>').addClass('new-page line').html(msg).droppable({
              accept: (is_grid && is_grid == true ? '.flex-grid-unit' : ':not(.flex-grid-unit)'),
              hoverClass: "highlight",
              tolerance: "pointer",
              drop: function(event, ui) {
                if ( ui.draggable.attr('id') && ui.draggable.attr('id').indexOf('block_') == 0 )
                  that.move_block(ui.draggable.attr('id'), bid, null, null);
                else
                  that.create_block(ui.draggable.data('btid'), bid, null, null, ui.draggable.data('children'));
              }
            }))
          );
        }
      }

      // child block of content area
      if ( $(v).closest('.content_body').length > 0 ) {
        var parent_id = $(v).parents("[id^='block_']").first().attr('id').replace('block_','');
        var is_last_child = $(v).next("[id^='block_']").length == 0 ? true : false;
        $(v).before($('<div/>')          
          .addClass('new_block_link ' + dropclass)
          .append($('<div/>').addClass('line').droppable({
            accept: (is_unit && is_unit == true ? '.flex-grid-unit' : ':not(.flex-grid-unit)'),
            hoverClass: "highlight",
            tolerance: "pointer",
            drop: function(event, ui) {
              if ( ui.draggable.attr('id') && ui.draggable.attr('id').indexOf('block_') == 0 )
                that.move_block(ui.draggable.attr('id'), parent_id, bid, null);
              else
                that.create_block(ui.draggable.data('btid'), parent_id, bid, null, ui.draggable.data('children'));
            }
          }))
        );
        if (is_last_child && is_last_child == true) {
          $(v).after($('<div/>')          
            .addClass('new_block_link ' + dropclass).addClass(dropclass)
            .append($('<div/>').addClass('line').droppable({
              accept: (is_unit && is_unit == true ? ".flex-grid-unit" : ':not(.flex-grid-unit)'),
              hoverClass: "highlight",
              tolerance: "pointer",
              drop: function(event, ui) {
                if ( ui.draggable.attr('id') && ui.draggable.attr('id').indexOf('block_') == 0 )
                  that.move_block(ui.draggable.attr('id'), parent_id, null, bid);
                else
                  that.create_block(ui.draggable.data('btid'), parent_id, null, bid, ui.draggable.data('children'));
              }
            }))
          );
        }
      }

      if ( !$(v).hasClass('header') && !$(v).hasClass('content_wrapper') && !$(v).hasClass('footer') && !$(v).hasClass('header-wrapper') && !$(v).hasClass('footer-wrapper') ) {
        $(v).draggable( {
          handle: ".drag_handle",
          revert: "invalid",
          scroll: false,
          zIndex: 999,
          start: function(event, ui) { $((is_unit && is_unit == true ? '.column-dropper' : '.regular-dropper') + " .line.ui-droppable").addClass('dropzone'); },
          stop: function(event, ui) { $((is_unit && is_unit == true ? '.column-dropper' : '.regular-dropper') + " .line.ui-droppable").removeClass('dropzone'); }
        });
      }

      that.add_handles_to_block(bid);

      $(".flex-grid-container").each(function(k, v) {
        var h = $(v).outerHeight();
        $(v).find(".flexbox > .new_block_link .line").css('height',h);
      });

    });

  },

  // add_all_new_child_blocks: function() {
  //   var that = this;
  //   $.each( $('.content_body'), function(k,v) {
  //     var el = $(v).parents("[id^='block_']").first();
  //     that.add_new_child_blocks(el.attr('id').replace('block_',''));
  //   });
  // },

  // get NEW child blocks of this block
 //  add_new_child_blocks: function(block_id) {
 // //   console.log('adding new child blocks for ' + block_id);
 //    var that = this;
 //    $.ajax({
 //      url: that.base_url() + '/' + block_id + '/new-child-blocks',
 //      type: 'get',
 //      success: function(resp) {        
 //        if ( resp && resp.blocks && resp.blocks.length > 0 ) {

 //          $.each(resp.blocks, function(k,v) {

 //        //    console.dir(v);

 //            // render each of them
 //            var url = that.base_url() + '/' + v.id + '/render';
 //            $.ajax({
 //              url: url,
 //              data: {
 //                is_new: 'yes'
 //              },
 //              type: 'get',
 //              success: function(html) {
 //            //    console.log(html);

 //                if ( $('#block_' + block_id).find('.content_body').first().find('.new_block_link.np').length > 0 ) {
 //                  $('#block_' + block_id).find('.content_body').first().html('');
 //                }

 //                $('#block_' + block_id).find('.content_body').first().append(html);

 //                that.add_handles_to_block(v.id);
 //              }
 //            });

 //          });

 //          that.add_dropzones();
 //          that.init_inline_editor();

 //        }
 //      }
 //    });
 //  },

  add_handles_to_block: function(block_id) {
    var that = this;
    var el = $('#block_' + block_id);
    if (el.length > 0 && block_id.indexOf('constrain') < 0 && block_id.indexOf('full_width') < 0 && block_id.indexOf('_value_') < 0) {
      if ( el.attr('id').indexOf('_value') >= 0 || el.children('.drag_handle').length > 0 )
        return true;
      if ( el.parents('.content_body').length > 0 ) {
        $('#block_' + block_id + ' *').attr('onclick', '').unbind('click');
        el.prepend($('<a/>').attr('id', 'handle_block_' + block_id + '_drag'      ).addClass('drag_handle'      ).append($('<span/>').addClass('ui-icon ui-icon-arrow-4'    )).click(function(e) { e.preventDefault(); e.stopPropagation();  }))
          .prepend($('<a/>').attr('id', 'handle_block_' + block_id + '_select'    ).addClass('select_handle'    ).append($('<span/>').addClass('ui-icon ui-icon-check'      )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.select_block(block_id);    }))
          .prepend($('<a/>').attr('id', 'handle_block_' + block_id + '_duplicate' ).addClass('duplicate_handle' ).append($('<span/>').addClass('ui-icon ui-icon-copy'       )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.duplicate_block(block_id); }))
          .prepend($('<a/>').attr('id', 'handle_block_' + block_id + '_delete'    ).addClass('delete_handle'    ).append($('<span/>').addClass('ui-icon ui-icon-close'      )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.delete_block(block_id);    }));
        el.mouseover(function(el) { $('#block_' + block_id).addClass(   'block_over'); });
        el.mouseout(function(el)  { $('#block_' + block_id).removeClass('block_over'); });
        if ( el.hasClass('hasrt') )
          el.prepend($('<a/>').attr('id', 'handle_block_' + block_id + '_settings'    ).addClass('settings_handle'    ).append($('<span/>').addClass('ui-icon ui-icon-gear'      )).click(function(e) { e.preventDefault(); e.stopPropagation(); that.edit_block(block_id);    }));
      }
      el.attr('onclick','').unbind('click');
      if ( el.hasClass('footer-wrapper') && el.prev('.content_wrapper.subpage').length > 0 ) {
        el.css('position','relative');
        var over = $('<div />').attr('id','footer-msg').text('The footer must be edited on the homepage.').css('position','absolute').css('left','0').css('top','0').css('background','rgba(43, 43, 43, 0.9)').css('color','white').css('width','100%').css('height','100%').css('z-index','14').css('padding','40px 3% 40px 3%').css('text-align','center');
        if ( el.find('#footer-msg').length == 0 ) { el.append(over); }
      }
      else if ( !el.hasClass('container') ) { 
        el.click(function(e) {      
          e.preventDefault();
          e.stopPropagation();
          if ( el.hasClass('rtedit') || $(e.target).closest(".rtedit").length > 0 || el.hasClass('content_wrapper') )
            return;
          else
            that.edit_block(block_id);
        });
      }
    }


    // el.attr('onclick','').unbind('click');
    // el.click(function(e) {      
    //   e.preventDefault();
    //   e.stopPropagation();
    //   if ( el.hasClass('rtedit') )
    //     return;
    //   else
    //     that.edit_block(block_id);
    // });

  },
  
  /*****************************************************************************
  Helper methods
  *****************************************************************************/
  
  base_url: function()
  {
    var that = this;
    return '/admin/' + (that.page_id && that.page_id != null ? 'pages/' + that.page_id : 'posts/' + that.post_id) + '/blocks';        
  }    
};
