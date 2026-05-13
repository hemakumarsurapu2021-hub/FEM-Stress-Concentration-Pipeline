// -----------------------------------------------------------
// 	Elliptical Hole With Circular Hole (T6 VERSION)
// -----------------------------------------------------------

a = 25.4;
b = 45.72;
W = 254;
H = 254;

cx = 38.10;
cy = 33.02;
r  = 12.70;

lc = 10;

// -------------------- POINTS --------------------
Point(1) = {0, 0, 0, lc};
Point(2) = {a, 0, 0, lc};
Point(3) = {W, 0, 0, lc};
Point(4) = {W, H, 0, lc};
Point(5) = {0, H, 0, lc};
Point(6) = {0, b, 0, lc};

// Circle
Point(7)  = {cx, cy, 0, lc};
Point(8)  = {cx + r, cy, 0, lc};
Point(9)  = {cx, cy + r, 0, lc};
Point(10) = {cx - r, cy, 0, lc};
Point(11) = {cx, cy - r, 0, lc};

// -------------------- LINES --------------------
Line(1) = {2, 3};
Line(2) = {3, 4};
Line(3) = {4, 5};
Line(4) = {5, 6};

// Ellipse
Ellipse(5) = {6, 1, 2};

// Circle arcs
Circle(6) = {8, 7, 9};
Circle(7) = {9, 7, 10};
Circle(8) = {10, 7, 11};
Circle(9) = {11, 7, 8};

// -------------------- SURFACE --------------------
Curve Loop(1) = {1, 2, 3, 4};
Curve Loop(2) = {5};
Curve Loop(3) = {6, 7, 8, 9};

Plane Surface(1) = {1, 2, 3};

// -------------------- PHYSICAL GROUPS --------------------
Physical Curve("Bottom Boundary") = {1};
Physical Curve("Left Boundary") = {4};
Physical Curve("Neumann Boundary") = {2};
Physical Surface("Surface") = {1};

// -------------------- MESH CONTROL --------------------

// Ellipse refinement
Field[1] = Distance;
Field[1].CurvesList = {5};
Field[1].Sampling = 50;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = lc/8;
Field[2].SizeMax = lc;
Field[2].DistMin = 20;
Field[2].DistMax = 150;

// Circle refinement
Field[3] = Distance;
Field[3].CurvesList = {6,7,8,9};
Field[3].Sampling = 50;

Field[4] = Threshold;
Field[4].InField = 3;
Field[4].SizeMin = lc/8;
Field[4].SizeMax = lc;
Field[4].DistMin = 20;
Field[4].DistMax = 100;

// Combine
Field[5] = Min;
Field[5].FieldsList = {2, 4};

Background Field = 5;


// USE TRIANGULAR MESH
Mesh.Algorithm = 6;  // Frontal-Delaunay (good for triangles)

// ENABLE SECOND ORDER ELEMENTS (T6)
Mesh.ElementOrder = 2;

// Optional but recommended
Mesh.SecondOrderLinear = 0;   // curved edges (important for ellipse)
Mesh.HighOrderOptimize = 1;

// Keep your controls
Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 1;
Mesh.MeshSizeFromCurvature = 0;