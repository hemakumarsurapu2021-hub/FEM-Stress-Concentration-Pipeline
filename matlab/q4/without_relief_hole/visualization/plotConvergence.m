function plotConvergence(T, cfg)
% =========================================================================
%  plotConvergence  —  σ_θθ_max vs Number of Elements
% =========================================================================

    outDir = cfg.resultsRoot;

    fig = figure('Visible','off','Position',[100 100 900 600]);

    % --- FEM values ---
    plot(T.Elements, T.SigmaMax_MPa, 'b-o', ...
         'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b', ...
         'DisplayName', 'FEM  \sigma_{\theta\theta}^{max}');
    hold on;

    % --- Analytical reference line ---
    yline(cfg.sigma_analytical, 'r--', 'LineWidth', 1.8, ...
          'DisplayName', sprintf('Analytical  %.3f MPa', cfg.sigma_analytical));

    % --- Annotations on each point ---
    for i = 1:height(T)
        text(T.Elements(i), T.SigmaMax_MPa(i) + 0.05*cfg.sigma_analytical, ...
             sprintf(' lc=%g', T.lc_mm(i)), ...
             'FontSize', 8, 'HorizontalAlignment', 'left');
    end

    xlabel('Number of Elements',  'FontSize', 12);
    ylabel('\sigma_{\theta\theta}^{max}  (MPa)', 'FontSize', 12);
    title('Mesh Convergence  —  Maximum Hoop Stress', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 11);
    grid on; box on;

    % --- Save ---
    base = fullfile(outDir, 'convergence_plot');
    exportgraphics(fig, [base '.png'], 'Resolution', 300);
    exportgraphics(fig, [base '.pdf'], 'ContentType', 'image');
    close(fig);

    fprintf('  Saved: convergence_plot.png / .pdf\n');
end
