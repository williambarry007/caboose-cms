
$(document).ready(function() {
  $('#caboose_station').hide();
  $('#caboose_conductor').click(function() {
    CabooseStation.toggle();
  });
});

var CabooseStation = function() {};

CabooseStation.is_open = false;

CabooseStation.toggle = function() {
  if (CabooseStation.is_open)
    CabooseStation.close();
  else
    CabooseStation.open();
};

CabooseStation.open = function() {
  $('#caboose_station').show('slide', { direction: 'right' }, 300);
  CabooseStation.is_open = true;
};

CabooseStation.close = function() {
  $('#caboose_station').hide('slide', { direction: 'right' }, 300);
  CabooseStation.is_open = false;
}
