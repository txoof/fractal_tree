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
                  maxGrowth, decay, maxAngle, step, start, control) {

  sizemod = rands(minGrowth, maxGrowth, 3, seed+4);
  mySize = sizemod[0]*size;

  p0 = [0,0];
  p1 = [rands(-bend, bend, 1, seed)[0], 
        rands(p0[1]+mySize/6, p0[1]+mySize/6*3, 1, seed+1)[0]]; 
  p2 = [rands(-bend, bend, 1, seed+2)[0], 
	rands(p0[1]+mySize/6*3, p0[1]+mySize/6*5, 1, seed+3)[0]];
  p3 = [rands(-bend, bend, 1, seed+4)[0],
        p0[1]+mySize];

  pArray = [p0, p1, p2, p3];

  points = bezier_curve(step, p0, p1, p2, p3);

  //main branch should be less angled than side branches
  rot = rands(-maxAngle/2, maxAngle/2, 1, seed+4)[0];
  
  //calculate the location of the tip based on the rotation angle
  tip = [start[0]+p3[0]-p3[1]*cos(90-rot), start[1]+p3[1]*sin(90-rot), 0];

  translate(tip)
    color("yellow")
    square(2*widthTop, center = true);

  // move to the starting point (previous tip)
  translate(start) {
    rotate([0, 0, rot])
    polyline(points, widthBottom, widthTop);

    // draw control points for debugging
    if (control) {
      for (i=pArray) {
        translate(i)
          color("red")
          square(size*.05, center = true);
      }
    }
  }


  
  //stop recursion if depth is less than 0
  if (depth > 0) {
    trunk(size = mySize*decay, depth = depth - 1, bend = bend*decay, seed = seed + 5, 
          widthBottom = widthTop, widthTop = widthTop*decay, 
          minGrowth = minGrowth, maxGrowth = maxGrowth, decay = decay, 
          maxAngle = maxAngle, step = step, start = tip, 
          control = control);
  }
  
}


module trunk(size = 300, depth = 3, seed = 55, widthBottom = 75, widthTop = 45, 
            minGrowth = 0.8, maxGrowth = 1.2, , decay = 0.9, maxAngle = 30,
            step = 0.01, start = [0,0], control = true) {

  //select the type of branch
  branchType = rands(0, 100, 1, seed+5)[0];

  if (0 < branchType && branchType < 100) {
    branch_one(size = size, depth = depth, bend = bend, seed = seed+6, 
              widthBottom = widthBottom, widthTop = widthTop, minGrowth = minGrowth, 
              maxGrowth = maxGrowth, decay = decay, maxAngle = maxAngle, step = step, 
              start = start, control = control);
  }

}

trunk(size = 500, seed = 5, bend = 50, control = true, depth = 5, decay = .8,
      widthBottom = 100, widthTop = 50);

