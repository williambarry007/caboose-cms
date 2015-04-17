
var google_spreadsheets = false;

function google_csv_data(spreadsheet_id, col, row)
{
  var csv_array = false;
  if (!google_spreadsheets) google_spreadsheets = {};
  if (!google_spreadsheets[spreadsheet_id])  
  {    
    $.ajax({
      url: "/google-spreadsheets/" + spreadsheet_id + "/csv",
      type: 'get',
      success: function(arr){ google_spreadsheets[spreadsheet_id] = arr; },           
      async: false               
    });
  }
  var arr = google_spreadsheets[spreadsheet_id];
  var c = column_name_to_int(col);    
  return arr[parseInt(row)-1][c];        
}
  
function column_name_to_int(col)
{  
  var c = 0;
  if (col.length > 0)
  {
    var l = col.length;
    for (var i=l-1; i >=0; i--)      
      c += Math.pow(25, l-i-1) * (col.charCodeAt(i) - 65);
  }
  return c;  
}  
