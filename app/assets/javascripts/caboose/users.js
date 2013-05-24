
/*
Nine
Caboose.User = function(){};

Caboose.User.add = function()
{
  $('#message').html("<p class='loading'>Adding user...</p>");
  
  $.ajax({
    url: '/users',
    type: 'post',
    data: $('#new_user_form').serialize(),
    success: Caboose.ajax_success,
    error: Caboose.ajax_error
  });
};

Caboose.User.delete = function(user_id, confirm)
{
  if (!confirm)
  {
    Caboose.confirm({
        message: "Are you sure you want to delete the user?  This can't be undone.",
        yes: function() { Caboose.User.delete(user_id, true) }
    });
    return;    
  }
  $('#message').html("<p class='loading'>Deleting user...</p>");
	
	$.ajax({
		url: '/users/' + user_id, 
		type: 'delete',
		success: Caboose.ajax_success,
		error: Caboose.ajax_error
	}); 
};
*/