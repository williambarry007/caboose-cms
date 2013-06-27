
function login()
{
  $('#message').hide();
  $('#message').html("<p class='loading'>Logging in...</p>");
	$('#message').slideDown({ duration: 350 });
	parent.$.fn.colorbox.resize({ height:"340px" })

	$.ajax({
		url: '/login',
		type: 'post',
		data: $('#login_form').serialize(),
		success: function(resp) {
		  if (resp.error)
		    $('#message').html("<p class='note error'>" + resp.error + "</p>"); 		    
			else if (resp.redirect != false)
			  parent.window.location = resp.redirect;
			else
			  parent.location.reload(true);
		},
		error: function() {	
			$('#message').html("<p class='note error'>Error</p>"); 
		}
	});
}
