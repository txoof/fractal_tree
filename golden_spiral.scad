function fibonacci(nth) = 
    nth == 0 || nth == 1 ? nth : (
        fibonacci(nth - 1) + fibonacci(nth - 2)
    );

module sector(radius, angles, fn = 24) {
    r = radius / cos(180 / fn);
    step = -360 / fn;

    points = concat([[0, 0]],
        [for(a = [angles[0] : step : angles[1] - 360]) 
            [r * cos(a), r * sin(a)]
        ],
        [[r * cos(angles[1]), r * sin(angles[1])]]
    );

    difference() {
        circle(radius, $fn = fn);
        polygon(points);
    }
}

module arc(radius, angles, width = 1, fn = 24) {
    difference() {
        sector(radius + width, angles, fn);
        sector(radius, angles, fn);
    }
} 

module golden_spiral(from, to, thickness) {
    if(from <= to) {
        f1 = fibonacci(from);
        f2 = fibonacci(from + 1);

        arc(f1, [0, 90], thickness, 48);

        offset = f2 - f1;

        translate([0, -offset, 0]) rotate(90)
            golden_spiral(from + 1, to, thickness);
    }
}

golden_spiral(1, 10, 1); 
