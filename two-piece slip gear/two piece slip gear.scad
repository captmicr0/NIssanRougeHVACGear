$fn = 100;
overlap = 0.5;

// === PARAMETERS ===
// Gear Body
num_teeth = 48;
gear_outer_dia = 29.50;
tooth_height = 1.5;
gear_body_height = 7.0;
backlash = 0.20;

// Tooth Profile Bend (at 50% of tooth height)
crease_h = tooth_height * 0.5;
crease_w_factor = 0.65;
tip_w_factor = 0.15;

// Top Pocket and Chamfer
pocket_depth = 2.48;
pocket_width = 4.0;
pocket_chamfer = 1.0;

pedestal_dia = 13.72;
pedestal_height = 7.5; // Measured: 6.6 mm

pocket_inner_dia = pedestal_dia + 2 * pocket_width;

// Bottom Pocket
bottom_pocket_depth = 1.55;
bottom_pocket_dia = pocket_inner_dia;

no_bottom_pocket = true;

// Bottom Shaft
bottom_shaft_dia = 5.52;
bottom_shaft_height = 5.78;

separate_bottom_shaft = true;

// Top Shaft (Engages the HVAC flap)
hex_height = 17.0; // Measured: 18.37 mm on aftermarket actuator
hex_reinforced_pct = 0.45; // Percentage of shaft that is reinforced
hex_base_flats = 8.2;
hex_top_flats = 8.1;
groove_size = 2.0; // Grooves for adhesive

hex_d1 = hex_base_flats / cos(30);
hex_d2 = hex_top_flats / cos(30);

// Slip Joint
slip_cone_base_dia = 9; // Large diameter of cone, excluding splines (mm)
slip_cone_length = 4; // Cone length along central axis (mm)
slip_cone_angle_per_side = 20; // Degrees from central axis (not included angle)

slip_spline_count = 12; // Number of rounded axial splines
slip_spline_height = 1; // Maximum radial height of a spline (mm)
slip_spline_resolution = 10; // Higher values produce smoother splines

slip_radial_clearance = 0.20; // Socket clearance at the wide end (mm)
slip_axial_clearance = 0.35; // Extra depth past the cone tip (mm)
slip_male_slide_clearance = 0.25; // Gear-side socket clearance for vertical movement (mm)
slip_male_slide_pedestal_height = 3;

slip_female_pedestal_height = slip_cone_length + 1;
slip_female_adjust = 0.6;

slip_spring_seat_dia = 8; // Diameter of circular spring pocket (mm)
slip_spring_seat_depth = 1.6; // Depth extension beyond the bottom of hex socket (mm)

base_r = slip_cone_base_dia / 2;
tip_r = base_r - slip_cone_length * tan(slip_cone_angle_per_side);
segments = max(72, slip_spline_count * slip_spline_resolution);

// Metal Rod Insert
metal_rod_dia = 3.2; // Diameter of metal rod for slip joint alignment
metal_rod_slide_clearance = 0.2; // Diameter increase for moving slip joint cutout


// === FUNCTIONS & UTILITIES ===

// Smooth raised lobes (no sharp involute/triangular teeth).
// The flanks are smooth; actual slip torque depends on spring preload.
module spline_profile(radius, amplitude, clearance = 0) {
    polygon(points = [
        for (i = [0 : segments-1])
            let(
                a = 360 * i / segments,
                r = radius
                    + amplitude * (1 + cos(slip_spline_count * a)) / 2
                    + clearance
            )
            [r * cos(a), r * sin(a)]
    ]);
}


// === COMPONENTS ===

// Main driving gear assembly
module gear() {
    difference() {
        union() {
            // Gear body with integrated teeth, pockets, and chamfer
            difference() {
                // Outer gear blank and tooth rendering
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

                // Top pocket cutout
                translate([0, 0, gear_body_height - pocket_depth])
                    cylinder(d = pocket_inner_dia, h = pocket_depth);
                
                // Spring pocket cutout
                translate([0, 0, gear_body_height - pocket_depth - slip_spring_seat_depth])
                    cylinder(d = slip_spring_seat_dia, h = slip_spring_seat_depth);
                
                // Upper edge 45-degree chamfer
                translate([0, 0, gear_body_height - pocket_chamfer])
                    cylinder(d1 = pocket_inner_dia, 
                             d2 = pocket_inner_dia + 2 * pocket_chamfer, 
                             h = pocket_chamfer);
                
                // Bottom pocket configuration
                if (!no_bottom_pocket) {
                    // Option 1: Standard bottom pocket cutout
                    translate()
                        cylinder(d = bottom_pocket_dia, h = bottom_pocket_depth);
                } else {
                    // Option 2: Full gear height reduction cutout
                    translate()
                        cylinder(d = gear_outer_dia + 2 * tooth_height, h = bottom_pocket_depth);
                }
            }
            
            // Integrated bottom shaft extension
            if (!separate_bottom_shaft) {
                translate([0, 0, bottom_pocket_depth - bottom_shaft_height])
                    cylinder(d = bottom_shaft_dia, h = bottom_shaft_height);
            }
            
            // Central pedestal with spline tracking profile
            translate([0, 0, gear_body_height - pocket_depth - 0.002])
                difference() {
                    cylinder(d = pedestal_dia, h = pedestal_height);
                    linear_extrude(height = pedestal_height)
                        spline_profile(base_r, slip_spline_height, slip_male_slide_clearance);
                }
        }
        
        // Alignment rod channel clearance
        translate([0, 0, bottom_pocket_depth - bottom_shaft_height])
            cylinder(d = metal_rod_dia, h = 20);
    }
}

