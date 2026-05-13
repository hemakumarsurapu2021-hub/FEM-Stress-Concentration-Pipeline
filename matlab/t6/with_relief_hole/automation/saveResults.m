function saveResults(results, resultsDir)
% =========================================================================
%   saveResults
%   Aggregate all per-case results into Excel (.xlsx), CSV (.csv), and
%   plain text (.txt) at the top of resultsDir.
%
% INPUTS:
%   results    : struct array (one entry per mesh case)
%   resultsDir : top-level output folder (e.g. 'Results')
%
% USED BY:  run_convergence_study_T6.m
% =========================================================================
%
% Columns (matches the spec):
%   lc, nodes, elements, elems_on_ellipse, elems_on_circle,
%   sigma_max_ellipse, sigma_max_circle,
%   Kt_ellipse, Kt_circle, Kt_analytical, abs_error, rel_error_pct
% =========================================================================

    n = numel(results);

    lc                = arrayfun(@(r) r.lc,              results);
    nodes             = arrayfun(@(r) r.nodes,           results);
    elem              = arrayfun(@(r) r.elements,        results);
    elemEll           = arrayfun(@(r) r.elemsOnEllipse,  results);
    elemCir           = arrayfun(@(r) r.elemsOnCircle,   results);
    sigmaMaxEll       = arrayfun(@(r) r.sigmaMaxEllipse, results);
    sigmaMaxCir       = arrayfun(@(r) r.sigmaMaxCircle,  results);
    Kt_ell            = arrayfun(@(r) r.Kt_ellipse,      results);
    Kt_cir            = arrayfun(@(r) r.Kt_circle,       results);
    Kt_an             = arrayfun(@(r) r.Kt_analytical,   results);
    absErr            = arrayfun(@(r) r.absError,        results);
    relErr            = arrayfun(@(r) r.relError,        results);

    T = table( lc(:), nodes(:), elem(:), elemEll(:), elemCir(:), ...
               sigmaMaxEll(:), sigmaMaxCir(:), ...
               Kt_ell(:), Kt_cir(:), Kt_an(:), absErr(:), relErr(:), ...
        'VariableNames', { ...
            'lc', 'nodes', 'elements', 'elems_on_ellipse', 'elems_on_circle', ...
            'sigma_max_ellipse', 'sigma_max_circle', ...
            'Kt_ellipse', 'Kt_circle', 'Kt_analytical', 'abs_error', 'rel_error_pct'});

    % --- Excel ---------------------------------------------------------
    xlsxPath = fullfile(resultsDir, 'convergence_results.xlsx');
    try
        if isfile(xlsxPath); delete(xlsxPath); end
        writetable(T, xlsxPath, 'Sheet', 'summary');
    catch ME
        warning('Excel write failed (%s). CSV/TXT will still be written.', ME.message);
    end

    % --- CSV -----------------------------------------------------------
    csvPath = fullfile(resultsDir, 'convergence_results.csv');
    writetable(T, csvPath);

    % --- TXT (human-friendly) -----------------------------------------
    txtPath = fullfile(resultsDir, 'convergence_results.txt');
    fid = fopen(txtPath, 'w');
    fprintf(fid, 'T6 FEM convergence study — summary\n');
    fprintf(fid, '%s\n\n', repmat('=', 1, 70));
    fprintf(fid, '%6s %8s %8s %10s %10s %14s %14s %10s %10s %12s %10s %10s\n', ...
        'lc','nodes','elems','el_ellipse','el_circle', ...
        'smax_ell','smax_cir','Kt_ell','Kt_cir','Kt_analyt','absErr','relErr%');
    for i = 1:n
        fprintf(fid, '%6.3g %8d %8d %10d %10d %14.5f %14.5f %10.4f %10.4f %12.4f %10.4f %10.3f\n', ...
            lc(i), nodes(i), elem(i), elemEll(i), elemCir(i), ...
            sigmaMaxEll(i), sigmaMaxCir(i), ...
            Kt_ell(i), Kt_cir(i), Kt_an(i), absErr(i), relErr(i));
    end
    fclose(fid);

    fprintf('Saved: %s\n', xlsxPath);
    fprintf('Saved: %s\n', csvPath);
    fprintf('Saved: %s\n', txtPath);
end
