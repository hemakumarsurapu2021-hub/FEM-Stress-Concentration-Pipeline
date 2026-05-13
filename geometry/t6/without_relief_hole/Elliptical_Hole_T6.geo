// -----------------------------------------------------------
// 			Elliptical Hole
// -----------------------------------------------------------

a = 25.4; 			// minor axis of elliptical hole in mm
b = 45.72;			// major axis of elliptical hole in mm
W = 254; 			// Width of quarter plate in mm
H = 254; 			// Height of quarter plate in mm

lc = 10; 			// mesh element size in mm

Point(1) = {0, 0, 0, lc};	// inputs are 3D coordinates
Point(2) = {a, 0, 0, lc};
Point(3) = {W, 0, 0, lc};
Point(4) = {W, H, 0, lc};
Point(5) = {0, H, 0, lc};
Point(6) = {0, b, 0, lc};

Line(1) = {2, 3};		// inputs are points
Line(2) = {3, 4};
Line(3) = {4, 5};
Line(4) = {5, 6};

Ellipse(5) = {6, 1, 2};

Curve Loop(1) = {1, 2, 3, 4, 5};		// inputs are lines
Plane Surface(1) = {1};				// input is curve loop


Physical Curve("Bottom Boundary") = {1};	// input is line
Physical Curve("Left Boundary") = {4};
Physical Curve("Neumann Boundary") = {2};
Physical Surface("Surface") = {1};		// input is Plane surface

Field[1] = Distance;
Field[1].CurvesList = {5};
Field[1].Sampling = 100;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = lc / 8;
Field[2].SizeMax = lc;
Field[2].DistMin = 5;
Field[2].DistMax = 60;

Background Field = 2;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 1;
Mesh.MeshSizeFromCurvature = 1;

Mesh.RecombineAll = 0;

Mesh.ElementOrder = 2;
Mesh.SecondOrderIncomplete = 0;

Mesh.Algorithm = 5;
Mesh.Smoothing = 10;

Mesh.MshFileVersion = 2.2;