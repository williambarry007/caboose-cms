
function delete_product(product_id, confirm)
{
  if (!confirm)
  {
    var p = $('<p/>')
      .addClass('note error')
      .append("Are you sure you want to delete the product?<br />This can't be undone.")
      .append("<br /><br />")
      .append($("<input/>").attr('type', 'button').val('Yes').click(function() { delete_product(product_id, true); }))
      .append(' ')
      .append($("<input/>").attr('type', 'button').val('No').click(function() { cancel_delete_product(product_id); })); 
    modal.autosize(p);      
    return;
  }
  modal.autosize("<p class='loading'>Deleting product...</p>");
  $.ajax({
    url: '/admin/products/' + product_id,
    type: 'delete',
    success: function(resp) {
      if (resp.error)
        modal.autosize("<p class='note error'>" + resp.error + "</p>");
      if (resp.redirect)
        window.location = resp.redirect;
    }
  });
}

function cancel_delete_product(product_id)
{
  var p = $('<p/>').append($("<input/>").attr('type', 'button').val('Delete this product').click(function() { delete_product(product_id); }));
  modal.autosize(p);  
}

function add_variant(product_id)
{
  modal.autosize("<p class='loading'>Adding variant...</p>");
	
  $.ajax({
    url: '/admin/products/' + product_id + '/variants',
    type: 'post',
    success: function(resp) {
      if (resp.error)   modal.autosize("<p class='note error'>" + resp.error + "</p>");
      if (resp.refresh) window.location.reload(true);
    }
  })
}

function delete_variant(product_id, variant_id, confirm)
{
  if (!confirm)
  {
    var p = $('<p/>')
      .addClass('note error')
      .append("Are you sure you want to delete the variant?<br />This can't be undone.<br /><br />")
      .append($("<input/>").attr('type', 'button').val('Confirm').click(function() { delete_variant(product_id, variant_id, true); }))
      .append(' ')
      .append($("<input/>").attr('type', 'button').val('Cancel').click(function() { cancel_delete_variant(variant_id); }));    
    $('#message').html(p);
    return;
  }
  $('#message').html("<p class='loading'>Deleting product...</p>");
  $.ajax({
    url: '/admin/products/' + product_id + '/variants/' + variant_id,
    type: 'delete',
    success: function(resp) {
      if (resp.error)
        $('#message').html("<p class='note error'>" + resp.error + "</p>");
      if (resp.redirect)
        window.location = resp.redirect;
    }
  });
}

function cancel_delete_variant(variant_id)
{
  var link = $('<a/>').attr('href','#').click(function(e) { e.preventDefault(); delete_variant(variant_id); });    
  modal.autosize(link);
}
