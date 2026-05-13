% =========================================================================
%   run_convergence_study_T6.m
%   MASTER DRIVER — T6 FEM Mesh Convergence Study
%   Quarter Plate with Elliptical Hole + Circular Relief Hole (Plane Stress)
% =========================================================================
% This script is the ONLY thing the user runs. It:
%   1. Loops over a list of mesh sizes (lc)
%   2. For each lc:  modify .geo  ->  run Gmsh  ->  parse  ->  solve  ->  metrics
%   3. Saves per-case folders (Results/lc_XX/) with .msh, plots, summary
%   4. Aggregates everything into Excel / TXT / CSV
%   5. Generates final convergence plots
%
% DATA FLOW (high level):
%
%   meshSizes  ──>  modifyGeoMeshSize  ──>  runGmsh  ──>  meshParserT6
%                                                              │
%                                                              ▼
%                                              solveFEM_T6_QuarterPlate
%                                                              │
%                                                              ▼
%                                  computeStressT6 ─> hoop stress (ellipse + circle)
%                                                              │
%                                                              ▼
%                                  computeMetrics  ─> saveResults (per-case)
%                                                              │
%                                                              ▼
%                                       aggregate ─> plotConvergence + Excel/CSV/TXT
%
% PREREQUISITES on MATLAB path (your existing solver — DO NOT MODIFY):
%   meshParserT6.m
%   T6elementStiffness.m
%   assembleGlobalStiffnessT6.m
%   solveFEM_T6_QuarterPlate.m
%   computeStressT6.m
%   computeHoopStressEllipseT6.m
%   computeHoopStressCircleT6.m
%   plotMesh.m
%   postProcess_T6.m
%
% NEW FILES (this pipeline):
%   modifyGeoMeshSize.m
%   runGmsh.m
%   countElementsOnBoundary.m
%   computeMetrics.m
%   saveResults.m
%   plotConvergence.m
% =========================================================================

clc; clear; close all;

% =========================================================================
%   USER INPUTS (edit here only)
% =========================================================================

% --- The ONLY real input: list of mesh sizes to study --------------------
meshSizes = [25, 20, 15, 12.5, 10, 8, 7, 5, 4];   % lc values in mm (coarse -> fine)

% --- Geometry parameters (MUST match your .geo file) ---------------------
geo.a  = 25.4;     % ellipse semi-axis along x (mm)
geo.b  = 45.72;    % ellipse semi-axis along y (mm)
geo.cx = 38.10;    % circular hole centre x (mm)
geo.cy = 33.02;    % circular hole centre y (mm)
geo.r  = 12.70;    % circular hole radius   (mm)

% --- Material & loading --------------------------------------------------
mat.E       = 70e3;     % Young's modulus (MPa)
mat.nu      = 0.33;     % Poisson's ratio
mat.t       = 5;        % thickness (mm)
mat.sigma_x = 10;       % applied far-field stress (MPa)

% --- File paths ----------------------------------------------------------
files.geoTemplate = 'Elliptical_Hole_with_circular_hole_T6.geo';   % source .geo
files.gmshExe     = 'C:\Users\hemak\Downloads\gmsh-4.15.2-Windows64\gmsh-4.15.2-Windows64\gmsh.exe';  % or full path e.g. 'C:\gmsh\gmsh.exe'
files.resultsDir  = 'Results';                                     % top-level output

% --- Pipeline options ----------------------------------------------------
opts.useParfor    = false;   % set true if you have Parallel Computing Toolbox
opts.savePlots    = true;    % save per-case plots (PNG + PDF)
opts.closeFigures = true;    % close per-case figures after saving (keeps memory low)
opts.verbose      = true;

% =========================================================================
%   PIPELINE EXECUTION
% =========================================================================

if ~exist(files.resultsDir, 'dir');  mkdir(files.resultsDir);  end

nCases  = numel(meshSizes);
results = repmat(emptyResultStruct(), nCases, 1);   % preallocate

t0 = tic;

if opts.useParfor
    % --- Parallel run ----------------------------------------------------
    % Each worker writes to its OWN folder (Results/lc_XX/), so no file conflicts.
    % We copy the .geo template to a per-case folder before mutating it.
    parfor i = 1:nCases
        results(i) = runOneCase(meshSizes(i), geo, mat, files, opts);
    end
else
    % --- Serial run ------------------------------------------------------
    for i = 1:nCases
        results(i) = runOneCase(meshSizes(i), geo, mat, files, opts);
    end
end

fprintf('\n=== All %d cases completed in %.1f s ===\n', nCases, toc(t0));

