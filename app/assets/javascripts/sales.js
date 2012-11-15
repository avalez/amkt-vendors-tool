google.load('visualization', '1', {'packages' : ['table']});
google.setOnLoadCallback(init);

var dataSourceUrl = 'https://spreadsheets.google.com/tq?key=rh_6pF1K_XsruwVr_doofvw&pub=1';
var query, options, container;

function init() {
  query = new google.visualization.Query(dataSourceUrl);
  container = document.getElementById("table");
  options = {'pageSize': 5};
  sendAndDraw();
}

function sendAndDraw() {
  query.abort();
  var tableQueryWrapper = new TableQueryWrapper(query, container, options);
  tableQueryWrapper.sendAndDraw();
}

function setOption(prop, value) {
  options[prop] = value;
  sendAndDraw();
}

