// Load the Visualization API and the piechart package.
google.load('visualization', '1.0', {'packages':['geochart']});

// Set a callback to run when the Google Visualization API is loaded.
google.setOnLoadCallback(drawChart);

// Callback that creates and populates a data table,
// instantiates the pie chart, passes in the data and
// draws it.
function drawChart() {

  // Create the data table.
  var data = new google.visualization.DataTable();

  // see https://developers.google.com/chart/interactive/docs/gallery/annotatedtimeline
  var jqXHR = $.getJSON('geochart.json', function(json) {
    data.addColumn('string', 'Country');
    data.addColumn('number', '# of Licenses');
    for (country in json.geo) {
      data.addRow([country, json.geo[country]]);
    }
    
    // Set chart options
    var options = {'title':'Licenses'};

    // Instantiate and draw our chart, passing in some options.
    var chart = new google.visualization.GeoChart(document.getElementById('chart_div'));
    chart.draw(data, options);
  });
}