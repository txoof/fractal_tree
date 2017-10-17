//fractal tree demo
use <./fractal_tree.scad>

rows = 5;
columns = 10;
box = [300, 250];

module array() {
  for (i = [0:columns-1]) {
    for (j = [0:rows-1]) {
      translate([i*box[0], j*box[1]])
        linear_extrude(height = 1, center = true) {
          trunk(size = 45, seed = j*10+i);
        }
      
      translate([i*box[0], j*box[1]-40])
        color("red")
        text(str(j*10+i), size = 40, halign = "center");
    }
  }

}


module animate() {
  seed = round($t*100);
  trunk(seed=seed);
  translate([0, -40])
    color("red")
    text(str("seed: ", seed), size = 40, halign = "center");
}

//array();
animate();

