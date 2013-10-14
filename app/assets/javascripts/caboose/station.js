
var CabooseStation = function(m, initial_tab) {
  this.init(m, initial_tab);
};

CabooseStation.prototype = {
 
  modal: false,
  
  init: function(m, initial_tab)
  {
    this.modal = m;
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
    if (initial_tab)
      $('#station > ul > li#nav_item_' + initial_tab + ' > a').trigger('click');
  },
  
  subnav: function(id, href)
  {
    //this.modal.set_width(400);
    
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
    var h = $('#station ul li.selected ul').outerHeight(true);
    var h2 = $('#station').outerHeight(true);
    if (h2 > h) h = h2    
    $('#station ul li#nav_item_' + id + ' ul').height(h);
        
    this.modal.resize(400, h);        
  }  
};
