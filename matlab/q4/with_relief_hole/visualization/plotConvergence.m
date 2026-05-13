function plotConvergence(results, ref, resultsDir)
% =========================================================================
%   plotConvergence
%   Aggregate plots after all cases have run.
%
% INPUTS:
%   results    : struct array (one per case)
%   ref        : reference values (sigmaMaxEllipse, Kt_ellipse)
%   resultsDir : top-level output folder
%
% PLOTS PRODUCED:
%   1. sigma_theta_max  vs  number of elements   (ellipse + circle + 46 MPa line)
%   2. SCF              vs  mesh density (= 1/lc) — ellipse + circle + Kt ref
%   3. Δσ_max           vs  mesh density
%   4. Relative error   vs  number of elements (semilog y)  [ellipse vs 46 MPa]
%   5. Ratio σ_circle / σ_ellipse vs lc  (relief-hole effectiveness)
%   6. theta vs σθθ — overlay of all meshes (ellipse)
%   7. theta vs σθθ — overlay of all meshes (circle)
%
% USED BY: run_convergence_study.m
% =========================================================================

    ok = [results.success];
    R  = results(ok);

    if isempty(R)
        warning('plotConvergence: no successful cases — nothing to plot.');
        return;
    end

    lc       = [R.lc];
    nelems   = [R.elements];
    sMaxEll  = [R.sigmaMaxEllipse];
    sMaxCir  = [R.sigmaMaxCircle];
    Kt_ell   = [R.Kt_ellipse];
    Kt_cir   = [R.Kt_circle];
    dsMax    = [R.deltaSigmaMax];
    relErr   = [R.relError];
    ratio    = [R.ratioCircleToEllipse];

    density = 1 ./ lc;     % "mesh density" = 1/lc, larger = finer

    % --- 1. sigma_max vs nElements ----------------------------------
    f = figure('Visible','off');
    semilogx(nelems, sMaxEll, '-o', 'LineWidth', 1.8, 'DisplayName','Ellipse'); hold on;
    semilogx(nelems, sMaxCir, '-s', 'LineWidth', 1.8, 'DisplayName','Circular hole');
    yline(ref.sigmaMaxEllipse, '--k', ...
          sprintf('analytical = %g MPa', ref.sigmaMaxEllipse), ...
          'LabelHorizontalAlignment','left', 'DisplayName','Reference (ellipse)');
    xlabel('Number of Q4 elements');
    ylabel('Max  \sigma_{\theta\theta}  (MPa)');
    title('Convergence of maximum hoop stress');
    legend('Location','best'); grid on;
    saveFig(f, fullfile(resultsDir, 'convergence_sigmaMax_vs_nElements'));

    % --- 2. SCF vs mesh density -------------------------------------
    f = figure('Visible','off');
    plot(density, Kt_ell, '-o', 'LineWidth', 1.8, 'DisplayName','K_t (ellipse, FEM)'); hold on;
    plot(density, Kt_cir, '-s', 'LineWidth', 1.8, 'DisplayName','K_t (circle, FEM)');
    yline(ref.Kt_ellipse, '--k', ...
          sprintf('K_t ref = %.2f', ref.Kt_ellipse), ...
          'LabelHorizontalAlignment','left', 'DisplayName','Reference (ellipse)');
    xlabel('Mesh density  1/lc  (1/mm)');
    ylabel('Stress concentration factor  K_t');
    title('SCF vs mesh density');
    legend('Location','best'); grid on;
    saveFig(f, fullfile(resultsDir, 'SCF_vs_meshDensity'));

    % --- 3. Δσ_max vs mesh density ----------------------------------
    f = figure('Visible','off');
    plot(density, dsMax, '-o', 'LineWidth', 1.8);
    xlabel('Mesh density  1/lc  (1/mm)');
    ylabel('\Delta\sigma_{max}  =  (\sigma_2 - \sigma_1)_{max}  (MPa)');
    title('Convergence of maximum principal stress difference');
    grid on;
    saveFig(f, fullfile(resultsDir, 'deltaSigmaMax_vs_meshDensity'));

    % --- 4. relative error vs nElements (log-log) -------------------
    f = figure('Visible','off');
    loglog(nelems, max(relErr, eps), '-o', 'LineWidth', 1.8);
    xlabel('Number of Q4 elements');
    ylabel('Relative error (%) vs analytical (46 MPa)');
    title('Convergence of \sigma_{\theta\theta,max} on ellipse');
    grid on;
    saveFig(f, fullfile(resultsDir, 'error_vs_nElements'));

    % --- 5. ratio σ_circle / σ_ellipse vs lc ------------------------
    f = figure('Visible','off');
    plot(lc, ratio, '-o', 'LineWidth', 1.8);
    set(gca, 'XDir', 'reverse');
    xlabel('Mesh size lc (mm)');
    ylabel('\sigma_{\theta\theta,max}^{circle}  /  \sigma_{\theta\theta,max}^{ellipse}');
    title('Relief-hole effectiveness ratio');
    grid on;
    saveFig(f, fullfile(resultsDir, 'reliefRatio_vs_lc'));

    % --- 6. ellipse θ–σ overlay ------------------------------------
    f = figure('Visible','off');
    cmap   = lines(numel(R));
    legends = strings(1, numel(R));
    for i = 1:numel(R)
        plot(R(i).theta_e, R(i).sigma_e, ...
             'Color', cmap(i,:), 'LineWidth', 1.5); hold on;
        legends(i) = sprintf('lc = %g', R(i).lc);
    end
    xlabel('\theta (rad)');
    ylabel('\sigma_{\theta\theta} (MPa)');
    title('Hoop stress along ellipse — all meshes');
    legend(legends, 'Location','bestoutside'); grid on;
    saveFig(f, fullfile(resultsDir, 'hoop_ellipse_overlay'));

    % --- 7. circle θ–σ overlay -------------------------------------
    f = figure('Visible','off');
    for i = 1:numel(R)
        plot(R(i).theta_c, R(i).sigma_c, ...
             'Color', cmap(i,:), 'LineWidth', 1.5); hold on;
    end
    xlabel('\theta (rad)');
    ylabel('\sigma_{\theta\theta} (MPa)');
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
