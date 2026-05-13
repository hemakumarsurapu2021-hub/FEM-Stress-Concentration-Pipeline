% =========================================================================
%              MASTER SCRIPT: FEM MESH CONVERGENCE STUDY
%              Q4 Element - Quarter Plate with Elliptical Hole
% =========================================================================
%
% USAGE:
%   Simply run this script. All inputs are defined in the CONFIG section.
%
%   Prerequisites:
%     - Gmsh must be installed and accessible (set GMSH_PATH below)
%     - All helper functions must be in the same folder or on MATLAB path
%     - Original .geo template file must exist (set GEO_TEMPLATE below)
%
% OUTPUTS (per mesh size, in Results/<caseName>/):
%     - mesh plot, Ux, Uy, sigma_xx, sigma_yy, tau_xy, hoop stress plots
%     - results.mat   (all FEM data for that case)
%
% FINAL OUTPUTS (in Results/):
%     - convergence_results.xlsx
%     - convergence_results.txt
%     - convergence_plot.png / .pdf
%     - error_plot.png / .pdf
%
% =========================================================================

clc; close all; clear;

%% -------------------------------------------------------------------------
%  USER CONFIGURATION  (edit only this section)
% -------------------------------------------------------------------------

% --- Mesh sizes to study (coarse → fine) ---
totalTimer = tic;
cfg.meshSizes = [2, 1.5];   % lc values in mm

% --- Gmsh executable path ---
%     Windows : 'C:/Program Files/Gmsh/gmsh.exe'
%     macOS   : '/Applications/Gmsh.app/Contents/MacOS/gmsh'
%     Linux   : 'gmsh'  (if on system PATH)
cfg.gmshPath = 'C:\Users\hemak\Downloads\gmsh-4.15.2-Windows64\gmsh-4.15.2-Windows64\gmsh.exe';

% --- Template .geo file (your original geometry) ---
cfg.geoTemplate = 'Elliptical_Hole_quad.geo';

% --- Material & loading ---
cfg.E       = 70e3;   % Young's modulus [MPa]
cfg.nu      = 0.33;   % Poisson's ratio
cfg.t       = 5;      % Thickness [mm]
cfg.sigma_x = 10;     % Applied far-field stress [MPa]

% --- Analytical solution for hoop stress at θ=90° (top of ellipse) ---
%     Kirsch solution for elliptical hole:  σ_θθ(90°) = σ_x * (1 + 2b/a)
%     a = 25.4 mm (semi-axis in x), b = 45.72 mm (semi-axis in y)
a_hole = 25.40;
b_hole = 45.72;
cfg.sigma_analytical = cfg.sigma_x * (1 + 2*b_hole/a_hole);   % MPa

% --- Output root folder ---
cfg.resultsRoot = 'Results';

% --- Use parallel computing (requires Parallel Computing Toolbox) ---
cfg.useParallel = false;   % set true to enable parfor

% -------------------------------------------------------------------------
%  END OF USER CONFIGURATION
% -------------------------------------------------------------------------

%% Validate inputs
validateConfig(cfg);

%% Create root results folder
if ~exist(cfg.resultsRoot, 'dir')
    mkdir(cfg.resultsRoot);
end

nCases = length(cfg.meshSizes);

%% Pre-allocate results table
resultsTable = initResultsTable(nCases);

fprintf('\n=====================================================\n');
fprintf('  FEM MESH CONVERGENCE STUDY  —  %d mesh sizes\n', nCases);
fprintf('  Analytical σ_θθ(90°) = %.4f MPa\n', cfg.sigma_analytical);
fprintf('=====================================================\n\n');

%% -------------------------------------------------------------------------
%  MAIN LOOP  (serial or parallel)
% -------------------------------------------------------------------------

if cfg.useParallel
    % --- Parallel branch ---
    % parfor cannot use struct directly in some versions; unpack first
    meshSizes    = cfg.meshSizes;
    gmshPath     = cfg.gmshPath;
    geoTemplate  = cfg.geoTemplate;
    E            = cfg.E;
    nu           = cfg.nu;
    t            = cfg.t;
    sigma_x      = cfg.sigma_x;
    resultsRoot  = cfg.resultsRoot;

    % Temporary cell array to collect results (parfor-safe)
    tempResults = cell(nCases, 1);

    parfor k = 1:nCases
        lc = meshSizes(k);
        caseName = sprintf('lc_%gmm', lc);
        caseDir  = fullfile(resultsRoot, caseName);

        fprintf('[Case %d/%d] lc = %g mm  →  %s\n', k, nCases, lc, caseName);

        try
            res = runSingleCase(lc, caseName, caseDir, ...
                                geoTemplate, gmshPath, ...
                                E, nu, t, sigma_x);
            tempResults{k} = res;
        catch ME
            warning('[Case %d] FAILED: %s', k, ME.message);
            tempResults{k} = [];
        end
    end

    % Collect results
    for k = 1:nCases
        if ~isempty(tempResults{k})
            resultsTable = fillRow(resultsTable, k, tempResults{k}, cfg);
        end
    end

else
    % --- Serial branch ---
    for k = 1:nCases
        lc = cfg.meshSizes(k);
        caseName = sprintf('lc_%gmm', lc);
        caseDir  = fullfile(cfg.resultsRoot, caseName);

        fprintf('[Case %d/%d] lc = %g mm  →  %s\n', k, nCases, lc, caseName);

        try
            res = runSingleCase(lc, caseName, caseDir, ...
                                cfg.geoTemplate, cfg.gmshPath, ...
                                cfg.E, cfg.nu, cfg.t, cfg.sigma_x);
            resultsTable = fillRow(resultsTable, k, res, cfg);
        catch ME
            warning('[Case %d] lc=%g FAILED: %s', k, lc, ME.message);
        end
    end
end

%% -------------------------------------------------------------------------
%  POST-PROCESSING: Convergence plots and export
% -------------------------------------------------------------------------

fprintf('\n--- Generating convergence plots and exporting results ---\n');

% Remove failed rows
validRows = ~isnan(resultsTable.SigmaMax_MPa);
T = resultsTable(validRows, :);

if height(T) < 2
    warning('Fewer than 2 valid cases — skipping convergence plots.');
else
    plotConvergence(T, cfg);
    plotErrorConvergence(T, cfg);
end

exportResults(T, cfg);

fprintf('\n Convergence study complete.  Results saved in: %s\n\n', ...
        fullfile(pwd, cfg.resultsRoot));

fprintf('\n Total runtime: %.2f seconds\n', toc(totalTimer));