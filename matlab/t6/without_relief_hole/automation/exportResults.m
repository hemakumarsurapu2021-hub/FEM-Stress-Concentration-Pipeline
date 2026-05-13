function exportResults(T, cfg)
% =========================================================================
%  exportResults  —  Save convergence table to Excel and plain text
% =========================================================================

    outDir = cfg.resultsRoot;

    %% --- Excel ---
    xlsxFile = fullfile(outDir, 'convergence_results.xlsx');

    % Sheet 1: main results
    writetable(T, xlsxFile, 'Sheet', 'Results', 'WriteRowNames', false);

    % Sheet 2: run configuration
    cfgTable = table( ...
        {'Analytical sigma_theta (MPa)'; 'Applied stress sigma_x (MPa)'; ...
         'Young''s modulus E (MPa)'; 'Poisson''s ratio nu'; ...
         'Thickness t (mm)'; 'Gmsh template'; 'Gmsh path'}, ...
        {num2str(cfg.sigma_analytical); num2str(cfg.sigma_x); ...
         num2str(cfg.E); num2str(cfg.nu); num2str(cfg.t); ...
         cfg.geoTemplate; cfg.gmshPath}, ...
        'VariableNames', {'Parameter', 'Value'});
    writetable(cfgTable, xlsxFile, 'Sheet', 'Config');

    fprintf('  Saved: convergence_results.xlsx\n');

    %% --- Plain text ---
    txtFile = fullfile(outDir, 'convergence_results.txt');
    fid = fopen(txtFile, 'w');
    if fid == -1
        warning('Could not write text file: %s', txtFile);
        return;
    end

    % Header
    fprintf(fid, '=======================================================================\n');
    fprintf(fid, '  FEM MESH CONVERGENCE STUDY — Q4 Quad  |  Quarter Plate + Ellipse Hole\n');
    fprintf(fid, '  Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '=======================================================================\n\n');

    fprintf(fid, '  E = %g MPa  |  nu = %g  |  t = %g mm  |  sigma_x = %g MPa\n', ...
            cfg.E, cfg.nu, cfg.t, cfg.sigma_x);
    fprintf(fid, '  Analytical sigma_theta(90deg) = %.4f MPa  [Kirsch: 1 + 2b/a]\n\n', ...
            cfg.sigma_analytical);

    % Table header
    hdr = '%-8s  %8s  %9s  %12s  %14s  %14s  %12s  %11s\n';
    row = '%-8s  %8.0f  %9.0f  %12.0f  %14.4f  %14.4f  %12.4f  %11.4f\n';

    fprintf(fid, hdr, ...
            'lc(mm)', 'Nodes', 'Elements', 'ElemsHole', ...
            'SigMax(MPa)', 'SigAnal(MPa)', 'AbsErr(MPa)', 'RelErr(%)');
    fprintf(fid, '%s\n', repmat('-', 1, 95));

    for i = 1:height(T)
        fprintf(fid, row, ...
                num2str(T.lc_mm(i)), ...
                T.Nodes(i), T.Elements(i), T.ElemsOnHole(i), ...
                T.SigmaMax_MPa(i), T.SigmaAnalytical_MPa(i), ...
                T.AbsError_MPa(i), T.RelError_pct(i));
    end

    fprintf(fid, '\n');
    fclose(fid);

    fprintf('  Saved: convergence_results.txt\n');
end