% =========================================================================
%   AGGREGATION + EXPORT
% =========================================================================

% Sort by lc (descending = coarse to fine), so plots read left-to-right naturally
[~, order] = sort([results.lc], 'descend');
results    = results(order);

saveResults(results, files.resultsDir);          % writes Excel/CSV/TXT
plotConvergence(results, geo, mat, files.resultsDir);   % final plots

fprintf('\nAll outputs saved under: %s\n', files.resultsDir);


% =========================================================================
%   LOCAL FUNCTION:  runOneCase
%   One full pipeline iteration for a single mesh size.
%   Kept local so parfor sees a single self-contained unit of work.
% =========================================================================
function R = runOneCase(lc, geo, mat, files, opts)

    R = emptyResultStruct();
    R.lc = lc;

    caseTag    = sprintf('lc_%g', lc);
    caseDir    = fullfile(files.resultsDir, caseTag);
    if ~exist(caseDir, 'dir');  mkdir(caseDir);  end

    geoFile = fullfile(caseDir, 'mesh.geo');
    mshFile = fullfile(caseDir, 'mesh.msh');

    try
        % -- 1. modify .geo with this lc ---------------------------------
        modifyGeoMeshSize(files.geoTemplate, geoFile, lc);

        % -- 2. run Gmsh -------------------------------------------------
        runGmsh(files.gmshExe, geoFile, mshFile);

        % -- 3. parse mesh -----------------------------------------------
        [coordinates, elements] = meshParserT6(mshFile);

        R.nodes    = size(coordinates,1);
        R.elements = size(elements,1);

        % -- 4. solve FEM (REUSING your existing solver — untouched) -----
        [U, ~, ~, ~, ~] = solveFEM_T6_QuarterPlate( ...
            coordinates, elements, mat.E, mat.nu, mat.t, mat.sigma_x);

        % -- 5. stress field --------------------------------------------
        [~, stressNode] = computeStressT6(coordinates, elements, U, mat.E, mat.nu);

        % -- 6. hoop stresses on both boundaries ------------------------
        [~, ~, theta_e, sigma_e] = computeHoopStressEllipseT6( ...
            coordinates, elements, stressNode, geo.a, geo.b);

        [~, ~, theta_c, sigma_c] = computeHoopStressCircleT6( ...
            coordinates, stressNode, geo.cx, geo.cy, geo.r);

        % -- 7. boundary element counts ---------------------------------
        R.elemsOnEllipse = countElementsOnBoundary( ...
            coordinates, elements, 'ellipse', geo);
        R.elemsOnCircle  = countElementsOnBoundary( ...
            coordinates, elements, 'circle',  geo);

        % -- 8. metrics (max σθθ, location, SCF, error) -----------------
        M = computeMetrics(theta_e, sigma_e, theta_c, sigma_c, geo, mat);

        R.sigmaMaxEllipse  = M.sigmaMaxEllipse;
        R.thetaMaxEllipse  = M.thetaMaxEllipse;
        R.sigmaMaxCircle   = M.sigmaMaxCircle;
        R.thetaMaxCircle   = M.thetaMaxCircle;
        R.Kt_ellipse       = M.Kt_ellipse;
        R.Kt_circle        = M.Kt_circle;
        R.Kt_analytical    = M.Kt_analytical;
        R.absError         = M.absError;
        R.relError         = M.relError;

        % -- 9. boundary stress profiles (for plotting) -----------------
        R.theta_e = theta_e;  R.sigma_e = sigma_e;
        R.theta_c = theta_c;  R.sigma_c = sigma_c;

        % -- 10. per-case plots + summary -------------------------------
        if opts.savePlots
            saveCasePlots(caseDir, caseTag, coordinates, elements, U, ...
                          stressNode, theta_e, sigma_e, theta_c, sigma_c, opts);
        end
        writeCaseSummary(fullfile(caseDir, 'summary.txt'), R);

        R.success = true;

        if opts.verbose
            fprintf('[%s]  nodes=%6d  elems=%6d  Kt_ell=%.3f  Kt_cir=%.3f  err=%.2f%%\n', ...
                caseTag, R.nodes, R.elements, R.Kt_ellipse, R.Kt_circle, R.relError);
        end

    catch ME
        R.success = false;
        R.errMsg  = ME.message;
        warning('Case %s FAILED: %s', caseTag, ME.message);
    end
end

% =========================================================================
%   LOCAL HELPERS
% =========================================================================

