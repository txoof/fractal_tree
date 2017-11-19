use <./bezier_tree.scad>
use <../libraries/colors.scad>

myColors = colorArray(100, 1);
//echo(myColors);i

mySeed = round($t*100);
color(myColors[mySeed][0])
//trunk(size = 1500, bend = 101, seed = mySeed, widthBottom = 300, widthTop = 280,
//      maxAngle = 15, minAngle = 15, branchProb = [10, 50, 30],
//      maxGrowth = 1.0, decay = .93, depth = 4, distance = 1);
trunk(seed = mySeed);

translate([0, -500])
  color("red")
  text(str("Seed: ", mySeed), size = 400, halign = "center");
