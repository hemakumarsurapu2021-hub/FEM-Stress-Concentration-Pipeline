FEM Mesh Convergence Automation Pipeline
=========================================
Q4 Element | Quarter Plate with Elliptical Hole | Plane Stress

────────────────────────────────────────────────────────────────────────────
FILE LAYOUT
────────────────────────────────────────────────────────────────────────────

YOUR PROJECT FOLDER/
├── run_convergence_study.m        ← MASTER SCRIPT  (run this)
│
├── ── Automation helpers ──
├── runSingleCase.m                ← Orchestrates one lc run
├── modifyGeoMeshSize.m            ← Edits lc= line in .geo file
├── runGmsh.m                      ← System-calls Gmsh
├── countElemsOnEllipse.m          ← Counts elements on hole boundary
├── saveCasePlots.m                ← Saves per-case PNG/PDF figures
├── plotConvergence.m              ← σ_θθ_max vs Elements + error plot
├── exportResults.m                ← Writes .xlsx and .txt
├── tableHelpers.m                 ← initResultsTable / fillRow
├── utils.m                        ← ensureDir / validateConfig
│
├── ── Your existing FEM core (DO NOT modify) ──
├── meshParserQ4.m
├── Q4elementStiffness.m
├── assembleGlobalStiffnessQ4.m
├── solveFEM_Q4_QuarterPlate.m
├── computeStressQ4.m
├── computeHoopStressEllipseQ4.m
│
├── Elliptical_Hole_quad.geo       ← Your original .geo template
│
└── Results/                       ← Auto-created on first run
    ├── lc_20mm/
    │   ├── lc_20mm.geo
    │   ├── lc_20mm.msh
    │   ├── results.mat
    │   └── plots/
    │       ├── lc_20mm_mesh.png / .pdf
    │       ├── lc_20mm_Ux.png / .pdf
    │       ├── lc_20mm_Uy.png / .pdf
    │       ├── lc_20mm_sigma_xx.png / .pdf
    │       ├── lc_20mm_sigma_yy.png / .pdf
    │       ├── lc_20mm_tau_xy.png / .pdf
    │       └── lc_20mm_hoop_stress.png / .pdf
    ├── lc_10mm/ ...
    ├── lc_5mm/  ...
    │
    ├── convergence_plot.png / .pdf
    ├── error_plot.png / .pdf
    ├── convergence_results.xlsx   ← Sheet1: Results, Sheet2: Config
    └── convergence_results.txt

────────────────────────────────────────────────────────────────────────────
QUICK START
────────────────────────────────────────────────────────────────────────────

1. Place ALL files in the same folder (or add them to your MATLAB path).

2. Open run_convergence_study.m and edit the CONFIG section:

   cfg.meshSizes = [20, 15, 10, 8, 5, 3];   % your lc values in mm
   cfg.gmshPath  = 'gmsh';                   % path to Gmsh executable
   cfg.geoTemplate = 'Elliptical_Hole_quad.geo';

3. Run:
   >> run_convergence_study

────────────────────────────────────────────────────────────────────────────
GMSH PATH BY PLATFORM
────────────────────────────────────────────────────────────────────────────

   Windows : cfg.gmshPath = 'C:/Program Files/Gmsh/gmsh.exe';
   macOS   : cfg.gmshPath = '/Applications/Gmsh.app/Contents/MacOS/gmsh';
   Linux   : cfg.gmshPath = 'gmsh';   % if installed to /usr/bin or ~/.local

   To test from MATLAB terminal:
   >> system('"C:/Program Files/Gmsh/gmsh.exe" --version')

────────────────────────────────────────────────────────────────────────────
ANALYTICAL REFERENCE (Kirsch — Elliptical Hole)
────────────────────────────────────────────────────────────────────────────

   σ_θθ(θ=90°) = σ_x · (1 + 2b/a)

   With a = 25.40 mm (x semi-axis), b = 45.72 mm (y semi-axis):
   σ_θθ = 10 · (1 + 2·45.72/25.40) = 46.0 MPa  (approx.)

   This value is auto-computed in cfg.sigma_analytical and used for
   both the convergence plot reference line and error calculation.

────────────────────────────────────────────────────────────────────────────
PARALLEL COMPUTING
────────────────────────────────────────────────────────────────────────────

   Requires: MATLAB Parallel Computing Toolbox

   Enable with:   cfg.useParallel = true;

   Each case runs in its own folder, so there are no file conflicts.
   Plots are generated with 'Visible','off' — no GUI flicker.

   NOTE: parfor cannot use structs with handle-class fields. The master
   script unpacks cfg into plain variables before the parfor loop.

────────────────────────────────────────────────────────────────────────────
DATA COLLECTED PER MESH
────────────────────────────────────────────────────────────────────────────

   Column               Description
   ──────────────────   ─────────────────────────────────────────
   lc_mm                Mesh size parameter passed to Gmsh
   CaseName             Folder/file label  (e.g. lc_10mm)
   Nodes                Total nodes in mesh
   Elements             Total Q4 elements
   ElemsOnHole          Elements whose centroid is on the ellipse
   SigmaMax_MPa         max σ_θθ along elliptical boundary
   SigmaAnalytical_MPa  Kirsch analytical solution
   AbsError_MPa         |FEM − Analytical|
   RelError_pct         100 × |FEM − Analytical| / Analytical

────────────────────────────────────────────────────────────────────────────
TROUBLESHOOTING
────────────────────────────────────────────────────────────────────────────

  Error: "Gmsh failed (exit code 1)"
  → Check cfg.gmshPath. Test it with system('"<path>" --version').

  Error: "Template .geo file not found"
  → The file must be in pwd (MATLAB current folder) or use full path.

  Warning: "No ellipse points detected"
  → The mesh is very coarse; try a smaller upper bound for lc.

  Error: "exportgraphics not found"
  → Requires MATLAB R2020a+. Replace with print() for older versions:
    print(fig, base, '-dpng', '-r150');

────────────────────────────────────────────────────────────────────────────
