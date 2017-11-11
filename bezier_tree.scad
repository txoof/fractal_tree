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


module branch_one(size, depth, bend, seed, widthBottom, widthTop, joint, minGrowth,
                  maxGrowth, step, start, control) {
 
  p0 = start;

  translate(p0)
    color("green")
    square(100, center = true);
  p1 = [rands(-bend, bend, 1, seed)[0], rands(p0[1], p0[1]+size/2, 1, seed+1)[0]]; 
  p2 = [rands(-bend, bend, 1, seed+2)[0], 
	rands(p1[1], p0[1]+size/2*2, 1, seed+3)[0]];
  p3 = [rands(-bend, bend, 1, seed+4)[0],
        p0[1]+size];

  pArray = [p0, p1, p2, p3];

  points = bezier_curve(step, p0, p1, p2, p3);

  polyline(points, size*widthBottom, size*widthTop);

  // draw control points for debugging
  if (control) {
    for (i=pArray) {
      translate(i)
        color("red")
        square(size*.05, center = true);
    }
  }


  sizemod = 1;
  echo("depth:", depth, "start:", p3);
    if (depth > 0) {
      trunk(size = size*.9, depth = depth - 1, bend = bend*.9, seed = seed + 5, 
            widthBottom = widthBottom, widthTop = widthTop, minGrowth = minGrowth,
            maxGrowth = maxGrowth, step = step, start = p3, control = control);
    }
  
}

module trunk(size = 300, depth = 3, seed = 55, widthBottom = 0.25, widthTop = 0.15,
            minGrowth = 0.8, maxGrowth = 1.2, step = 0.01, start = [0,0], 
            control = false) {

  /*
  p0 = start;
  p1 = [rands(-bend, bend, 1, seed)[0], rands(p0[1], size/2, 1, seed+1)[0]]; 
  p2 = [rands(-bend, bend, 1, seed+2)[0], 
	rands(p1[1], size/2*2, 1, seed+3)[0]];
  p3 = [rands(-bend, bend, 1, seed+4)[0],
        size];

  //calculate the points along the bezier curve
  points = bezier_curve(step, p0, p1, p2, p3 );
  
  //draw a branch
  polyline(points, size*widthBottom, size*widthTop);
  */

  //select the type of branch
  branchType = rands(0, 100, 1, seed+5)[0];

  if (0 < branchType && branchType < 100) {
    branch_one(size = size, depth = depth, bend = bend, seed = seed+6, 
              widthBottom = widthBottom, widthTop = widthTop, minGrowth = minGrowth, 
              maxGrowth = maxGrowth, step = 0.01, start = start, control = control);
  }

}

trunk(size = 500, seed = 4, bend = 200, control = true, depth = 5);
