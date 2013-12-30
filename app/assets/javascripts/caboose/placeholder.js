// Placeholder IE Fix

$(document).ready(function() {
	$('[placeholder]').focus(function() {
	  console.log("PH"); 
	  var input = $(this);
	  if (input.val() == input.attr('placeholder')) {
	    input.val('');
	    input.removeClass('placeholder_js');
	  }
	}).blur(function() {
	  var input = $(this);
	  if (input.val() == '' || input.val() == input.attr('placeholder')) {
	    input.addClass('placeholder_js');
	    input.val(input.attr('placeholder'));
	  }
	}).blur().parents('form').submit(function() {
	  $(this).find('[placeholder]').each(function() {
	    var input = $(this);
	    if (input.val() == input.attr('placeholder')) {
	      input.val('');
	    }
	  })
	});
}); 
