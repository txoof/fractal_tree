/*
Create a 2D Fractal Tree using OpenSCAD recursion and Bezier Curves

tl;dr: trunk(first=true); 

All Bezier Functions based on the excellent work of @caterpillar (Justin SDK)
https://openhome.cc/eGossip/OpenSCAD/BezierCurve.html

Thanks to SteveWeber314 for his fractal tree tutorials
https://www.thingiverse.com/steveweber314/about

Releasted under GPL v3


*/

/* 
calculate a coordinate along a bezier curve
paramaters:
  t             [real]        step along the curve
  coord         [vector]      x, y, z vector

returns:
  single coordinate value based on a vector point
*/
function bezierCoordinate(t, coord) = 
  coord[0] * pow((1 - t), 3) + 3 * coord[1] * t * pow((1 - t), 2) +
    3 * coord[2] * pow(t, 2) * (1 - t) + coord[3] * pow(t, 3);

/*
calculate single point along a bezier curve
paramaters:
  t               [real]        step along the curve
  controlPoints   [vector]      x, y, z vector

returns:
  vector of a point along a bezier curve
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

returns:
  vector of length/t_step points along a bezier curve
*/
function bezierCurve(t_step, controlPoints) = 
  [for(t = [0:t_step:1+t_step]) bezierPoint(t, controlPoints)];


/*
generate a vector of four vector control points; first point is always [0, 0]
paramaters:
  seed            [real]      seed for random number generator
  bend            [real]      maximum/minimum deflection for curve
  size            [real]      length, from origin, of curve

returns:
  [[0, 0], [x1, y1], [x2, y2], [x3, y3]]
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
  * Denotes paramater that is used internally by recursion and is not intended to be
    used from the inital module call
  (suggested values in parentheses)

  size          [real]        size of first segment (linear from origin)
  depth         [integer]     recusion level (1 to 8)
  widthBottom   [real]        maximum width at base of trunk
  widthTop      [real]        maximum width at top of first trunk segment
  minGrowth     [real]        minimum amount to grow the new branch (0.1 to 1.2)
  maxGrowth     [real]        maximum amount to grow the new branch (0.1 to 1.2)
  decay         [real]        base amount to diminish each branch by (0.5 to 1.2)
  minAngle      [real]        minimum angle to rotate each branch (0 to 180)
  maxAngle      [real]        maximum angle to rotate each branch (0 to 180)
  branchProb    [vector]      % chance of one, two or three branches occuring
                              [%one, %two, %three] ([10, 40, 50])
  step          [real]        step size to use when generating bezier curves
                              values approaching 0 are smoother, but take much longer
                              to render (0.05)
  *depthMax     [integer]     records maximum depth on first call
  *distance     [integer]     records distance from "trunk" - can be used to diminish
                              branches
  *start        [vector]      records [x, y, z] vector at which to start 
  *branchNum    [integer]     number of branches to draw at each joint (1-3)
*/
module branch(size, 
             depth,
             depthMax,
             seed, 
             bend,
             widthBottom, 
             widthTop, 
             minGrowth, 
             maxGrowth, 
             decay, 
             minAngle,
             maxAngle,
             branchProb,
             step, 
             distance, 
             start,
             branchNum
             ) {



  debug = 0; 

  sizemod = rands(minGrowth, maxGrowth, branchNum, seed+1)[0];

  mySize = size*sizemod;

  controlPoints = randControlPoints(seed = seed, bend = bend, size = mySize);
  
  bezierPoints = bezierCurve(step, controlPoints);

  // diminish the branch width by the depth and the distance from the "trunk"
  myWidthTop = widthTop*(depth+1)/(depthMax-2)/(distance+2);

  //draw the current branch
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

  if (depth > 0 && myWidthTop > 10) { //stop if the depth or width gets too small 
    translate(tip) {
      for (i=[0:branchNum-1]) {
        //select rotation value from the vector
        myRot = i==0 ? rotations[i]/depth : rotations[i];
        //set the distance from the trunk
        myDist = (i==0 && distance == 0 )? 0 : distance+1;
        //rotate the starting position by myRot * direction (ccw, cw)
        rotate([0, 0, direction[i]*myRot]) {
          trunk(size = mySize*decay,  //change size by decay
                depth = depth-1, //decrease depth count
                depthMax = depthMax, //maintain the maximum depth
                seed = seed*(i+5)/(i+1), //add some variability in seed
                bend = bend*decay, //decrease the bend value
                widthBottom = myWidthTop, //new bottom equals this top
                widthTop = widthTop*decayRands[i], //decrease top value 
                minGrowth = minGrowth, //maintain minGrowth
                maxGrowth = maxGrowth, //maintain maxGrowth
                decay = decay, //maintain decay
                minAngle = minAngle, //maintain minAngle
                maxAngle = maxAngle, //maintain maxAngle
                branchProb = branchProb, //maintain branchProb
                step = step, //maintain step
                distance = myDist, //pass current distance from trunk 
                start = tip //start of new banch is tip of this branch
                );
        } //end rotation
      } //end for loop
    } // end translate
  } // end if depth 

}



