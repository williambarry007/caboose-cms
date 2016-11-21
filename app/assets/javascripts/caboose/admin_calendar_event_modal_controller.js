
var AdminCalendarEventModalController = ModalController.extend({
    
  calendar_id: false,
  event: false,
  event_id: false,
  new_event_date: false,
  
  edit_recurring: false,   
  EDIT_RECURRING_THIS_ONLY: 'this only',
  EDIT_RECURRING_THIS_AND_FOLLOWING: 'this and following',
  EDIT_RECURRING_ALL: 'all',
    
  init: function(params)
  {
    var that = this;
    for (var i in params)
      that[i] = params[i];
    that.print();    
  },
  
  refresh: function(callback)  
  {
    var that = this;        
    $.ajax({
      url: '/admin/calendars/' + that.calendar_id + '/events/' + that.event_id + '/json',
      type: 'get',      
      success: function(resp) { 
        that.event = resp; 
        if (callback) callback();
      }      
    });
  },
    
  print: function()
  {
    var that = this;
    
    if (!that.event_id && that.new_event_date)
    {
      that.print_new_event_form();
      return;
    }    
    if (!that.event)
    {
      var div = $('<div/>')
        .append($('<h1/>').append('Edit Event'))
        .append($('<p/>').addClass('loading').append("Getting event details..."));
      that.modal(div, 800);      
      that.refresh(function() { that.print(); });
      return;
    }    
    if (!that.edit_recurring && that.event.repeats == true)
    {
      var div = that.edit_recurring_form();      
      that.modal(div, 800);
      return;      
    }
                     
    var div = $('<div/>')
      .append($('<h1/>').append('Edit Event')) 
      .append($('<p/>').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_name'        )))
      .append($('<p/>').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_location'    )))
      .append($('<p/>').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_description' )))
      .append($('<div/>').attr('id', 'datetime_container').addClass(that.event.all_day ? 'all_day' : 'non_all_day')
        .append($('<table/>').append($('<tbody/>').append($('<tr/>')
          .append($('<td/>').addClass('event_date').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_begin_date' )))
          .append($('<td/>').addClass('event_time').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_begin_time' )))
          .append($('<td/>').addClass('event_date').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_end_date'   )))
          .append($('<td/>').addClass('event_time').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_end_time'   )))
        )))
        .append($('<div/>').addClass('spacer'))
      )            
      .append($('<table/>').attr('id', 'all_day_repeats_container').append($('<tbody/>').append($('<tr/>')
        .append($('<td/>').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_all_day')))
        .append($('<td/>').append($('<div/>').attr('id', 'calendarevent_' + that.event_id + '_repeats')))
      )))            
      .append(that.repeat_container())                     
      .append($('<div/>').attr('id', 'modal_message'))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('Close'        ).click(function() { that.close(); that.parent_controller.refresh_events_and_print(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Delete Event' ).click(function() { that.delete_event(); }))
      );
    that.modal(div);
    that.make_editable();
    that.after_all_day_update();
  },
  
  make_editable: function()
  {
    var that = this;
    var e = that.event;
    var g = that.event.calendar_event_group;  
    new ModelBinder({
      name: 'CalendarEvent',
      id: that.event_id,
      update_url: '/admin/calendars/' + that.calendar_id + '/events/' + that.event_id,
      authenticity_token: that.parent_controller.authenticity_token,
      attributes: [
        { name: 'name'        , nice_name: 'Name'         , type: 'text'     , value: e.name                     , width: 500, after_update: function() { e.name        = this.value; }},        
        { name: 'description' , nice_name: 'Description'  , type: 'richtext' , value: e.description              , width: 500, after_update: function() { e.description = this.value; }, height: 100 },
        { name: 'location'    , nice_name: 'Location'     , type: 'text'     , value: e.location                 , width: 500, after_update: function() { e.location    = this.value; }},
        { name: 'begin_date'  , nice_name: 'Begin'        , type: 'date'     , value: pretty_date(e.begin_date ) , width: 160, after_update: function() {}, align: 'right' },
        { name: 'begin_time'  , nice_name: 'Begin'        , type: 'time'     , value: pretty_time(e.begin_date ) , width: 100, after_update: function() {}, fixed_placeholder: false },
        { name: 'end_date'    , nice_name: 'End'          , type: 'date'     , value: pretty_date(e.end_date   ) , width: 150, after_update: function() {}, align: 'right' },
        { name: 'end_time'    , nice_name: 'End'          , type: 'time'     , value: pretty_time(e.end_date   ) , width: 100, after_update: function() {}, fixed_placeholder: false },
        { name: 'all_day'     , nice_name: 'All day'      , type: 'checkbox' , value: e.all_day ? 1 : 0          , width: 115, after_update: function() { e.all_day = this.value; that.after_all_day_update(); } },
        { name: 'repeats'     , nice_name: 'Repeats'      , type: 'checkbox' , value: e.repeats ? 1 : 0          , width: 130, after_update: function() { e.repeats = this.value; g.refresh; that.after_repeats_update(); } }      
      ],
      on_load: function() { that.autosize(); }    
    });  
    console.log(g);
    new ModelBinder({
      name: 'CalendarEventGroup',
      id: g.id,
      update_url: '/admin/calendars/' + that.calendar_id + '/event-groups/' + g.id + (that.edit_recurring == that.EDIT_RECURRING_THIS_AND_FOLLOWING ? '?after_calendar_event_id=' + that.event_id : ''), 
      authenticity_token: that.parent_controller.authenticity_token,
      attributes: [
        { name: 'frequency'    , nice_name: 'Repeat every'  , type: 'select'   , value: g.frequency                , width: 40  , fixed_placeholder: false, options_url: '/admin/event-groups/frequency-options' },
        { name: 'period'       , nice_name: 'Repeats'       , type: 'select'   , value: g.period                   , width: 80  , fixed_placeholder: false, options_url: '/admin/event-groups/period-options', after_update: function() { g.period = this.value; that.after_period_update(); } },      
        { name: 'repeat_by'    , nice_name: 'Repeat by'     , type: 'select'   , value: g.repeat_by                , width: 140 , fixed_placeholder: false, options_url: '/admin/event-groups/repeat-by-options' },
        { name: 'date_start'   , nice_name: 'Start'         , type: 'date'     , value: pretty_date(g.date_start ) , width: 150 , align: 'right' },
        { name: 'date_end'     , nice_name: 'End'           , type: 'date'     , value: pretty_date(g.date_end   ) , width: 150 , align: 'right' },      
        { name: 'sun'          , nice_name: 'sun'           , type: 'checkbox' , value: g.sun ? 1 : 0              , width: 21  , fixed_placeholder: false },
        { name: 'mon'          , nice_name: 'mon'           , type: 'checkbox' , value: g.mon ? 1 : 0              , width: 21  , fixed_placeholder: false },
        { name: 'tue'          , nice_name: 'tue'           , type: 'checkbox' , value: g.tue ? 1 : 0              , width: 21  , fixed_placeholder: false },
        { name: 'wed'          , nice_name: 'wed'           , type: 'checkbox' , value: g.wed ? 1 : 0              , width: 21  , fixed_placeholder: false },
        { name: 'thu'          , nice_name: 'thu'           , type: 'checkbox' , value: g.thu ? 1 : 0              , width: 21  , fixed_placeholder: false },
        { name: 'fri'          , nice_name: 'fri'           , type: 'checkbox' , value: g.fri ? 1 : 0              , width: 21  , fixed_placeholder: false },
        { name: 'sat'          , nice_name: 'sat'           , type: 'checkbox' , value: g.sat ? 1 : 0              , width: 21  , fixed_placeholder: false }        
      ],
      on_load: function() { that.autosize(); }
    });
  },
  
  repeat_container: function()
  {
    var that = this;
    
    var days_row = $('<tr/>');
    $.each(['S','M','T','W','R','F','S'], function(i, d) { days_row.append($('<th/>').append(d)); });
        
    var g = that.event.calendar_event_group;
    var div = $('<div/>').attr('id', 'repeat_container').css('display', that.event.repeats ? 'block' : 'none')
      .append($('<h2/>').append('Repeat Options'));
    
    var disabled = false;
    var msg = '';
    if (that.edit_recurring == that.EDIT_RECURRING_THIS_ONLY)
    {
      msg = "This is part of a repeating event series and you are making changes for only this event. ";
      disabled = true;
    }
    else if (that.edit_recurring == that.EDIT_RECURRING_THIS_AND_FOLLOWING)
    {
      msg = "This is part of a repeating event series and you are making changes for this event and any that follow. ";      
    }
    else if (that.edit_recurring == that.EDIT_RECURRING_ALL)
    {
      msg = "This is part of a repeating event series and you are making changes for the entire event series. ";      
    }  
    
    div.append($('<p/>')
        .append(msg)
        .append($('<a/>').attr('href','#').click(function(e) { e.preventDefault(); that.edit_recurring = false; that.print(); }).append('Change'))
      )
      .append($('<table/>').append($('<tbody/>').append($('<tr/>')
        .append($('<td/>').append($('<p/>').attr('id', 'repeat_every').append('Repeat every:'))) 
        .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_frequency'  )))
        .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_period'     )))
        .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_date_start' ))) 
        .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_date_end'   )))
      )))          
      .append($('<div/>').attr('id', 'repeat_by_container').css('display', g.repeat_by == 'Month' ? 'visible' : 'none')                    
        .append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_repeat_by'))
      )
      .append($('<table/>').addClass('data').attr('id', 'week_container').css('display', g.period == 'Week' ? 'visible' : 'none')
        .append($('<tbody/>')
          .append(days_row)
          .append($('<tr/>')
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_sun')))
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_mon')))
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_tue')))
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_wed')))
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_thu')))
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_fri')))
            .append($('<td/>').append($('<div/>').attr('id', 'calendareventgroup_' + g.id + '_sat')))
          )
        )
      );
    return div;
  },
  
  edit_recurring_form: function()
  {
    var that = this;           
    var div = $('<div/>')
      .append($('<h1/>').append('Edit Recurring Event'))      
      .append($('<p/>').append("This is a recurring event. To what events would you like any changes you make to be applied?"))            
      .append($('<table/>').append($('<tbody/>').append($('<tr/>')
        .append($('<td/>').append($('<input/>').attr('type', 'button').val('Only this event'                ).click(function(e) { that.edit_recurring = that.EDIT_RECURRING_THIS_ONLY;          that.print(); })))
        .append($('<td/>').append($('<input/>').attr('type', 'button').val('This event and any that follow' ).click(function(e) { that.edit_recurring = that.EDIT_RECURRING_THIS_AND_FOLLOWING; that.print(); })))
        .append($('<td/>').append($('<input/>').attr('type', 'button').val('All events'                     ).click(function(e) { that.edit_recurring = that.EDIT_RECURRING_ALL;                that.print(); })))
      )))
      .append($('<div/>').attr('id', 'modal_message'))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('Close'        ).click(function() { that.close(); })).append(' ')
        .append($('<input/>').attr('type', 'button').val('Delete Event' ).click(function() { that.delete_event(); }))
      );
    return div;    
  },
  
  print_new_event_form: function()
  {
    var that = this;
        
    var days_row = $('<tr/>');
    $.each(['S','M','T','W','R','F','S'], function(i, d) { days_row.append($('<th/>').append(d)); });
      
    var form = $('<form/>')
      .submit(function() { that.add_event($('#new_event_name').val()); return false; })
      .append($('<h1/>').append('New Event')) 
      .append($('<p/>').append($('<input/>').attr('type', 'text').attr('id', 'new_event_name').attr('placeholder', 'Event Name').css('width', '400px')))                     
      .append($('<div/>').attr('id', 'modal_message'))
      .append($('<p/>')
        .append($('<input/>').attr('type', 'button').val('Close'     ).click(function() { that.close(); })).append(' ')
        .append($('<input/>').attr('type', 'submit').val('Add Event' ))
      );
    that.modal(form, 600, null, function() { $('#new_event_name').focus(); });
  },
  
  add_event: function(name)
  {
    var that = this;
    that.autosize("<p class='loading'>Adding event...</p>");
    $.ajax({
      url: '/admin/calendars/' + that.calendar_id + '/events',
      type: 'post',
      data: { name: name, begin_date: that.new_event_date },
      success: function(resp)
      {
        if (resp.success)
        {
          that.event_id = resp.new_id;
          that.print();
          that.parent_controller.refresh_events_and_print();
        }
        if (resp.error) that.autosize("<p class='note error'>" + resp.error + "</p>");        
      }        
    });        
  },
           
  delete_event: function(delete_recurring, confirm)
  {
    var that = this;
    if (!delete_recurring)
    {
      var div = $('<div/>')
        .append($('<h1/>').append("Delete Event"))
        .append($('<p/>').append('This event is part of a series. Which events do you want to delete?'))
        .append($('<p/>')
          .append($('<input/>').attr('type','button').val('Only this event'                ).click(function() { that.delete_event(that.EDIT_RECURRING_THIS_ONLY          ); })).append(' ')
          .append($('<input/>').attr('type','button').val('This event and any that follow' ).click(function() { that.delete_event(that.EDIT_RECURRING_THIS_AND_FOLLOWING ); })).append(' ')
          .append($('<input/>').attr('type','button').val('All events'                     ).click(function() { that.delete_event(that.EDIT_RECURRING_ALL                ); })).append(' ')
        )
        .append($('<p/>').append($('<input/>').attr('type','button').val('Cancel').click(function() { that.print(); })));
      that.modal(div);
      return;
    }
    if (!confirm)
    { 
      if      (delete_recurring == that.EDIT_RECURRING_THIS_ONLY          ) msg = "Are you sure you want to delete only this event?";
      else if (delete_recurring == that.EDIT_RECURRING_THIS_AND_FOLLOWING ) msg = "Are you sure you want to delete this event and any that follow?";
      else if (delete_recurring == that.EDIT_RECURRING_ALL                ) msg = "Are you sure you want to delete all events in this series?";
      
      var div = $('<div/>')        
        .append($('<h1/>').append("Delete Event"))                
        .append($('<p/>').append(msg))
        .append($('<div/>').attr('id', 'modal_message'))
        .append($('<p/>')
          .append($('<input/>').attr('type','button').val('Yes').click(function() { that.delete_event(delete_recurring, true); })).append(' ')
          .append($('<input/>').attr('type','button').val('No').click(function() { that.print(); }))
        );
      that.modal(div);
      return;
    }
    that.autosize("<p class='loading'>Deleting event...</p>");
    $.ajax({
      url: '/admin/calendars/' + that.calendar_id + '/events/' + that.event_id,
      type: 'delete',
      data: { delete_recurring: delete_recurring },
      success: function(resp) {
        if (resp.error) that.autosize("<p class='note error'>" + resp.error + "</p>");
        if (resp.redirect) 
        {
          that.close();
          that.parent_controller.refresh_events_and_print();
        }
      }
    });
  },
  
  after_all_day_update: function()
  {
    var that = this;
    if (that.event.all_day)        
      $('td.event_time').hide()
    else
      $('td.event_time').show()
      
    //if (el.hasClass('all_day')) el.removeClass('all_day').addClass('non_all_day');
    //else                        el.removeClass('non_all_day').addClass('all_day');
    that.autosize();
  },
  
  after_repeats_update: function()
  {
    var that = this;        
    var el = $('#repeat_container');
    el.slideToggle(function() { that.autosize(); });  
  },
  
  after_period_update: function()
  {
    var that = this;
    var period = $('#calendareventgroup_' + that.event.calendar_event_group_id + '_period').val();
    //console.log(that.event.calendar_event_group.period);
    //console.log(period);    
    if (period == 'Week')   $('#week_container').show();
    else                    $('#week_container').hide();
    if (period == 'Month')  $('#repeat_by_container').show();
    else                    $('#repeat_by_container').hide();
    that.autosize();    
  }
  
});

function pretty_date(d)
{  
  if (!d) return '';  
  if (typeof d == 'string') d = new Date(d);

  var m = d.getUTCMonth() + 1;
  var day = d.getUTCDate();
  console.log("Pretty date: " + d);
  return '' + m + '/' + add_zero(day) + '/' + d.getFullYear();
}

function pretty_time(d)
{
  if (!d) return '';
  if (typeof d == 'string') d = new Date(d);
  var h = d.getUTCHours();
  var m = d.getUTCMinutes();
  var ampm = h >= 12 ? 'pm' : 'am';
  h = h >= 12 ? h - 12 : h
  return '' + h + ':' + add_zero(m) + ' ' + ampm;     
}

function add_zero(i)
{
  if (i > 10) return i;
  return '0' + i;    
}
