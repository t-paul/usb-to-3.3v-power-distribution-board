// USB to 3.3v Power Distribution Board
//
// Torsten Paul <Torsten.Paul@gmx.de>, November 2023
// CC BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

/* [Part Selection] */
selection = 0; // [ 0:Assembly, 1:Bottom, 2:Top ]

/* [Hidden] */

eps = 0.1;
tolerance = 0.3;
wall = 2;
layer = 0.15;

pcb_length = 150;
pcb_width = 20;
pcb_hole_dia = 3.2;
pcb_thickness = 1.6;

usb_height = 10.75;
usb_width = 12.1;

led_dia = 5;

case_offset = 2;
case_x_offset = 3.5;
case_width_1 = 53;
case_height_1 = 22;
case_height_2 = 12;

// JST PH 2-pin
// https://www.jst.co.uk/downloads/series/TSSC017.01(PH).pdf
conn_width = 5;
conn_length = 6.5;
conn_offset = 61;
conn_pin_offset = 1.8;
conn_spacing = 7;
conn_count = 12;

bottom_height = 2 * wall;

// International ISO Standard 7380-1
// https://cdn.standards.iteh.ai/samples/78699/a175805085534f98983d6c8aa583a5b0/ISO-7380-1-2022.pdf
screw_dia = 3.1;
screw_head_dia = 5.7;
screw_head_height = 1.65;
screw_length = 10;

module screw_hole(d = 3, o = 1) {
	polygon([for (a = [0:359]) (d/2 + o * sin(a * 5)) * [ -sin(a), cos(a) ]]);
}

module pcb_shape(length = pcb_length) {
	translate([0, -pcb_width/2])
		square([length, pcb_width]);
	translate([-case_x_offset, -pcb_width/2])
		square([case_x_offset + 1, pcb_width]);
}

module holes_pos(z = 0, range = undef) {
	pos = [for (x = [15,15+130], y = [-6,6]) [x, y, z]];
	range = is_undef(range) ? [0:1:len(pos)-1] : range;
	for (idx = range)
		translate(pos[idx])
			mirror([0, 1 - idx % 2, 0])
				children();
}

module led_pos(z = 0) {
	translate([20, 0, z])
		children();
}

module conn_pos(z = 0) {
	o = conn_offset - conn_pin_offset + conn_width / 2;
	for (a = [0:conn_count - 1])
		translate([o + a * conn_spacing, 0, z])
			children();
}

module chamfer(r, w) {
	difference() {
		rotate_extrude()
			translate([0, -2 * eps])
				square([w + r, w + eps]);
		rotate_extrude()
			translate([r + w, w - eps])
				circle(w);
	}
}

module top() {
	pcb_top = bottom_height +  wall + pcb_thickness;
	difference() {
		union() {
			difference() {
				union() {
					linear_extrude(case_height_1)
						offset(wall)
							offset(case_offset)
								pcb_shape(case_width_1);
					linear_extrude(case_height_2)
						offset(wall)
							offset(case_offset)
								pcb_shape();
				}
				translate([0, 0, -wall])
					linear_extrude(case_height_1)
						offset(case_offset)
							pcb_shape(case_width_1);
				translate([0, 0, -wall])
					linear_extrude(case_height_2)
						offset(case_offset)
							pcb_shape();
			}
			union() {
				d = pcb_hole_dia + 2 * wall;
				holes_pos(pcb_top, range = [0, 1]) hull() {
					h = case_height_1 - pcb_top - eps;
					cylinder(h = h, d = d);
					translate([-d / 2, 7, 0]) cube([2 * d, eps, h]);
				}
				hull() holes_pos(pcb_top, range = [2, 3]) {
					h = case_height_2 - pcb_top - eps;
					cylinder(h = h, d = d);
					translate([5, 4, 0]) cylinder(h = h, d = d);
				}
				holes_pos(case_height_1 - wall, range = [0, 1])
					translate([0, 0, 0]) mirror([0, 0, 1]) chamfer(d / 2, wall);
				holes_pos(case_height_2 - wall, range = [2, 3])
					translate([0, 0, 0]) mirror([0, 0, 1]) chamfer(d / 2, wall);
			}
		}
		// Screw holes
		holes_pos()
			translate([0, 0, pcb_top - eps])
				linear_extrude(screw_length - pcb_top + 4 * tolerance, scale = 0.9, convexity = 3)
					screw_hole(screw_dia, tolerance);
		// JST Connectors PH
		conn_pos(case_height_2 - wall - eps)
			linear_extrude(wall + 2 * eps, scale = 1.0)
				offset(1) offset(-1) offset(tolerance)
					square([conn_width, conn_length], center = true);
		// 5mm LED
		led_pos()
			cylinder(h = 50, d = led_dia + 2 * tolerance, center = true);
		// USB B Socket
		translate([-wall - case_x_offset, 0, pcb_top + 2 * tolerance + usb_height/2])
			rotate([0, 90, 0])
				linear_extrude(3 * wall, center = true)
					offset(2 * tolerance)
						square([usb_height, usb_width], center = true);
	}
}

module bottom() {
	difference() {
		union() {
			linear_extrude(bottom_height)
				offset(case_offset - tolerance)
					pcb_shape();
			holes_pos(bottom_height - eps) union() {
				d = pcb_hole_dia + 2 * wall;
				cylinder(h = wall, d = d);
				chamfer(d / 2, wall);
			}
		}
		holes_pos() {
			d1 = screw_head_dia + 2 * tolerance;
			h1 = screw_head_height + tolerance;
			d2 = pcb_hole_dia + 2 * tolerance;
			h2 = 4 * wall;
			floating_hole(d1, h1, d2, h2, eps = eps, layer = layer);
		}
	}
}

module floating_hole(d1, h1, d2, h2, eps = 0.01, layer = 0.2) {
	translate([0, 0, -eps]) {
		cylinder(d = d1, h = h1 + eps);
		cylinder(d = d2, h = h2 + eps);
	}
	translate([0, 0, h1 - eps]) linear_extrude(layer + eps) intersection() {
		circle(d = d1);
		square([d1, d2], center = true);
	}
	translate([0, 0, h1 + layer - eps]) linear_extrude(layer + eps) intersection() {
		circle(d = d1);
		square(d2, center = true);
	}
}

parts = [
    [ "assembly", [0, 0,  0 ], [ 0, 0, 0], undef],
    [ "bottom",   [0, 0,  0 ], [ 0, 0, 0], undef],
    [ "top",      [0, 0, 40 ], [ 0, 0, 0], undef]
];

module part_select() {
    for (idx = [0:1:$children-1]) {
        if (selection == 0) {
            col = parts[idx][3];
            translate(parts[idx][1])
                rotate(parts[idx][2])
                    if (is_undef(col))
                        children(idx);
                    else
                        color(col[0], col[1])
                            children(idx);
        } else {
            if (selection == idx)
                children(idx);
        }
    }
}

part_select() {
	union() {}
	bottom();
    top();
}

$fa = 2; $fs = 0.2;
