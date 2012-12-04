google.load('visualization', '1', {'packages' : ['table', 'corechart']});
google.setOnLoadCallback(init);

var query, options, container, chart_container;

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
    var chart_pivot = {'10 Users' : {}, '25 Users' : {}, '50 Users' : {},
     '100 Users': {}, '500 Users' : {}, 'Unlimited Users' : {}};
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

      // chart
      if (!(sale.licenseSize in chart_pivot)) {
        chart_pivot[sale.licenseSize] = {};
      }
      edition_pivot = chart_pivot[sale.licenseSize];
      edition_pivot.count = (edition_pivot.count || 0) + 1;
      edition_pivot.gross = (edition_pivot.gross || 0) + sale.purchasePrice;
      edition_pivot.net = (edition_pivot.net || 0) + sale.vendorAmount;
    }
    data.addRows(rows);

    // chart
    var chart_rows = [];
    chart_rows.push(['licenseSize', 'Count * 100', 'Gross', 'Net']);
    for (key in chart_pivot) {
      chart_rows.push([key,
        chart_pivot[key].count * 100,
        chart_pivot[key].gross,
        chart_pivot[key].net]);
    }
    //chart_data.addRows(chart_rows);
    var chart_data = google.visualization.arrayToDataTable(chart_rows);

    callback({
      isError: function() { return false},
      getDataTable: function() {return data},
      getChartDataTable: function() {return chart_data}
    })
  })
}
 
function init() {
  query = new SalesQuery();
  container = document.getElementById("table");
  chart_container = document.getElementById("chart");
  options = {'pageSize': 10};
  sendAndDraw();
}

function sendAndDraw() {
  var tableQueryWrapper = new TableQueryWrapper(query, container, chart_container, options);
  tableQueryWrapper.sendAndDraw();
}

function setOption(prop, value) {
  options[prop] = value;
  sendAndDraw();
}

