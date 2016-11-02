
var AdminCalendarController = Class.extend({
    
  calendar: false,
  calendar_id: false,
  events: false,
  current_month: false,
  container: 'calendar_container',

  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
    that.current_month = new Date();
    that.refresh(function() { 
      that.refresh_events(function() {
        that.print();
      });
    });
  },
  
  refresh: function(callback)  
  {
    var that = this;        
    $.ajax({
      url: '/admin/calendars/' + that.calendar_id + '/json',
      type: 'get',      
      success: function(resp) { 
        that.calendar = resp;        
        if (callback) callback();
      }      
    });
  },
  
  refresh_events: function(callback)  
  {
    var that = this;        
    $.ajax({
      url: '/admin/calendars/' + that.calendar_id + '/events/json',
      type: 'get',
      data: { month: that.current_month.getMonth()+1, year: that.current_month.getFullYear() },      
      success: function(resp) {
        that.events = resp;
        if (callback) callback();
      }      
    });
  },
  
  refresh_events_and_print: function()
  {
    var that = this;
    that.refresh_events(function() { that.print(); });
  },
    
  print: function()
  { 
    var that = this;
    var div = $('<div/>')
      .append($('<p/>').append($('<div/>').attr('id', 'calendar_' + that.calendar_id + '_name'        )))
      .append($('<p/>').append($('<div/>').attr('id', 'calendar_' + that.calendar_id + '_color'       )))
      .append($('<p/>').append($('<div/>').attr('id', 'calendar_' + that.calendar_id + '_description' )))
      .append(that.calendar_div())      
      .append($('<div/>').attr('id', 'message'))
      .append($('<div/>').attr('id', 'controls')
        .append($('<input/>').attr('type', 'button').val('Back'            ).click(function() { window.location='/admin/calendars'; })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Delete Calendar' ).click(function() { that.delete_calendar(); }))
      )
      .append($('<br/>'));
    $('#'+that.container).empty().append(div);
    
    new ModelBinder({
      name: 'Calendar',
      id: that.calendar_id,
      update_url: '/admin/calendars/' + that.calendar_id,
      authenticity_token: that.authenticity_token,
      attributes: [
        { name: 'name'        , nice_name: 'Name'        , type: 'text'     , value: that.calendar.name        , width: 400 },
        { name: 'description' , nice_name: 'Description' , type: 'textarea' , value: that.calendar.description , width: 400, height: 100 },
        { name: 'color'       , nice_name: 'Color'       , type: 'color'    , value: that.calendar.color       , width: 400, height: 100 }  
      ]    
    });
  },
  
  events_for_day: function(d)
  {
    var that = this;
    var ul = $('<ul/>');
    var count = 0;
    $.each(that.events, function(i, ev) {
      bd = new Date(ev.begin_date);
      ed = new Date(ev.end_date);
      if (bd.getDate() == d.getDate() || ed.getDate() == d.getDate())
      {        
        ul.append($('<li/>').append($('<a/>').attr('href', '#').addClass('event_link').html(ev.name).data('event_id', ev.id).click(function(e) {
          e.preventDefault();
          e.stopPropagation();
          that.edit_calendar_event($(this).data('event_id'));                         
        })));
        count++;
      }              
    });
    return count > 0 ? ul : '';    
  },
  
  calendar_div: function()
  {
    var that = this;
    var days_in_previous_month = new Date(that.current_month.getFullYear(), that.current_month.getMonth(), 0).getDate();            
    var days_in_month          = new Date(that.current_month.getFullYear(), that.current_month.getMonth()+1, 0).getDate();
    var start_day              = new Date(that.current_month.getFullYear(), that.current_month.getMonth(), 1).getDay();
        
    var tbody = $('<tbody/>');
    var tr = $('<tr/>');
    for (var i=0; i<start_day; i++)
      tr.append($('<td/>').addClass('blank').append($('<span/>').addClass('day').append(days_in_previous_month - (start_day - i - 1))));
    
    var day = 1;
    while (day <= days_in_month)
    {
      //var d = new Date(that.current_month.getFullYear(), that.current_month.getMonth(), that.current_month.getDate() - 1);
      var d = new Date(that.current_month.getFullYear(), that.current_month.getMonth(), day);
      var F = iso8601_date(d);
        
      if ((day + start_day - 1) % 7 == 0)
      {
        tbody.append(tr);
        if (day < days_in_month)
          tr = $('<tr/>');
      }
      tr.append($('<td/>').attr('id', 'day_' + F).data('F', F)
        .mouseover(function(e) { $(this).addClass('over'); })
        .mouseout(function(e) { $(this).removeClass('over'); })
        .click(function(e) { e.preventDefault(); e.stopPropagation(); if (!$(this).hasClass('blank')) { that.new_calendar_event($(this).data('F')); }})
        .append($('<span/>').addClass('day').append(day))
        .append(that.events_for_day(d))
      );
      day++;
    }    
    last_day = (start_day + days_in_month) % 7
    var remaining_days = 7 - last_day    
    if (last_day > 0)
    {
      for (var i=0; i<remaining_days; i++)
        tr.append($('<td/>').addClass('blank').append($('<span/>').addClass('day').append(i + 1)));
    }
    if ((start_day + days_in_month) != 0)
      tbody.append(tr);
    
    tr = $('<tr/>');
    $.each(['Sun','Mon','Tue','Wed','Thu','Fri','Sat'], function(i, day) { tr.append($('<th/>').append(day)); });
    
    var div = $('<div/>').attr('id', 'calendar')
      .append($('<h2/>').append(month_name(that.current_month) + ' ' + that.current_month.getFullYear()))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('< Previous Month' ).click(function() { that.current_month.setMonth(that.current_month.getMonth()-1); that.refresh_events_and_print(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Current Month'    ).click(function() { that.current_month = new Date();                              that.refresh_events_and_print(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Next Month >'     ).click(function() { that.current_month.setMonth(that.current_month.getMonth()+1); that.refresh_events_and_print(); })).append(' ')
      )          
      .append($('<p/>').append($('<a/>').attr('href', '#').click(function(e) { e.preventDefault(); that.new_calendar_event(iso8601_date(new Date())); }).html("New Event")))
      .append($('<table/>').append($('<thead/>').append(tr)).append(tbody))            
      .append($('<br/>'));            
    return div;
  },     
  
  delete_calendar: function(confirm)
  {
    var that = this;
    if (!confirm)
    {
      var p = $('<p/>').addClass('note confirm')
        .append('Are you sure you want to delete the calendar? ')
        .append($('<input/>').attr('type','button').val('Yes').click(function() { that.delete_calendar(true); })).append(' ')
        .append($('<input/>').attr('type','button').val('No').click(function() { $('#message').empty(); }));
      $('#message').empty().append(p);
      return;
    }
    $('#message').html("<p class='loading'>Deleting calendar...</p>");
    $.ajax({
      url: '/admin/calendars/' + that.calendar_id,
      type: 'delete',
      success: function(resp) {
        if (resp.error) $('#message').html("<p class='note error'>" + resp.error + "</p>");
        if (resp.redirect) window.location = resp.redirect;
      }
    });
  },
  
  //----------------------------------------------------------------------------
  // Calendar events
  //----------------------------------------------------------------------------
  
  new_calendar_event: function(d)
  {
    var that = this;
    new AdminCalendarEventModalController({
      calendar_id: that.calendar_id,
      event_id: false,
      new_event_date: d,
      parent_controller: this,
      modal_width: 600
    });    
  },
  
  edit_calendar_event: function(event_id)
  {
    var that = this;
    new AdminCalendarEventModalController({
      calendar_id: that.calendar_id,
      event_id: event_id,      
      parent_controller: this,
      modal_width: 600
    });    
  }    
});

function iso8601_date(d)
{       
  var m = d.getMonth() + 1;
  var day = d.getDate();
  return d.getFullYear() + '-' + (m < 10 ? '0' : '') + m + '-' + (day < 10 ? '0' : '') + day;
}

function month_name(d, use_short_name)
{   
  return d.toLocaleString('en-us', { month: use_short_name ? 'short' : 'long' });
}
