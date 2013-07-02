
var CabooseStation = function(m) {
  this.modal = m;
  this.init();
};

CabooseStation.prototype = {
  
  modal: false,
  
  init: function()
  {
    var this2 = this;
    // Handle main nav items with subnav
    $('#station > ul > li > a').click(function(event) {
      li = $(this).parent();
      if ($('ul', li).length > 0)
      {
        event.preventDefault();
        id = li.attr('id').replace('nav_item_', '');
        href = $(this).attr('href');
        this2.subnav(id, href);
      }
      else if ($(this).attr('rel') != 'modal')
      {
        event.preventDefault();
        parent.window.location = $(this).attr('href');
      }
    });
    $('#station ul li ul li a').click(function(event) {
      if ($(this).attr('rel') != 'modal')
      {
        event.preventDefault();
        parent.window.location = $(this).attr('href');
      }
    });
  },
  
  subnav: function(id, href)
  {
    this.modal.set_width(400);
    
    $('#station > ul > li').each(function(i, li) {
      id2 = $(li).attr('id').replace('nav_item_', '');
      if (id == id2)
        $(li).addClass('selected');
      else
        $(li).removeClass('selected');      
    });
    // Show only the selected subnav
    $('#station ul li ul').hide();
    $('#station ul li#nav_item_' + id + ' ul').show();
    
    // Set the height of the selected subnav
    var height = $('#station > ul').height();
    $('#station ul li#nav_item_' + id + ' ul').height(height);
  }  
};
