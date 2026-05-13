// -----------------------------------------------------------
//     Elliptical Hole with Circular Relief Hole (Q4 Mesh)
// -----------------------------------------------------------

a = 25.4;
b = 45.72;
W = 254;
H = 254;

cx = 38.10;
cy = 33.02;
r  = 12.70;

lc = 10;

// ------------------ POINTS ------------------
Point(1) = {0, 0, 0, lc};
Point(2) = {a, 0, 0, lc};
Point(3) = {W, 0, 0, lc};
Point(4) = {W, H, 0, lc};
Point(5) = {0, H, 0, lc};
Point(6) = {0, b, 0, lc};

// circle points
Point(7)  = {cx, cy, 0, lc};
Point(8)  = {cx + r, cy, 0, lc};
Point(9)  = {cx, cy + r, 0, lc};
Point(10) = {cx - r, cy, 0, lc};
Point(11) = {cx, cy - r, 0, lc};

// ------------------ OUTER BOUNDARY ------------------
Line(1) = {2, 3};
Line(2) = {3, 4};
Line(3) = {4, 5};
Line(4) = {5, 6};

// ellipse
Ellipse(5) = {6, 1, 2};

// circle
Circle(6) = {8, 7, 9};
Circle(7) = {9, 7, 10};
Circle(8) = {10, 7, 11};
Circle(9) = {11, 7, 8};

// ------------------ SURFACE ------------------
Curve Loop(1) = {1, 2, 3, 4};
Curve Loop(2) = {5};
Curve Loop(3) = {6, 7, 8, 9};

Plane Surface(1) = {1, 2, 3};

// ------------------ PHYSICAL GROUPS ------------------
Physical Curve("Bottom") = {1};
Physical Curve("Left")   = {4};
Physical Curve("Load")   = {2};
Physical Surface("Plate") = {1};

// ------------------ MESH CONTROL ------------------
Field[1] = Distance;
Field[1].CurvesList = {5,6,7,8,9};
Field[1].Sampling = 50;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = lc/10;
Field[2].SizeMax = 2*lc;
Field[2].DistMin = 20;
Field[2].DistMax = 120;

Background Field = 2;

Mesh . MeshSizeExtendFromBoundary = 0;
Mesh . MeshSizeFromPoints = 1;
Mesh . MeshSizeFromCurvature = 0;
Recombine Surface {1}; // Takes pairs of triangles and
merges them into quadrilaterals
Mesh . RecombineAll = 1; // Applies recombination to ALL
surfaces automatically
Mesh . Algorithm = 8; // quad - dominant ( Generate quad -
friendly mesh )