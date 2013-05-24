
Caboose.Role = function(){};

Caboose.Role.add = function()
{
  $('#message').html("<p class='loading'>Adding role...</p>");
  
  $.ajax({
    url: '/roles',
    type: 'post',
    data: $('#new_role_form').serialize(),
    success: Caboose.ajax_success,
    error: Caboose.ajax_error
  });
};

Caboose.Role.delete = function(role_id, confirm)
{
  if (!confirm)
  {
    Caboose.confirm({
        message: "Are you sure you want to delete the role?  This can't be undone.",
        yes: function() { Caboose.Role.delete(role_id, true) }
    });
    return;    
  }
  $('#message').html("<p class='loading'>Deleting role...</p>");
	
	$.ajax({
		url: '/roles/' + role_id, 
		type: 'delete',
		success: Caboose.ajax_success,
		error: Caboose.ajax_error
	}); 
};
