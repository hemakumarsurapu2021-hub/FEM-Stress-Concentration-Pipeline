% =========================================================================
%   run_convergence_study.m
%   MASTER DRIVER — Q4 FEM Mesh Convergence Study
%   Quarter Plate with Elliptical Hole + Circular Relief Hole (Plane Stress)
% =========================================================================
% This script is the ONLY thing the user runs. It:
%   1. Loops over a list of mesh sizes (lc)
%   2. For each lc:  modify .geo  ->  run Gmsh  ->  parse  ->  solve  ->  metrics
%   3. Saves per-case folders (Results/lc_XX/) with .msh, plots, summary
%   4. Aggregates everything into Excel + TXT
%   5. Generates final convergence plots
%
% DATA FLOW (high level):
%
%   meshSizes ──► modifyGeoMeshSize ──► runGmsh ──► copy to hardcoded name
%                                                            │
%                                                            ▼
%                                                     meshParserQ4
%                                                            │
%                                                            ▼
%                                            solveFEM_Q4_QuarterPlate
%                                                            │
%                                                            ▼
%                computeStressQ4 (sxx, syy, txy, Δσ)  ──► hoop on ellipse + circle
%                                                            │
%                                                            ▼
%                                  extractMetrics ─► saveCaseResults (per-case)
%                                                            │
%                                                            ▼
%                                       aggregate ─► plotConvergence + exportResults
%
% PREREQUISITES on MATLAB path (your existing solver — DO NOT MODIFY):
%   meshParserQ4.m
%   Q4elementStiffness.m
%   assembleGlobalStiffnessQ4.m
%   solveFEM_Q4_QuarterPlate.m
%   computeStressQ4.m                         (returns sxx,syy,txy + Δσ)
%   computeHoopStressEllipseQ4.m
%   computeHoopStressCircleQ4.m
%   plotMesh.m
%
% NEW FILES (this pipeline):
%   modifyGeoMeshSize.m
%   runGmsh.m
%   ensureDir.m
%   countElementsOnBoundary.m
%   extractMetrics.m
%   saveCaseResults.m
%   plotConvergence.m
%   exportResults.m
%
% IMPORTANT NOTE — meshParserQ4 quirk:
%   Your meshParserQ4.m ignores its `filename` argument and always opens
%   'Elliptical_Hole_with_circular_hole.msh' from the current directory.
%   Per the "do not rewrite the solver" constraint, this pipeline works
%   around it by COPYING the per-case mesh to that hardcoded name before
%   calling the parser. See callMeshParser() below.
% =========================================================================

clc; clear; close all;

% =========================================================================
%   USER INPUTS (edit here only)
% =========================================================================

% --- The ONLY real input: list of mesh sizes ----------------------------
meshSizes = [25, 20, 15, 12.5, 10, 8, 7, 5];     % lc values in mm (coarse -> fine)

% --- Geometry parameters (MUST match your .geo file) --------------------
geo.a  = 25.4;      % ellipse semi-axis along x (mm)
geo.b  = 45.72;     % ellipse semi-axis along y (mm)
geo.cx = 38.10;     % circular hole centre x (mm)
geo.cy = 25;     % circular hole centre y (mm)
geo.r  = 12.70;     % circular hole radius   (mm)

% --- Material & loading ------------------------------------------------
mat.E       = 70e3;     % Young's modulus (MPa)
mat.nu      = 0.33;     % Poisson's ratio
mat.t       = 5;        % thickness (mm)
mat.sigma_x = 10;       % applied far-field stress (MPa)

% --- Reference value for error analysis --------------------------------
% The assignment specifies the analytical max hoop stress on the ellipse:
ref.sigmaMaxEllipse = 46;       % MPa (analytical reference)
ref.Kt_ellipse      = ref.sigmaMaxEllipse / mat.sigma_x;   % = 4.6

