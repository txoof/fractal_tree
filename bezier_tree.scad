//https://openhome.cc/eGossip/OpenSCAD/BezierCurve.html

/* 
calculate a coordinate along a bezier curve
paramaters:
  t             [real]        step along the curve
  coord         [vector]      x, y, z vector
*/
function bezierCoordinate(t, coord) = 
  coord[0] * pow((1 - t), 3) + 3 * coord[1] * t * pow((1 - t), 2) +
    3 * coord[2] * pow(t, 2) * (1 - t) + coord[3] * pow(t, 3);

/*
calculate the points along a bezier curve
paramaters:
  t               [real]        step along the curve
  controlPoints   [vector]      x, y, z vector
*/
function bezierPoint(t, controlPoints) = 
  [
    bezierCoordinate(t, [controlPoints[0][0], controlPoints[1][0], controlPoints[2][0],
                    controlPoints[3][0]]),
    bezierCoordinate(t, [controlPoints[0][1], controlPoints[1][1], controlPoints[2][1],
                    controlPoints[3][1]]),
    bezierCoordinate(t, [controlPoints[0][2], controlPoints[1][2], controlPoints[2][2],
                    controlPoints[3][2]])
  ];

/*
calculate the bezier curve for four control points
paramaters:
  t_step          [real]      step size (smaller steps give finer curves)
  controlPoints   [vector]    vector of x, y, z vectors [[0,0], [10,10], [-10,20], [0,50]]
*/
function bezierCurve(t_step, controlPoints) = 
  [for(t = [0:t_step:1+t_step]) bezierPoint(t, controlPoints)];


/*
generate a vector of four vector control points 
paramaters:
  seed            [real]      seed for random number generator
  bend            [real]      maximum/minimum deflection for curve
  size            [real]      length, from origin, of curve
*/
function randControlPoints(seed, bend, size) = [ 
  // start at origin
  [0, 0], 
  // choose X points between max/min bend, Y points on interval 1/6:3/6 size
  [rands(-bend, bend, 1, seed+0)[0], rands(size/6, size/6*3, 1, seed+1)[0]], 
  // choose X points between max/min bend, Y points on interval 3/6:5/6 size
  [rands(-bend, bend, 1, seed+2)[0], rands(size/6*3, size/6*5, 1, seed+3)[0]],
  // choose X points between max/min bend, Y point at size
  [rands(-bend, bend, 1, seed+4)[0], size] 
  ];

/*
draw a line segment along a bezier curve
paramaters
  point1          [vector]      x, y, z vector of a single point along a bezier curve
  point2          [vector]      x, y, z vector of a single point adjacent to point1
*/
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


/*
draw a (tapered) line along a vector curve
paramaters:
  points        [vector]      vector of x, y, z vectors that describe a bezier curve
  startWidth    [real]        starting width of the poly line
  endWidth      [real]        ending width of the poly line
*/
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

