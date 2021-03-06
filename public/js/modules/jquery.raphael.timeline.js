jQuery.fn.timelineGraph = function(){
  return this.each(function(){
    
    // Hide the original table
    $(this).css({
      position: 'absolute',
      left: '-9999px',
      top: '-9999px'
    });
    
    var max_num_labels = 15;
    
    // Grab the data from the table
    var labels = [], data = [], data_numbers = [], elapsed_data = [], elapsed_data_numbers = [];
    var label_cells = $(this).find('tfoot th');
    var num_skip_cells = Math.max(Math.floor(label_cells.length/max_num_labels) - 1, 0);
    var skip_iter = 0;
    label_cells.each(function(){
      var type = 'skip';
      if (++skip_iter > num_skip_cells){
        type = 'show';
        skip_iter = 0;
      }
      labels.push({text:$(this).html(), type:type});
    });
    $(this).find('tbody tr#hours_left td').each(function(){
      var data_type = null;
      if ($(this).hasClass('future')) data_type = 'future' ;
      data.push({value: $(this).html(), type:data_type})
      data_numbers.push($(this).html());
    });
    $(this).find('tbody tr#hours_elapsed td').each(function(){
      var data_type = null;
      if ($(this).hasClass('future')) data_type = 'future' ;
      elapsed_data.push({value: $(this).html(), type:data_type})
      elapsed_data_numbers.push($(this).html());
    });
    
    // Prepare variables for drawing
    var width = 790, height = 250, leftgutter = 0, rightgutter = 0, topgutter = 20, bottomgutter = 25;
    var colorhue = 0.75, color = "#ffb240", red_color = "#E6392E";
    var r = Raphael("holder", width, height);
    var txt =  {"font": '12px "Helvetica"', "font-weight": "bold", stroke: 'none', fill: '#000'},
        txt1 = {"font": '12px "Helvetica"', "font-weight": "bold", stroke: 'none', fill: '#000'},
        txt2 = {"font": '12px "Helvetica"', stroke: 'none', fill: '#000'}
    var X = (width - leftgutter) / labels.length,
        max = Math.max.apply(Math, data_numbers),
        Y = (height - bottomgutter - topgutter) / max;
    
    // Draw the grid ?
    r.drawGrid(leftgutter + X*0.5, topgutter, width - leftgutter - X, height - topgutter - bottomgutter, 10, 10, "#ddd");
    var path =  r.path({stroke: color, "stroke-width": 3, "stroke-linejoin": "round"}),
        bgp =   r.path({stroke: "none", opacity: 0.3, fill: color}).moveTo(leftgutter + X*0.5, height - bottomgutter),
        frame = r.rect(10, 10, 100, 40, 5).attr({fill: "#eee", stroke: "#ccc", "stroke-width": 2}).hide();
    
    var red_path =  r.path({stroke: red_color, "stroke-width": 3, "stroke-linejoin": "round"});
    // Labels ?
    var label = [],
        is_label_visible = false,
        leave_timer,
        blanket = r.set();
    
    label[0] = r.text(60, 10, "hours left").attr(txt).hide();
    label[1] = r.text(60, 40).attr(txt1).attr({fill: "#666"}).hide();
    
    for(var i=0, ii=labels.length; i<ii; i++){
      var y = Math.round(height - bottomgutter - Y*data[i].value),
          x = Math.round(leftgutter + X * (i + 0.5)),
          t = r.text(x, height - 6, labels[i].type == 'show' ? labels[i].text : "").attr(txt).toBack();
      var dot_color = data[i].type == 'future' ? "#c3c3c3" : color;
      // bgp[i == 0 ? "lineTo" : "cplineTo"](x, y, 10);
      path.attr({"color": dot_color});
      if (data[i].type != 'future') path[i == 0 ? "moveTo" : "cplineTo"](x, y, 10);
      var dot = r.circle(x, y, 4).attr({fill: dot_color, stroke: "#fff", "stroke-width": 2});
      blanket.push(r.rect(leftgutter + X * i, y-10, X, 20).attr({stroke: "none", fill: "#fff", opacity: 0}));
      var rect = blanket[blanket.length - 1];
      (function(x, y, data, lbl, dot){
        var timer, i = 0;
        $(rect.node).hover(function(){
          clearTimeout(leave_timer);
          var newcoord = {x: x*1 + 7.5, y: y - 19};
          if (newcoord.x + 100 > width){
            newcoord.x -= 114;
          }
          frame.show().animate({x: newcoord.x, y:newcoord.y}, 200*is_label_visible);
          var label_text = data.type == 'future' ? data.value + " (projected)" : data.value + " hour" + ((data.value == 1) ? "" : "s");
          label[0].attr({text:label_text}).show().animate({x: newcoord.x*1 + 50, y:newcoord.y*1 + 12}, 200 *is_label_visible);
          label[1].attr({text: lbl.text}).show().animate({x: newcoord.x * 1 + 50, y: newcoord.y * 1 + 27}, 200 * is_label_visible);
          dot.attr("r", 7);
          is_label_visible = true;
          r.safari();
        }, function(){
          dot.attr("r", 4);
          r.safari();
          leave_timer = setTimeout(function(){
            frame.hide();
            label[0].hide();
            label[1].hide();
            is_label_visible = false;
            r.safari();
          }, 1);
        })
      })(x, y, data[i], labels[i], dot);
    }

    for(var i=0, ii=labels.length; i<ii; i++){
      var y = Math.round(height - bottomgutter - Y*elapsed_data[i].value),
          x = Math.round(leftgutter + X * (i + 0.5)),
          t = r.text(x, height - 6, labels[i].type == 'show' ? labels[i].text : "").attr(txt).toBack();
      var dot_color = elapsed_data[i].type == 'future' ? "#c3c3c3" : red_color;
      // bgp[i == 0 ? "lineTo" : "cplineTo"](x, y, 10);
      path.attr({"color": dot_color});
      if (elapsed_data[i].type != 'future') red_path[i == 0 ? "moveTo" : "cplineTo"](x, y, 10);
      var dot = r.circle(x, y, 4).attr({fill: dot_color, stroke: "#fff", "stroke-width": 2});
      blanket.push(r.rect(leftgutter + X * i, y-10, X, 20).attr({stroke: "none", fill: "#fff", opacity: 0}));
      var rect = blanket[blanket.length - 1];
      (function(x, y, elapsed_data, lbl, dot){
        var timer, i = 0;
        $(rect.node).hover(function(){
          clearTimeout(leave_timer);
          var newcoord = {x: x*1 + 7.5, y: y - 19};
          if (newcoord.x + 100 > width){
            newcoord.x -= 114;
          }
          frame.show().animate({x: newcoord.x, y:newcoord.y}, 200*is_label_visible);
          var label_text = elapsed_data.type == 'future' ? elapsed_data.value + " (projected)" : elapsed_data.value + " hour" + ((elapsed_data.value == 1) ? "" : "s");
          label[0].attr({text:label_text}).show().animate({x: newcoord.x*1 + 50, y:newcoord.y*1 + 12}, 200 *is_label_visible);
          label[1].attr({text: lbl.text}).show().animate({x: newcoord.x * 1 + 50, y: newcoord.y * 1 + 27}, 200 * is_label_visible);
          dot.attr("r", 7);
          is_label_visible = true;
          r.safari();
        }, function(){
          dot.attr("r", 4);
          r.safari();
          leave_timer = setTimeout(function(){
            frame.hide();
            label[0].hide();
            label[1].hide();
            is_label_visible = false;
            r.safari();
          }, 1);
        })
      })(x, y, elapsed_data[i], labels[i], dot);
    }
    
    bgp.lineTo(x, height - bottomgutter).andClose();
    frame.toFront();
    label[0].toFront();
    label[1].toFront();
    blanket.toFront();
  });
}
