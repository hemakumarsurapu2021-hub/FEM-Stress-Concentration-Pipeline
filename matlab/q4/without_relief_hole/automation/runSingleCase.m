function res = runSingleCase(lc, caseName, caseDir, ...
                              geoTemplate, gmshPath, ...
                              E, nu, t, sigma_x)
% =========================================================================
%  runSingleCase  —  Run complete FEM pipeline for ONE mesh size
% =========================================================================
%
%  Steps:
%    1. Create isolated case folder
%    2. Edit .geo file to set lc
%    3. Call Gmsh to generate .msh
%    4. Parse mesh
%    5. Run FEM solver
%    6. Compute stresses & hoop stress
%    7. Save plots + .mat results
%
%  Returns res struct with all scalar results for convergence table.
% =========================================================================

    %% 1 ── Create case folder
    caseTimer = tic;
    ensureDir(caseDir);
    fprintf('  [1/7] Folder: %s\n', caseDir);

    %% 2 ── Modify .geo file
    geoOut = fullfile(caseDir, [caseName '.geo']);
    modifyGeoMeshSize(geoTemplate, geoOut, lc);
    fprintf('  [2/7] .geo written (lc = %g)\n', lc);

    %% 3 ── Run Gmsh
    mshFile = fullfile(caseDir, [caseName '.msh']);
    runGmsh(gmshPath, geoOut, mshFile);
    fprintf('  [3/7] Gmsh mesh generated\n');

    %% 4 ── Parse mesh
    [coordinates, elements] = meshParserQ4(mshFile);
    nNodes    = size(coordinates, 1);
    nElements = size(elements, 1);
    fprintf('  [4/7] Mesh parsed: %d nodes, %d elements\n', nNodes, nElements);

    %% 5 ── FEM solver
    [U, ~, ~, ~, ~] = solveFEM_Q4_QuarterPlate(coordinates, elements, E, nu, t, sigma_x);
    fprintf('  [5/7] FEM solved\n');

    %% 6 ── Stresses
    [stress, stressNode] = computeStressQ4(coordinates, elements, U, E, nu);

    [theta, sigma_theta, theta_sorted, sigma_theta_sorted] = ...
        computeHoopStressEllipseQ4(coordinates, elements, stress);

    sigma_max       = max(sigma_theta_sorted);
    nElemsOnHole    = countElemsOnEllipse(coordinates, elements);
    fprintf('  [6/7] Hoop stress computed: max = %.4f MPa, %d elems on hole\n', ...
            sigma_max, nElemsOnHole);

    %% 7 ── Save plots
    saveCasePlots(coordinates, elements, U, stressNode, ...
                  theta_sorted, sigma_theta_sorted, caseDir, caseName);
    fprintf('  [7/7] Plots saved\n');

    %% 8 ── Save .mat
    matFile = fullfile(caseDir, 'results.mat');
    save(matFile, 'coordinates','elements','U','stress','stressNode', ...
         'theta','sigma_theta','theta_sorted','sigma_theta_sorted', ...
         'lc','nNodes','nElements','nElemsOnHole','sigma_max');

    elapsedTime = toc(caseTimer);

    %% Return scalar summary
    res.lc           = lc;
    res.caseName     = caseName;
    res.nNodes       = nNodes;
    res.nElements    = nElements;
    res.nElemsOnHole = nElemsOnHole;
    res.sigma_max    = sigma_max;
    res.runtime_sec  = elapsedTime;

    fprintf('\nCase runtime: %.2f seconds\n', elapsedTime);
    
end