/*
draw between 1 and 3 poly lines rooted at the "start"
  -this module should be called by module trunk()
paramaters:
  size          [real]        size of first segment (linear from origin)
  depth         [integer]     recusion level
  widthBottom   [real]        maximum width at base of branch
  widthTop      [real]        maximum width at top of branch
  minGrowth     [real]        minimum amount to grow the new branch (0.1 to 1.2)
  maxGrowth     [real]        maximum amount to grow the new branch (0.1 to 1.2)
  decay         [real]        base amount to diminish each branch by (0.5 to 0.9)
  maxAngle      [real]        maximum angle to rotate each branch (0 to 180)
  branchNum     [integer]     number of branches to draw
  start         [vector]      x, y, z vector at which to start growing the branch
*/
module branch(size, depth, depthMax, bend, seed, widthBottom, widthTop, minGrowth, 
              maxGrowth, decay, maxAngle, step, branchNum, 
              start, distance) {
  
  debug = 0; 

  sizemod = rands(minGrowth, maxGrowth, branchNum, seed+1)[0];

  mySize = size*sizemod;

  controlPoints = randControlPoints(seed = seed, bend = bend, size = mySize);
  
  bezierPoints = bezierCurve(step, controlPoints);

  // diminish the branch width by the depth and the distance from the "trunk"
  myWidthTop = widthTop*(depth+1)/(depthMax-2)/(distance+2);

  polyline(bezierPoints, widthBottom, myWidthTop);

  


  /*
          for (j=[0:len(controlPoints)-1]) {
            color("red")
              translate(controlPoints[j])
              square(30, center = true);
          }
  */

  if (debug) {
    translate(controlPoints[3]) {
      color("red")
      text(str("seed:", seed,", bn:", branchNum), 
              halign = "left", size = myWidthTop*.5);
    }
  }


  // create vector of branchNum angles between 0 and maxAngle
  rotations = rands(minAngle, maxAngle, branchNum, seed+3);
  // create vector of branchNum negative and positive values
  direction = [ for (j=[0:branchNum-1]) rands(-1, 1, 1, seed-j)[0]>=0 ? 1 : -1];

  decayRands = rands(decay*decay, decay, branchNum, seed+5);

  tip = controlPoints[3];


  if (depth > 0 && myWidthTop > 10) { //stop if the width gets too small 
    translate(tip) {
      for (i=[0:branchNum-1]) {
        myRot = i==0 ? rotations[i]/depth : rotations[i];
        myDist = (i==0 && distance == 0 )? 0 : distance+1;
        //rotate the starting position by myRot * direction (ccw, cw)
        rotate([0, 0, direction[i]*myRot]) {
          trunk(size = mySize*decay, depth = depth-1, depthMax = depthMax,
              //bend = bend*decay, 
              bend = bend*decay,
              seed = seed*(i+5)/(i+1), widthBottom = myWidthTop, 
              widthTop = widthTop*decayRands[i], 
              minGrowth = minGrowth, maxGrowth = maxGrowth, 
              decay = decay, 
              maxAngle = maxAngle, minAngle = minAngle, 
              step = step, start = tip, 
              distance = myDist);

          
        }
        
      }
    }
  }

}



/*

paramaters:
  * Denotes paramater that is used internally by recursion and is not intended to be
    used from the inital module call
  (suggested values)

  size          [real]        size of first segment (linear from origin)
  depth         [integer]     recusion level (1 to 8)
  widthBottom   [real]        maximum width at base of trunk
  widthTop      [real]        maximum width at top of first trunk segment
  minGrowth     [real]        minimum amount to grow the new branch (0.1 to 1.2)
  maxGrowth     [real]        maximum amount to grow the new branch (0.1 to 1.2)
  decay         [real]        base amount to diminish each branch by (0.5 to 1.2)
  maxAngle      [real]        maximum angle to rotate each branch (0 to 180)
  minAngle      [real]        minimum angle to rotate each branch (0 to 180)
  first         [boolean]     needs to be set to "true" when called 
  *depthMax     [integer]     records maximum depth on first call
  *distance     [integer]     records distance from "trunk" - can be used to diminish
                              branches
  *start        [vector]      records [x, y, z] vector at which to start 
                              growing the branch

*/
module trunk(size = 200, 
             depth = 3,
             depthMax = 1,
             seed = 55, 
             widthBottom = 75, 
             widthTop = 45, 
             minGrowth = 0.8, 
             maxGrowth = 1.2, 
             decay = 0.9, 
             minAngle = 0,
             maxAngle = 30,
             step = 0.01, 
             start = [0, 0, 0], 
             distance = 0, 
             first = false) {



  //select the type of branch
  
  one = 10;
  two = 50;
  branchRand = rands(0, 100, 1, seed+5)[0];

  branchNum = (0 < branchRand && branchRand < one) ? 1 : 
              (one < branchRand && branchRand < two) ? 2 : 3;
  
  myDepthMax = first==true ? depth : depthMax;


  branch(size = size, depth = depth, depthMax = myDepthMax,
        bend = bend, seed = seed+4, 
        widthBottom = widthBottom, widthTop = widthTop, minGrowth = minGrowth, 
        maxGrowth = maxGrowth, decay = decay, 
        minAngle = minAngle,
        maxAngle = maxAngle,
        step = step, 
        start = start, branchNum = branchNum, 
        distance = distance);


}

module willow() {
  trunk(size = 500, seed = 58, bend = 250, depth = 5, decay = .8, 
  widthBottom = 200, widthTop = 75, maxAngle = 130, step = 0.05);
}


  trunk(size = 1000, seed = 22, bend = 100, depth = 6, decay = .95, 
        widthBottom = 300, widthTop = 280, maxGrowth = .9, minGrowth = .8,
        maxAngle = 37, minAngle = 35, step = 0.05, first = true);



//myRnd = rands(-1, 1, 1)[0]>=0 ? 1 : -1;
//echo(myRnd);
