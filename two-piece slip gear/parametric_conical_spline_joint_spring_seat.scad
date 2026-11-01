/*
  Parametric conical spline coupling (male + matching female)
  Units: millimeters

  Rounded longitudinal splines use smooth cosine-profile lobes.
  This is a geometric coupling only; spring force determines slipping torque.

  Select part = "male", "female", or "both"; press F6 to render.
  Select an individual part before exporting STL.
*/

// -------- EDIT THESE PARAMETERS --------
part = "both";                 // ["both", "male", "female"]

shaft_diameter = 13.72;          // Cylinder OD, both parts (mm)

male_length = 16;             // Straight male cylinder length (mm)
female_length = 16;           // Female cylinder length (mm)

spring_seat_diameter = 5;     // Diameter of circular spring pocket (mm)
spring_seat_depth = 3;        // Pocket extends beyond bottom of hex socket (mm)

hex_across_flats = 8.1;       // Male rear hex socket, flat-to-flat (mm)
hex_depth = 10;              // Depth of hex socket from rear face (mm)

cone_base_diameter = 10;      // Cone's large diameter, excluding splines (mm)
cone_length = 10;              // Cone length along axis (mm)
cone_angle_per_side = 10;     // Degrees from central axis, NOT included angle

spline_count = 12;           // Number of rounded axial splines
spline_height = 1;        // Maximum radial height of a spline (mm)

radial_clearance = 0.20;     // Socket clearance at wide end (mm)
axial_clearance = 0.35;      // Extra depth past cone tip (mm)

female_shaft_length = 20;       // Length of projecting female drive shaft (mm)
female_hex_across_flats = 10;  // Hex envelope measured across its six flats (mm)

female_v_depth = 3.4;         // Depth of each V notch, inward from flat (mm)
female_v_start = 0.2;       // Fraction along each flat where notch begins (0..0.5)
female_reinforcement_diameter = female_hex_across_flats; // Round core diameter at base of notched shaft (mm)
female_reinforcement_fraction = 0.45; // Fraction of shaft length reinforced (0..1)

preview_spacing = 8;         // Gap between preview parts (mm)
resolution_per_spline = 10;  // Higher = smoother
// ---------------------------------------

$fn = 96;

base_r = cone_base_diameter / 2;
tip_r = base_r - cone_length * tan(cone_angle_per_side);
segments = max(72, spline_count * resolution_per_spline);

assert(cone_angle_per_side > 0 && cone_angle_per_side < 85,
       "Cone angle must be between 0 and 85 degrees");
assert(tip_r > 0.4,
       "Cone length/angle makes tip radius zero or negative; shorten cone, decrease angle, or increase cone base diameter");
assert(cone_base_diameter + 2 * spline_height < shaft_diameter,
       "Cone plus splines must be smaller than shaft diameter");
assert(radial_clearance >= 0 && spline_height >= 0,
       "Clearance and spline height must be nonnegative");
assert(spline_count >= 3, "At least three splines required");
assert(hex_across_flats > 0 && hex_across_flats / cos(30) < shaft_diameter,
       "Hex socket must fit inside male cylinder");
assert(hex_depth > 0 && hex_depth < male_length,
       "Hex depth must be positive and shorter than the straight male cylinder");
assert(spring_seat_diameter > 0 && spring_seat_diameter <= hex_across_flats,
       "Spring pocket diameter must fit inside the hex flats");
assert(spring_seat_depth > 0 && hex_depth + spring_seat_depth < male_length,
       "Spring pocket must end before the cone begins");
assert(female_hex_across_flats > 0 && female_hex_across_flats / cos(30) <= shaft_diameter,
       "Female drive shaft must fit on the back of the cylinder");
assert(female_v_depth >= 0 && female_v_depth < female_hex_across_flats / 2,
       "V depth must be nonnegative and less than the hex apothem");
assert(female_v_start > 0 && female_v_start < 0.5,
       "V start must be between 0 and 0.5");
assert(female_shaft_length > 0, "Female drive shaft length must be positive");
assert(female_reinforcement_diameter > 0 && female_reinforcement_diameter <= female_hex_across_flats / cos(30),
       "Reinforcement core diameter must fit inside the hex corner envelope");
