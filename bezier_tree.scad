//https://openhome.cc/eGossip/OpenSCAD/BezierCurve.html

function bezier_coordinate(t, n0, n1, n2, n3) = 
    n0 * pow((1 - t), 3) + 3 * n1 * t * pow((1 - t), 2) + 
        3 * n2 * pow(t, 2) * (1 - t) + n3 * pow(t, 3);

function bezier_point(t, p0, p1, p2, p3) = 
    [
        bezier_coordinate(t, p0[0], p1[0], p2[0], p3[0]),
        bezier_coordinate(t, p0[1], p1[1], p2[1], p3[1]),
        bezier_coordinate(t, p0[2], p1[2], p2[2], p3[2])
    ];


function bezier_curve(t_step, p0, p1, p2, p3) = 
    [for(t = [0: t_step: 1 + t_step]) bezier_point(t, p0, p1, p2, p3)];


module line(point1, point2, width = 1, cap_round = true) {
    angle = 90 - atan((point2[1] - point1[1]) / (point2[0] - point1[0]));
    offset_x = 0.5 * width * cos(angle);
    offset_y = 0.5 * width * sin(angle);

    offset1 = [-offset_x, offset_y];
    offset2 = [offset_x, -offset_y];

    if(cap_round) {
        translate(point1) circle(d = width, $fn = 24);
        translate(point2) circle(d = width, $fn = 24);
    }

    polygon(points=[
        point1 + offset1, point2 + offset1,  
        point2 + offset2, point1 + offset2
    ]);
}

module polylineX(points, width = 1, decay = 0.1) {
  module polyline_inner(points, index) {
      if(index < len(points)) {
          line(points[index - 1], points[index], width-width*(index/len(points))*decay);
          polyline_inner(points, index + 1);
      }
  }

  polyline_inner(points, 1);
}


module polyline(points, botWidth = 40, topWidth = 20) {
  module polyline_inner(points, index) {
    //width = botWidth*(len(points)-index+1)/len(points)*widthDecay;
    //endwidth=widthDecay*botWidth;
    //width = endwidth+(len(points)-(index-1))/len(points)*(botWidth-endwidth);
    //width = botWidth+(index-1)/len(points)*((widthDecay*botWidth)-botWidth);
    //width = ((index-1)/len(points))*topWidth;
    width = botWidth - (botWidth-topWidth)*(index-1)/len(points);

    echo(index, width);
    if (index < len(points)) {
      line(points[index -1], points[index], width);
      polyline_inner(points, index + 1);
    }
  }
  polyline_inner(points, 1);
}

function divide(points, divisions) = floor(len(points)/(divisions));


//module tree(height = 600, trunk = 50, bend = 300, depth = 3, seed = 5, 
//  decay = 0.7, step = 0.01) {

module tree(seed = 55, height = 300, step = 0.01, bend = 75, maxWidth = 40, 
            minWidth = 30, decay =  0.2) {
  p0 = [0, 0];
  p1 = [rands(-bend, bend, 1, seed)[0], rands(p0[1], height/2, 1, seed+1)[0]]; 
  p2 = [rands(-bend, bend, 1, seed+2)[0], 
	rands(p1[1], height/2*2, 1, seed+3)[0]];
  p3 = [rands(-bend, bend, 1, seed+4)[0],
        height];

  pArray = [p0, p1, p2, p3];

  points = bezier_curve(step, 
      p0, p1, p2, p3
  );
  

  polyline(points, 40, 20);

  


  for (i=pArray) {
    color("red")
    translate(i)
      square(10, center = true);
  }

}

tree(seed=99);
