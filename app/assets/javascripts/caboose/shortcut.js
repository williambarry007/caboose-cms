
lastkeys = "";
$(document).keyup(function(e) {
  if (e.keyCode == 13 && lastkeys == "caboose") // Enter
  {
    
  }
  if (lastkeys.length > 7)
    lastkeys = "";
  lastkeys += String.fromCharCode(e.keyCode);
});