assert(female_reinforcement_fraction >= 0 && female_reinforcement_fraction <= 1,
       "Reinforcement fraction must be from 0 to 1");
assert(female_length > cone_length + axial_clearance + 1,
       "Female cylinder must be longer than cone depth plus clearance");

// Smooth raised lobes (no sharp involute/triangular teeth).
// The flanks are smooth; actual slip torque depends on spring preload.
module spline_profile(radius, amplitude) {
    polygon(points = [
        for (i = [0 : segments-1])
            let(a = 360 * i / segments,
                r = radius + amplitude * (1 + cos(spline_count * a)) / 2)
            [r * cos(a), r * sin(a)]
    ]);
}

// Cone shrinks toward the tip; ribs run axially down the conical face.
module male() {
    difference() {
        union() {
            cylinder(d = shaft_diameter, h = male_length);
            translate([0, 0, male_length - 0.01])
                linear_extrude(height = cone_length + 0.01,
                               scale = tip_r / base_r,
                               convexity = 10)
                    spline_profile(base_r, spline_height);
        }
        // Blind hex socket opens on the BACK (z=0) of the male cylinder.
        // A six-sided cylinder's diameter is corner-to-corner, hence /cos(30).
        translate([0, 0, -0.02])
            cylinder(d = hex_across_flats / cos(30),
                     h = hex_depth + 0.02, $fn = 6);
        // Circular spring seat recessed into the floor of the blind hex socket.
        translate([0, 0, hex_depth - 0.01])
            cylinder(d = spring_seat_diameter,
                     h = spring_seat_depth + 0.01);
    }
}

// Rear drive shaft profile: a hexagon with a V-notch in EACH flat.
// Six outer HEX CORNERS are retained at angles 0, 60, 120... degrees.
// Six V valleys are centered on the FLATS at 30, 90, 150... degrees.
// The resulting corners act as six raised axial drive ribs.
function lerp2(p, q, t) = [p[0] + (q[0] - p[0]) * t,
                            p[1] + (q[1] - p[1]) * t];
function hex_vertex(i) =
    let(r = female_hex_across_flats / (2 * cos(30)), a = 60 * i)
    [r * cos(a), r * sin(a)];

module female_drive_profile() {
    polygon(points = [
        for (i = [0:5])
            each [
                hex_vertex(i),
                lerp2(hex_vertex(i), hex_vertex((i + 1) % 6), female_v_start),
                let(a = 60 * i + 30, r = female_hex_across_flats / 2 - female_v_depth)
                    [r * cos(a), r * sin(a)],
                lerp2(hex_vertex(i), hex_vertex((i + 1) % 6), 1 - female_v_start)
            ]
    ]);
}

// Matching socket opens on the BOTTOM z=0 face, tapering inward.
// The notched hex drive shaft projects from the opposite/back end.
module female() {
    union() {
        difference() {
            cylinder(d = shaft_diameter, h = female_length);
            translate([0, 0, -0.02])
                linear_extrude(height = cone_length + axial_clearance + 0.02,
                               scale = (tip_r + radial_clearance) /
                                       (base_r + radial_clearance),
                               convexity = 10)
                    spline_profile(base_r + radial_clearance,
                                   spline_height * (base_r + radial_clearance) / base_r);
        }
        translate([0, 0, female_length - 0.01]) {
            // Full-length, six-finned drive profile.
            linear_extrude(height = female_shaft_length + 0.01)
                female_drive_profile();
            // Round reinforcing core fills the inner V valleys near the base,
            // then stops halfway up so the outer end remains flexible.
            cylinder(d = female_reinforcement_diameter,
                     h = female_shaft_length * female_reinforcement_fraction + 0.01);
        }
    }
}

if (part == "male") {
    male();
} else if (part == "female") {
    female();
} else if (part == "both") {
    male();
    translate([shaft_diameter + preview_spacing, 0, 0]) female();
} else {
    assert(false, "part must be male, female, or both");
}

echo("Cone tip diameter (before splines):", 2 * tip_r);
echo("Cone included angle:", 2 * cone_angle_per_side);