/*
paramaters:
  * Denotes paramater that is used internally by recursion and is not intended to be
    used from the inital module call
  (suggested values in parentheses)

  first         [boolean]     first - run sets persistent variables for recursion
                              this **MUST** be set to true when the module is called:
                              trunk(first=true); 
  size          [real]        size of first segment (linear from origin)
  depth         [integer]     recusion level (1 to 8)
  widthBottom   [real]        maximum width at base of trunk
  widthTop      [real]        maximum width at top of first trunk segment
  minGrowth     [real]        minimum amount to grow the new branch (0.1 to 1.2)
  maxGrowth     [real]        maximum amount to grow the new branch (0.1 to 1.2)
  decay         [real]        base amount to diminish each branch by (0.5 to 1.2)
  minAngle      [real]        minimum angle to rotate each branch (0 to 180)
  maxAngle      [real]        maximum angle to rotate each branch (0 to 180)
  branchProb    [vector]      % chance of one, two or three branches occuring
                              [%one, %two, %three] ([10, 40, 50])
  step          [real]        step size to use when generating bezier curves
                              values approaching 0 are smoother, but take much longer
                              to render (0.05)
  *depthMax     [integer]     records maximum depth on first call
  *distance     [integer]     records distance from "trunk" - can be used to diminish
                              branches
  *start        [vector]      records [x, y, z] vector at which to start 
                              growing the branch

*/
module trunk(first = false,
             size = 1000, 
             depth = 6,
             depthMax = 1,
             seed = 22, 
             bend = 100,
             widthBottom = 300, 
             widthTop = 280, 
             minGrowth = 0.8, 
             maxGrowth = .9, 
             decay = 0.95, 
             minAngle = 35,
             maxAngle = 37,
             branchProb = [10, 50, 40],
             step = 0.05, 
             distance = 0, 
             start = [0, 0, 0]
             ) {


  //select the type of branch
  
//  one = 10;
//  two = 50;
  brOne = branchProb[0];
  brTwo = branchProb[0]+branchProb[1];

  branchRand = rands(0, 100, 1, seed+5)[0];



  //choose the type of branch
  branchNum = (branchRand < brOne) ? 1 : 
              (brOne < branchRand && branchRand < brTwo) ? 2 : 3;
  
  
  //check if this is the first run; record the depthMax for use later
  myDepthMax = first==true ? depth : depthMax;


  branch(size = size, 
         depth = depth, 
         depthMax = myDepthMax,
         seed = seed+4, 
         bend = bend,         
         widthBottom = widthBottom, 
         widthTop = widthTop, 
         minGrowth = minGrowth, 
         maxGrowth = maxGrowth, 
         decay = decay, 
         minAngle = minAngle,
         maxAngle = maxAngle,
         branchProb = branchProb,
         step = step, 
         distance = distance,
         start = start, 
         branchNum = branchNum 
         );

}

module willow() {
  trunk(size = 500, seed = 58, bend = 250, depth = 5, decay = .8, 
  widthBottom = 200, widthTop = 75, maxAngle = 130, step = 0.05);
}


//  trunk(size = 1000, seed = 22, bend = 100, depth = 6, decay = .95, 
//        widthBottom = 300, widthTop = 280, maxGrowth = .9, minGrowth = .8,
//        maxAngle = 37, minAngle = 35, step = 0.05, first = true);

trunk(first = true);