% --- File paths ---------------------------------------------------------
files.geoTemplate     = 'Elliptical_Hole_with_circular_hole.geo';
files.gmshExe         = 'C:\Users\hemak\Downloads\gmsh-4.15.2-Windows64\gmsh-4.15.2-Windows64\gmsh.exe';                  % or full path
files.resultsDir      = 'Results';
files.parserHardcoded = 'Elliptical_Hole_with_circular_hole.msh';  % name parser expects

% --- Pipeline options ---------------------------------------------------
opts.useParfor    = false;   % set true if Parallel Computing Toolbox available
                              % NOTE: set FALSE if relying on the parser-hardcoded
                              % filename workaround — parallel workers in the
                              % same MATLAB workdir will collide on that file.
opts.savePlots    = true;
opts.closeFigures = true;
opts.verbose      = true;

% =========================================================================
%   PIPELINE EXECUTION
% =========================================================================

ensureDir(files.resultsDir);

nCases  = numel(meshSizes);
results = repmat(emptyResultStruct(), nCases, 1);

t0 = tic;

if opts.useParfor
    % If you really want parfor, the parser hardcoding becomes a problem.
    % The safe way is to launch each worker in its OWN tempdir; see comment
    % in callMeshParser() for the workaround.
    parfor i = 1:nCases
        results(i) = runOneCase(meshSizes(i), geo, mat, ref, files, opts);
    end
else
    for i = 1:nCases
        results(i) = runOneCase(meshSizes(i), geo, mat, ref, files, opts);
    end
end

fprintf('\n=== All %d cases completed in %.1f s ===\n', nCases, toc(t0));

% =========================================================================
%   AGGREGATION + EXPORT
% =========================================================================

% Sort coarse-to-fine for natural left-to-right reading
[~, order] = sort([results.lc], 'descend');
results    = results(order);

exportResults(results, files.resultsDir);            % Excel + CSV + TXT
plotConvergence(results, ref, files.resultsDir);     % final plots

fprintf('\nAll outputs saved under: %s\n', files.resultsDir);


