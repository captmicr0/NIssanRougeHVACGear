$fn = 100;
overlap = 0.5;

// GEAR BODY (7.0 mm height)
num_teeth = 48;
gear_outer_dia = 29.50;
tooth_height = 1.5;
gear_body_height = 7.0;
backlash = 0.20;

// Tooth profile bend parameters (at 50% of tooth height)
crease_h = tooth_height * 0.5;
crease_w_factor = 0.65;
tip_w_factor = 0.15;

// TOP POCKET AND CHAMFER
pocket_depth = 2.48;
pocket_width = 4.0;
pocket_chamfer = 1.0;

pedestal_dia = 13.72;
pedestal_height = 6.48;

pocket_inner_dia = pedestal_dia + 2 * pocket_width;

// BOTTOM POCKET
bottom_pocket_depth = 3.2;
bottom_pocket_dia = pocket_inner_dia;

// BOTTOM SHAFT
bottom_shaft_dia = 5.52;
bottom_shaft_height = 5.52;

// TOP SHAFT (Shaft engaging the HVAC flap)
hex_height = 17.0; //18.37 measured on aftermarket actuator
hex_reinforced_pct = 0.45; //perfect of shaft thats reinforced
hex_base_flats = 8.2;
hex_top_flats = 8.1;
groove_size = 2.0; // Grooves for adhesive

hex_d1 = hex_base_flats / cos(30);
hex_d2 = hex_top_flats / cos(30);

render()

union() {
    // === GEAR BODY + TEETH - POCKETS - CHAMFER ===
    difference() {
        // 1. Gear blank with teeth
        union() {
            cylinder(d = gear_outer_dia - 2 * tooth_height, h = gear_body_height);
            base_w = ((PI * (gear_outer_dia - 2 * tooth_height)) / num_teeth) - backlash;
            mid_w = base_w * crease_w_factor;
            top_w = base_w * tip_w_factor;
            for (i = [0 : num_teeth - 1]) {
                rotate([0, 0, i * 360 / num_teeth])
                    translate([(gear_outer_dia - 2 * tooth_height) / 2 - overlap, 0, 0])
                        linear_extrude(height = gear_body_height)
                            polygon(points=[
                                [0, -base_w/2],
                                [crease_h + overlap, -mid_w/2],
                                [tooth_height + overlap, -top_w/2], 
                                [tooth_height + overlap, top_w/2],
                                [crease_h + overlap, mid_w/2],
                                [0, base_w/2]
                            ]);
            }
        }

        // 2. Cut out the top pocket
        translate([0, 0, gear_body_height - pocket_depth])
            cylinder(d = pocket_inner_dia, h = pocket_depth);
        
        // 3. Cut the 45° chamfer on the upper edge (now 2 mm)
        translate([0, 0, gear_body_height - pocket_chamfer])
            cylinder(d1 = pocket_inner_dia, 
                     d2 = pocket_inner_dia + 2 * pocket_chamfer, 
                     h = pocket_chamfer);
        
        // 4. Cut out the bottom pocket
        translate([0, 0, 0])
            cylinder(d = bottom_pocket_dia, h = bottom_pocket_depth);
    }
    
    // === BOTTOM SHAFT ===
    translate([0, 0, bottom_pocket_depth - bottom_shaft_height])
        cylinder(d = bottom_shaft_dia, h = bottom_shaft_height);

    // === PEDESTAL ===
    translate([0, 0, gear_body_height - pocket_depth])
        cylinder(d = pedestal_dia, h = pedestal_height);
    
    // === HEX SHAFT + ADHESIVE GROOVES + REINFORCEMENT ===
    translate([0, 0, gear_body_height - pocket_depth]) {
        translate([0, 0, pedestal_height]) {
            union() {
                // HEX SHAFT + ADHESIVE GROOVES
                difference() {
                    cylinder(d1 = hex_d1, d2 = hex_d2, h = hex_height, $fn = 6);
                    for (a = [30 : 60 : 330]) {
                        rotate([0, 0, a])
                            translate([hex_base_flats/2, 0, hex_height/2])
                                rotate([0, 0, 45])
                                    cube([groove_size, groove_size, hex_height + 5], center=true);
                    }
                }
                cylinder(d = hex_base_flats,
                         h = hex_height * hex_reinforced_pct);
            }
        }
    }
}