// Standalone bottom shaft component
module bottom_shaft() {
    if (separate_bottom_shaft) {
        difference() {
            // Main shaft geometry
            translate([0, 0, bottom_pocket_depth - bottom_shaft_height])
                cylinder(d = bottom_shaft_dia, h = bottom_shaft_height);
            
            // Internal alignment rod channel
            translate([0, 0, bottom_pocket_depth - bottom_shaft_height])
                cylinder(d = metal_rod_dia, h = bottom_shaft_height);
        }
    }
}

// Male insert of the slip joint assembly
module male() {
    translate([0, 0, gear_body_height + - pocket_depth + pedestal_height - slip_male_slide_pedestal_height])
        translate([0, 0, pedestal_height - slip_cone_length])
            difference() {
                union() {
                    // Conical slip engagement profile
                    linear_extrude(height = slip_cone_length,
                                   scale = tip_r / base_r,
                                   convexity = 10)
                        spline_profile(base_r, slip_spline_height);
                    
                    // Base tracking extension for pedestal alignment
                    translate([0, 0, -slip_male_slide_pedestal_height])
                        linear_extrude(height = slip_male_slide_pedestal_height)
                            spline_profile(base_r, slip_spline_height);
                }
                
                // Spring pocket seat cutout
                translate([0, 0, -slip_male_slide_pedestal_height])
                        cylinder(d = slip_spring_seat_dia, h = slip_spring_seat_depth);
                
                // Center pin clearance hole
                translate([0, 0, -slip_male_slide_pedestal_height])
                    cylinder(d = metal_rod_dia + metal_rod_slide_clearance, h = 20);
            }
}

// Female receiver housing and output drive shaft
module female() {
    translate([0, 0, gear_body_height + pocket_depth])
    difference() {
        union() {
            // Output hex drive profile with integration features
            translate([0, 0, pedestal_height])
                union() {
                    // Hex profile with adhesive relief grooves
                    difference() {
                        cylinder(d1 = hex_d1, d2 = hex_d2, h = hex_height, $fn = 6);
                        for (a = [30 : 60 : 330]) {
                            rotate([0, 0, a])
                                translate([hex_base_flats/2, 0, hex_height/2])
                                    rotate()
                                        cube([groove_size, groove_size, hex_height + 5], center=true);
                        }
                    }
                    // Structural reinforcement sleeve
                    cylinder(d = hex_base_flats,
                             h = hex_height * hex_reinforced_pct);
                }
            
            // Receiver base pedestal
            translate([0, 0, pedestal_height - slip_cone_length])
                cylinder(d = pedestal_dia, h = slip_female_pedestal_height);
        }
        
        // Internal female spline cavity matching male taper
        translate([0, 0, pedestal_height - slip_cone_length - slip_female_adjust])
            linear_extrude(height = slip_cone_length + slip_axial_clearance + 0.02,
                           scale = (tip_r + slip_radial_clearance) /
                                   (base_r + slip_radial_clearance),
                           convexity = 10)
                spline_profile(base_r + slip_radial_clearance,
                               slip_spline_height * (base_r + slip_radial_clearance) / base_r);
        
        // Center pin blind alignment hole
        translate([0, 0, pedestal_height - slip_cone_length])
            // Option 1: Blind hole extending into structural reinforcement
            cylinder(d = metal_rod_dia + metal_rod_slide_clearance, h = slip_cone_length + (hex_height * hex_reinforced_pct * 0.8));
            // Option 2: Full clearance channel through output drive shaft
            // cylinder(d = metal_rod_dia, h = 40);
    }
}

// Mechanical alignment spacers for actuator chassis mounting
module spacer() {
    difference() {
        cylinder(d = 10, h = slip_female_pedestal_height);
        cylinder(d = 4.5, h = slip_female_pedestal_height);
    }
}


// === STAGE RENDERING ===

space_out = false;

group() {
    translate([space_out ? -25 : 0, 0, 0]) gear();
    if (separate_bottom_shaft) { translate([space_out ? -25 : 0, space_out ? -25 : 0, 0]) bottom_shaft(); }
    translate() male();
    translate() translate([space_out ? 25 : 0, 0, 0]) female();
    translate([0,  -25, 0]) spacer();
    translate([15, -25, 0]) spacer();
}