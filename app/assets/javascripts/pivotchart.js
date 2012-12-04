// Load the Visualization API and the corechart package.
google.load('visualization', '1.0', {'packages':['corechart']});

// Set a callback to run when the Google Visualization API is loaded.
google.setOnLoadCallback(drawChart);

// Callback that creates and populates a data table,
// instantiates the pie chart, passes in the data and
// draws it.
function drawChart() {

  // Create the data table.
  var data = new google.visualization.DataTable();

  // see https://developers.google.com/chart/interactive/docs/gallery/annotatedtimeline
  var jqXHR = $.getJSON('pivot.json', function(json) {
    
    data.addColumn('string', 'Edition');
    data.addColumn('number', '# of Licenses * 100');
    data.addColumn('number', 'Aprx. Gross');
    for (edition in json.total) {
      data.addRow([edition, json.total[edition] * (edition == 'Evaluation' ? 1 : 100), json.amount[edition]]);
    }
    
    // Set chart options
    var options = {'title':'Totals'};

    // Instantiate and draw our chart, passing in some options.
    var chart = new google.visualization.ColumnChart(document.getElementById('chart'), {'hAxis.logScale':true});
    chart.draw(data, options);
  });
}