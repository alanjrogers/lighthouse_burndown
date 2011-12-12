jQuery.fn.timelineGraph = function(){
  return this.each(function(){
    
    // Hide the original table
    $(this).css({
      position: 'absolute',
      left: '-9999px',
      top: '-9999px'
    });

    var width = 790, height = 250, leftgutter = 15, rightgutter = 0, topgutter = 0, bottomgutter = 20;
    var colorhue = 0.75, color = "#ffb240";
    var r = Raphael("holder", width, height);

    var max_num_labels = 15;
    
    // Grab the data from the table
    var label_indices = [], labels = [], hours_left_numbers = [];
    var hours_elapsed_numbers = [], future_hours_left = [], future_hours_elapsed = [];
    var label_cells = $(this).find('tfoot th');
    var num_skip_cells = Math.max(Math.floor(label_cells.length/max_num_labels) - 1, 0);
    var skip_iter = 0;
    var index = 0;
    label_cells.each(function(){
      var type = 'skip';
      if (++skip_iter > num_skip_cells){
        type = 'show';
        skip_iter = 0;
      }
      labels.push({text:$(this).html(), type:type});
      label_indices.push(index++);
    });
    
    var future_left_labels = [], hours_left_labels = [];
    index = 0;
    $(this).find('tbody tr#hours_left td').each(function(){
      if ($(this).hasClass('future')) {
        future_left_labels.push(index);
        future_hours_left.push($(this).html());
      } else {
        hours_left_labels.push(index);
        hours_left_numbers.push($(this).html());
      }
      index++;
    });

    var future_elapsed_labels = [], hours_elapsed_labels = [];
    index = 0;
    $(this).find('tbody tr#hours_elapsed td').each(function(){
      if ($(this).hasClass('future')) {
          future_elapsed_labels.push(index);
          future_hours_elapsed.push($(this).html());
      } else {
          hours_elapsed_labels.push(index);
          hours_elapsed_numbers.push($(this).html());
      }
      index++;
    });

    //console.log(hours_left_labels, future_left_labels, hours_left_numbers, future_hours_left, hours_elapsed_labels, future_elapsed_labels, hours_elapsed_numbers, future_hours_elapsed);

    var lines = r.linechart(leftgutter, topgutter, width-rightgutter-leftgutter, height-bottomgutter-topgutter, [labels, future_left_labels], [hours_left_numbers], { nostroke: false, axis: "0 0 1 1", symbol: "circle", smooth: false, colors: [color, "#c3c3c3","#E6392E", "#c3c3c3"] } ); 

    lines.symbols.attr({ r: 4 });
    
})};
