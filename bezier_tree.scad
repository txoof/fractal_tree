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

module polyline(points, startWidth = 40, endWidth = 20) {
  module polyline_inner(points, index) {
   //change the width with respect to the start and end
   width = startWidth - (startWidth-endWidth)*(index-1)/len(points);

    if (index < len(points)) {
      line(points[index -1], points[index], width);
      polyline_inner(points, index + 1);
    }
  }
  polyline_inner(points, 1);
}


//module tree(size = 600, trunk = 50, bend = 300, depth = 3, seed = 5, 
//  decay = 0.7, step = 0.01) {


/*
module trunk(seed = 55, size = 300, step = 0.01, depth = 3, bend = 75, 
            widthBottom = .3,
            widthTop = .2, 
            minGrowth = 0.8,
            maxGrowth = 1.2,
*/
module trunk(size = 300, depth = 3, seed = 55, widthBottom = 0.25, widthTop = 0.18,
            minGrowth = 0.8, maxGrowth = 1.2, step = 0.01
            ) {

  p0 = [0, 0];
  p1 = [rands(-bend, bend, 1, seed)[0], rands(p0[1], size/2, 1, seed+1)[0]]; 
  p2 = [rands(-bend, bend, 1, seed+2)[0], 
	rands(p1[1], size/2*2, 1, seed+3)[0]];
  p3 = [rands(-bend, bend, 1, seed+4)[0],
        size];

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

trunk(seed=27, bend = 45);