% =========================================================================
%   LOCAL FUNCTION:  runOneCase
%   One full pipeline iteration for a single mesh size.
% =========================================================================
function R = runOneCase(lc, geo, mat, ref, files, opts)

    R = emptyResultStruct();
    R.lc = lc;

    caseTag = sprintf('lc_%g', lc);
    caseDir = fullfile(files.resultsDir, caseTag);
    ensureDir(caseDir);

    geoFile = fullfile(caseDir, 'mesh.geo');
    mshFile = fullfile(caseDir, 'mesh.msh');

    try
        % -- 1. modify .geo with this lc --------------------------------
        modifyGeoMeshSize(files.geoTemplate, geoFile, lc);

        % -- 2. run Gmsh ------------------------------------------------
        runGmsh(files.gmshExe, geoFile, mshFile);

        % -- 3. parse mesh (workaround for hardcoded filename) ----------
        [coordinates, elements] = callMeshParser(mshFile, files.parserHardcoded);

        R.nodes    = size(coordinates, 1);
        R.elements = size(elements, 1);

        % -- 4. solve FEM (REUSE — untouched) ---------------------------
        [U, ~, ~, ~, ~] = solveFEM_Q4_QuarterPlate( ...
            coordinates, elements, mat.E, mat.nu, mat.t, mat.sigma_x);

        % -- 5. stress field + Δσ ---------------------------------------
        [~, stressNode, deltaSigmaNode] = computeStressQ4( ...
            coordinates, elements, U, mat.E, mat.nu);

        R.deltaSigmaMax = max(deltaSigmaNode);

        % -- 6. hoop stresses on both boundaries ------------------------
        % NOTE: Q4 ellipse hoop signature does NOT take `elements`
        [~, ~, theta_e, sigma_e] = computeHoopStressEllipseQ4( ...
            coordinates, stressNode, geo.a, geo.b);

        [~, ~, theta_c, sigma_c] = computeHoopStressCircleQ4( ...
            coordinates, stressNode, geo.cx, geo.cy, geo.r);

        % -- 7. boundary element counts ---------------------------------
        R.elemsOnEllipse = countElementsOnBoundary( ...
            coordinates, elements, 'ellipse', geo);
        R.elemsOnCircle  = countElementsOnBoundary( ...
            coordinates, elements, 'circle',  geo);

        % -- 8. metrics (max σθθ, location, SCF, Δσ, error, ratio) ------
        M = extractMetrics(theta_e, sigma_e, theta_c, sigma_c, ...
                           R.deltaSigmaMax, mat, ref);

        R.sigmaMaxEllipse = M.sigmaMaxEllipse;
        R.thetaMaxEllipse = M.thetaMaxEllipse;
        R.sigmaMaxCircle  = M.sigmaMaxCircle;
        R.thetaMaxCircle  = M.thetaMaxCircle;
        R.Kt_ellipse      = M.Kt_ellipse;
        R.Kt_circle       = M.Kt_circle;
        R.ratioCircleToEllipse = M.ratioCircleToEllipse;
        R.absError        = M.absError;
        R.relError        = M.relError;

        % -- 9. boundary stress profiles (for plotting) ----------------
        R.theta_e = theta_e;  R.sigma_e = sigma_e;
        R.theta_c = theta_c;  R.sigma_c = sigma_c;

        % -- 10. per-case plots + summary ------------------------------
        saveCaseResults(caseDir, caseTag, coordinates, elements, U, ...
                        stressNode, deltaSigmaNode, ...
                        theta_e, sigma_e, theta_c, sigma_c, ...
                        R, opts);

        R.success = true;

        if opts.verbose
            fprintf(['[%s]  nodes=%6d  elems=%6d  ' ...
                     'Kt_ell=%.3f  Kt_cir=%.3f  Δσmax=%.2f  err=%.2f%%\n'], ...
                caseTag, R.nodes, R.elements, ...
                R.Kt_ellipse, R.Kt_circle, R.deltaSigmaMax, R.relError);
        end

    catch ME
        R.success = false;
        R.errMsg  = ME.message;
        warning('Case %s FAILED: %s', caseTag, ME.message);
    end
end

% =========================================================================
%   LOCAL FUNCTION:  callMeshParser
%   Workaround for meshParserQ4 hardcoded filename.
%
%   Your meshParserQ4 always opens files.parserHardcoded from the current
%   directory. We copy this case's .msh to that name, run the parser, then
%   leave the copy in place (overwritten next iteration).
%
%   For parfor: each worker has its OWN current directory only if you
%   explicitly cd into a per-worker temp folder at the top of runOneCase.
%   The simpler path for now: keep useParfor=false. The bottleneck is
%   Gmsh + the linear solve, not the loop overhead.
% =========================================================================
function [coordinates, elements] = callMeshParser(mshFile, hardcodedName)
    % Copy the per-case mesh to the name the parser actually opens
    copyfile(mshFile, hardcodedName, 'f');
    [coordinates, elements] = meshParserQ4(hardcodedName);
end

% =========================================================================
%   LOCAL HELPER:  empty result template
% =========================================================================
function R = emptyResultStruct()
    R = struct( ...
        'lc',                   NaN, ...
        'nodes',                NaN, ...
        'elements',             NaN, ...
        'elemsOnEllipse',       NaN, ...
        'elemsOnCircle',        NaN, ...
        'sigmaMaxEllipse',      NaN, ...
        'thetaMaxEllipse',      NaN, ...
        'sigmaMaxCircle',       NaN, ...
        'thetaMaxCircle',       NaN, ...
        'Kt_ellipse',           NaN, ...
        'Kt_circle',            NaN, ...
        'ratioCircleToEllipse', NaN, ...
        'deltaSigmaMax',        NaN, ...
        'absError',             NaN, ...
        'relError',             NaN, ...
        'theta_e', [], 'sigma_e', [], ...
        'theta_c', [], 'sigma_c', [], ...
        'success', false, 'errMsg', '');
end
