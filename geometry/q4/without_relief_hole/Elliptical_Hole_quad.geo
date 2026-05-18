// -----------------------------------------------------------
// Quarter Plate with Elliptical Hole + Circular Hole (Q4)
// -----------------------------------------------------------

SetFactory("OpenCASCADE");

// ---------------- PARAMETERS ----------------
a = 25.4;        // ellipse minor (x-direction)
b = 45.72;       // ellipse major (y-direction)

W = 254;
H = 254;

lc = 10;

// ---------------- POINTS ----------------
Point(1) = {0, 0, 0, lc};
Point(2) = {a, 0, 0, lc};
Point(3) = {W, 0, 0, lc};
Point(4) = {W, H, 0, lc};
Point(5) = {0, H, 0, lc};
Point(6) = {0, b, 0, lc};   // major axis point

// ---------------- OUTER BOUNDARY ----------------
Line(1) = {2, 3};
Line(2) = {3, 4};
Line(3) = {4, 5};
Line(4) = {5, 6};

// ---------------- ELLIPSE ----------------
// start = (a,0), center = (0,0), major axis = (0,b), end = (0,b)
Ellipse(5) = {2, 1, 6, 6};

// ---------------- SURFACE ----------------
Curve Loop(1) = {1, 2, 3, 4, 5};   // outer + ellipse

Plane Surface(1) = {1};

// ---------------- PHYSICAL GROUPS ----------------
Physical Curve("Bottom Boundary") = {1};
Physical Curve("Left Boundary")   = {4};
Physical Curve("Neumann Boundary") = {2};

Physical Surface("Surface") = {1};

// ---------------- MESH REFINEMENT ----------------

// Ellipse refinement
Field[1] = Distance;
Field[1].CurvesList = {5};
Field[1].Sampling = 50;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = lc/5;
Field[2].SizeMax = lc;
Field[2].DistMin = 20;
Field[2].DistMax = 120;

Background Field = 5;

// ---------------- MESH SETTINGS ----------------

// Quad-dominant mesh
Recombine Surface {1};
Mesh.RecombineAll = 1;
Mesh.Algorithm = 8;

// Stabilization
Mesh.Optimize = 1;
Mesh.Smoothing = 50;

// Export format
Mesh.MshFileVersion = 2.2;