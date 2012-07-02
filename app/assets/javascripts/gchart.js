// Load the Visualization API and the piechart package.
google.load('visualization', '1.0', {'packages':['annotatedtimeline']});

// Set a callback to run when the Google Visualization API is loaded.
google.setOnLoadCallback(drawChart);

// Callback that creates and populates a data table,
// instantiates the pie chart, passes in the data and
// draws it.
function drawChart() {

  // Create the data table.
  var data = new google.visualization.DataTable();

  // see https://developers.google.com/chart/interactive/docs/gallery/annotatedtimeline
  var jqXHR = $.getJSON('chart.json', function(json) {
    data.addColumn('date', 'Date');
    var i = 1;
    for (edition in json.all_editions) {
      data.addColumn('number', edition);
      //data.addColumn('string', 'title' + i);
      //data.addColumn('string', 'text' + i);
      i++;
    }
    for (date in json.pivot) {
      var row = [new Date(date)];
      for (edition in json.all_editions) {
        var licenses = json.pivot[date][edition] || 0;
        row.push(licenses);
      }
      data.addRow(row);
    }
    
    // Set chart options
    var options = {'title':'Licenses',
                   'displayAnnotations':false};

    // Instantiate and draw our chart, passing in some options.
    var chart = new google.visualization.AnnotatedTimeLine(document.getElementById('chart_div'));
    chart.draw(data, options);
  });
}