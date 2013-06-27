
function register()
{
  resize_colorbox("<p class='loading'>Registering...</p>");

	$.ajax({
		url: '/register',
		type: 'post',
		data: $('#register_form').serialize(),
		success: function(resp) {
		  if (resp.error)
		    resize_colorbox("<p class='note error'>" + resp.error + "</p>");
			else if (resp.redirect != false)
			  window.location = resp.redirect;
			else
			  parent.location.reload(true);
		},
		error: function() {	
			$('#message').html("<p class='note error'>Error</p>"); 
		}
	});
}

function resize_colorbox(html)
{
  $('#message').html(html);
  height = $('#modal_content').outerHeight(true);
  parent.$.fn.colorbox.resize({ innerHeight: '' + height + 'px' })
}
