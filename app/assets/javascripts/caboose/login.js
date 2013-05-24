
function login()
{
  $('#message').html("<p class='loading'>Logging in...</p>");

	$.ajax({
		url: '/login',
		type: 'post',
		data: $('#login_form').serialize(),
		success: function(resp) {
		  if (resp.error)
		    $('#message').html("<p class='note error'>" + resp.error + "</p>");
			else if (resp.redirect != false)
				window.location = resp.redirect;
		},
		error: function() {	
			$('#message').html("<p class='note error'>Error</p>"); 
		}
	});
}

