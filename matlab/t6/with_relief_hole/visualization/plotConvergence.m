function plotConvergence(results, geo, mat, resultsDir) %#ok<INUSD>
% =========================================================================
%   plotConvergence
%   Produces the final-aggregate plots after all cases have run.
%
% INPUTS:
%   results    : struct array (one per case)
%   geo        : geometry struct (a, b, cx, cy, r)   [unused, kept for API]
%   mat        : material struct (sigma_x, ...)      [unused, kept for API]
%   resultsDir : top-level output folder
%
% PLOTS PRODUCED:
%   1. sigma_theta_max  vs  number of elements   (ellipse + circle, one plot)
%   2. relative error   vs  number of elements   (semilog y)
%   3. SCF              vs  mesh size lc         (ellipse + circle + Inglis line)
%   4. SCF comparison   ellipse vs circle        (bar chart per lc)
%   5. theta vs sigma_thetatheta — overlaid, all meshes — for ellipse
%   6. theta vs sigma_thetatheta — overlaid, all meshes — for circle
%
% USED BY:  run_convergence_study_T6.m
% =========================================================================

    % Filter only successful cases
    ok = [results.success];
    R  = results(ok);

    if isempty(R)
        warning('plotConvergence: no successful cases — nothing to plot.');
        return;
    end

    lc          = [R.lc];
    nelems      = [R.elements];
    sMaxEll     = [R.sigmaMaxEllipse];
    sMaxCir     = [R.sigmaMaxCircle];
    Kt_ell      = [R.Kt_ellipse];
    Kt_cir      = [R.Kt_circle];
    Kt_an       = R(1).Kt_analytical;       % same for all cases
    relErr      = [R.relError];

    % --- 1. sigma_max vs nElements -------------------------------------
    f = figure('Visible','off');
    semilogx(nelems, sMaxEll, '-o', 'LineWidth', 1.8, 'DisplayName', 'Ellipse'); hold on;
    semilogx(nelems, sMaxCir, '-s', 'LineWidth', 1.8, 'DisplayName', 'Circular hole');
    xlabel('Number of T6 elements');
    ylabel('Max  \sigma_{\theta\theta}  (MPa)');
    title('Convergence of maximum hoop stress');
    legend('Location','best'); grid on;
    saveFig(f, fullfile(resultsDir, 'convergence_sigmaMax_vs_nElements'));

    % --- 2. error vs nElements (log-log) -------------------------------
    f = figure('Visible','off');
    loglog(nelems, max(relErr, eps), '-o', 'LineWidth', 1.8);
    xlabel('Number of T6 elements');
    ylabel('Relative error  (%)  vs Inglis');
    title('Convergence of SCF (ellipse) — relative error');
    grid on;
    saveFig(f, fullfile(resultsDir, 'convergence_error_vs_nElements'));

    % --- 3. SCF vs lc --------------------------------------------------
    f = figure('Visible','off');
    plot(lc, Kt_ell, '-o', 'LineWidth', 1.8, 'DisplayName', 'K_t (ellipse, FEM)'); hold on;
    plot(lc, Kt_cir, '-s', 'LineWidth', 1.8, 'DisplayName', 'K_t (circular hole, FEM)');
    yline(Kt_an, '--k', sprintf('Inglis: 1 + 2b/a = %.3f', Kt_an), ...
          'LabelHorizontalAlignment','left', 'DisplayName', 'Inglis (ellipse)');
    set(gca, 'XDir', 'reverse');   % coarse mesh on the LEFT, fine on the RIGHT
    xlabel('Mesh size lc  (mm)');
    ylabel('Stress concentration factor  K_t');
    title('SCF vs mesh size');
    legend('Location','best'); grid on;
    saveFig(f, fullfile(resultsDir, 'SCF_vs_lc'));

    % --- 4. SCF comparison bar chart -----------------------------------
    f = figure('Visible','off');
    bar(categorical(string(lc)), [Kt_ell(:) Kt_cir(:)]);
    legend('Ellipse','Circular hole','Location','best');
    xlabel('Mesh size lc  (mm)');
    ylabel('K_t');
    title('SCF: ellipse vs circular hole');
    grid on;
    saveFig(f, fullfile(resultsDir, 'SCF_comparison_bar'));

    % --- 5. theta vs sigma — ellipse, overlaid -------------------------
    f = figure('Visible','off');
    cmap = lines(numel(R));
    legends = strings(1, numel(R));
    for i = 1:numel(R)
        plot(R(i).theta_e, R(i).sigma_e, ...
             'Color', cmap(i,:), 'LineWidth', 1.5); hold on;
        legends(i) = sprintf('lc = %g', R(i).lc);
    end
    xlabel('\theta  (rad)');
    ylabel('\sigma_{\theta\theta}  (MPa)');
    title('Hoop stress along ellipse — all meshes');
    legend(legends, 'Location','bestoutside'); grid on;
    saveFig(f, fullfile(resultsDir, 'hoop_ellipse_overlay'));

    % --- 6. theta vs sigma — circle, overlaid --------------------------
    f = figure('Visible','off');
    for i = 1:numel(R)
        plot(R(i).theta_c, R(i).sigma_c, ...
             'Color', cmap(i,:), 'LineWidth', 1.5); hold on;
    end
    xlabel('\theta  (rad)');
    ylabel('\sigma_{\theta\theta}  (MPa)');
    title('Hoop stress along circular hole — all meshes');
    legend(legends, 'Location','bestoutside'); grid on;
    saveFig(f, fullfile(resultsDir, 'hoop_circle_overlay'));
end


function saveFig(f, basename)
    try
        exportgraphics(f, [basename '.png'], 'Resolution', 200);
        exportgraphics(f, [basename '.pdf']);
    catch
        print(f, [basename '.png'], '-dpng', '-r200');
        print(f, [basename '.pdf'], '-dpdf');
    end
    close(f);
end
