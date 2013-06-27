
$(document).ready(function() {
    
  // Make the main nav open the subnav
  $('#station > ul > li > a').each(function(i, a) {
    var href = $(a).attr('href');
    $(a).click(function(event) {
      event.preventDefault();
      id = $(this).parent().attr('id').replace('nav_item_', '');
      caboose_subnav(id, href); 
    })
  });  
  
  // Make the subnav links take over the entire page instead of just the iframe
  $('#station ul li ul li a').each(function(i, a) {
    var href = $(a).attr('href');
    $(a).click(function(event) {
      event.preventDefault();
      parent.window.location = href;
    })
  });
  
});

function caboose_subnav(id, href)
{
  parent.$.fn.colorbox.resize({ innerHeight: plugin_count * 50, innerWidth: '400px' });
  
  $('#station > ul > li').each(function(i, li) {
    id2 = $(li).attr('id').replace('nav_item_', '');
    if (id == id2)
      $(li).addClass('selected');
    else
      $(li).removeClass('selected');      
  });
  
  $('#station ul li ul').hide();
  $('#station ul li#nav_item_' + id + ' ul').show();
  
  var height = $('#station > ul').height();
  $('#station ul li#nav_item_' + id + ' ul').height(height);
}
