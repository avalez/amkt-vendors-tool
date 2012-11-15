google.load('visualization', '1', {'packages' : ['table']});
google.setOnLoadCallback(init);

var query, options, container;

var SalesQuery = function() {
}

SalesQuery.prototype.send = function(limit, offset, callback) {
  var jqXHR = $.getJSON('sales_data.json', {limit: limit, offset: offset}, function(json) {
    var data = new google.visualization.DataTable();
    data.addColumn('string', 'billingContactEmail');
    data.addColumn('string', 'billingContactName');
    data.addColumn('string', 'country');
    data.addColumn('string', 'date');
    data.addColumn('string', 'invoice');
    data.addColumn('string', 'licenseId');
    data.addColumn('string', 'licenseSize');
    data.addColumn('string', 'licenseType');
    data.addColumn('string', 'maintenanceEndDate');
    data.addColumn('string', 'maintenanceStartDate');
    data.addColumn('string', 'organisationName');
    data.addColumn('string', 'pluginName');
    data.addColumn('number', 'purchasePrice');
    data.addColumn('string', 'expertName');
    data.addColumn('string', 'saleType');
    data.addColumn('string', 'technicalContactEmail');
    data.addColumn('string', 'technicalContactName');
    data.addColumn('number', 'vendorAmount');
    var rows = [];
    for (i in json.sales) {
      var sale = json.sales[i];
      rows.push([sale.billingContact ? sale.billingContact.email : 'N/A',
        sale.billingContact ? sale.billingContact.name : 'N/A',
        sale.country, sale.date, sale.invoice,
        sale.licenseId, sale.licenseSize, sale.licenseType,
        sale.maintenanceEndDate, sale.maintenanceStartDate,
        sale.organisationName, sale.pluginName,
        sale.purchasePrice, sale.expertName, sale.saleType,
        sale.technicalContact ? sale.technicalContact.email : 'N/A',
        sale.technicalContact ? sale.technicalContact.name : 'N/A',
        sale.vendorAmount]);
    }
    data.addRows(rows);
    callback({
      isError: function() { return false},
      getDataTable: function() {return data}
    })
  })
}
 
function init() {
  query = new SalesQuery();
  container = document.getElementById("table");
  options = {'pageSize': 10};
  sendAndDraw();
}

function sendAndDraw() {
  var tableQueryWrapper = new TableQueryWrapper(query, container, options);
  tableQueryWrapper.sendAndDraw();
}

function setOption(prop, value) {
  options[prop] = value;
  sendAndDraw();
}