function R = emptyResultStruct()
    R = struct( ...
        'lc',              NaN, ...
        'nodes',           NaN, ...
        'elements',        NaN, ...
        'elemsOnEllipse',  NaN, ...
        'elemsOnCircle',   NaN, ...
        'sigmaMaxEllipse', NaN, ...
        'thetaMaxEllipse', NaN, ...
        'sigmaMaxCircle',  NaN, ...
        'thetaMaxCircle',  NaN, ...
        'Kt_ellipse',      NaN, ...
        'Kt_circle',       NaN, ...
        'Kt_analytical',   NaN, ...
        'absError',        NaN, ...
        'relError',        NaN, ...
        'theta_e',         [],  ...
        'sigma_e',         [],  ...
        'theta_c',         [],  ...
        'sigma_c',         [],  ...
        'success',         false, ...
        'errMsg',          '');
end

function saveCasePlots(caseDir, caseTag, coordinates, elements, U, ...
                       stressNode, theta_e, sigma_e, theta_c, sigma_c, opts)
% Lightweight per-case plot saver.  We do NOT call your postProcess_T6
% because that function pops 8 figures — too noisy for a sweep. Instead we
% generate compact summary plots and save as PNG + PDF.

    % ---- Mesh ----------------------------------------------------------
    f = figure('Visible','off');
    patch('Faces', elements(:,1:3), 'Vertices', coordinates, ...
          'FaceColor','none','EdgeColor','k');
    axis equal; xlabel('X'); ylabel('Y'); title(['Mesh — ' caseTag]);
    saveFig(f, fullfile(caseDir, 'mesh'));

    % ---- σxx contour ---------------------------------------------------
    f = figure('Visible','off');
    patch('Faces', elements(:,1:3), 'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,1), ...
          'FaceColor','interp','EdgeColor','none');
    colorbar; axis equal tight;
    xlabel('X'); ylabel('Y'); title(['\sigma_{xx} (MPa) — ' caseTag]);
    saveFig(f, fullfile(caseDir, 'sigma_xx'));

    % ---- Hoop stress: ellipse -----------------------------------------
    f = figure('Visible','off');
    plot(theta_e, sigma_e, 'LineWidth', 2);
    xlabel('\theta (rad)'); ylabel('\sigma_{\theta\theta} (MPa)');
    title(['Hoop stress on ellipse — ' caseTag]); grid on;
    saveFig(f, fullfile(caseDir, 'hoop_ellipse'));

    % ---- Hoop stress: circle ------------------------------------------
    f = figure('Visible','off');
    plot(theta_c, sigma_c, 'LineWidth', 2);
    xlabel('\theta (rad)'); ylabel('\sigma_{\theta\theta} (MPa)');
    title(['Hoop stress on circular hole — ' caseTag]); grid on;
    saveFig(f, fullfile(caseDir, 'hoop_circle'));

    if opts.closeFigures
        close all;
    end
end

function saveFig(f, basename)
    try
        exportgraphics(f, [basename '.png'], 'Resolution', 200);
        exportgraphics(f, [basename '.pdf']);
    catch
        % Fallback for older MATLAB
        print(f, [basename '.png'], '-dpng', '-r200');
        print(f, [basename '.pdf'], '-dpdf');
    end
    close(f);
end

function writeCaseSummary(fname, R)
    fid = fopen(fname, 'w');
    fprintf(fid, '=== Case summary ===\n');
    fprintf(fid, 'lc                 : %g\n',   R.lc);
    fprintf(fid, 'nodes              : %d\n',   R.nodes);
    fprintf(fid, 'elements (T6)      : %d\n',   R.elements);
    fprintf(fid, 'elems on ellipse   : %d\n',   R.elemsOnEllipse);
    fprintf(fid, 'elems on circle    : %d\n',   R.elemsOnCircle);
    fprintf(fid, 'sigma_max_ellipse  : %.6f MPa  at  theta = %.4f rad\n', ...
            R.sigmaMaxEllipse, R.thetaMaxEllipse);
    fprintf(fid, 'sigma_max_circle   : %.6f MPa  at  theta = %.4f rad\n', ...
            R.sigmaMaxCircle, R.thetaMaxCircle);
    fprintf(fid, 'Kt_ellipse  (FEM)  : %.6f\n', R.Kt_ellipse);
    fprintf(fid, 'Kt_circle   (FEM)  : %.6f\n', R.Kt_circle);
    fprintf(fid, 'Kt_ellipse  (Inglis): %.6f\n', R.Kt_analytical);
    fprintf(fid, 'absolute error     : %.6f\n', R.absError);
    fprintf(fid, 'relative error (%%): %.4f\n', R.relError);
    fclose(fid);
end
