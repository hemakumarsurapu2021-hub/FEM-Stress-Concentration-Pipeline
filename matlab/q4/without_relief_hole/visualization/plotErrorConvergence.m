function plotErrorConvergence(T, cfg)
% =========================================================================
%  plotErrorConvergence  —  Relative error vs Number of Elements (log-log)
% =========================================================================

    outDir = cfg.resultsRoot;

    fig = figure('Visible','off','Position',[100 100 900 600]);

    % --- Error on log-log axes ---
    loglog(T.Elements, T.RelError_pct, 'r-s', ...
           'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    hold on;

    % --- Reference slope lines (order 1, 2) ---
    xRef = linspace(min(T.Elements)*0.8, max(T.Elements)*1.2, 50);
    % Fit a line in log space to the data for automatic anchor
    p = polyfit(log10(T.Elements), log10(T.RelError_pct), 1);
    anchor = 10.^polyval(p, log10(mean(T.Elements)));

    plot(xRef, anchor * (xRef/mean(T.Elements)).^(-1), 'k:', ...
         'LineWidth', 1, 'DisplayName', 'O(N^{-1})');
    plot(xRef, anchor * (xRef/mean(T.Elements)).^(-2), 'k--', ...
         'LineWidth', 1, 'DisplayName', 'O(N^{-2})');

    % --- Convergence rate annotation ---
    rate = p(1);
    xlabel('Number of Elements',  'FontSize', 12);
    ylabel('Relative Error  (%)', 'FontSize', 12);
    title(sprintf('Error Convergence  |  slope ≈ %.2f', rate), 'FontSize', 14);
    legend({'FEM Error', 'O(N^{-1})', 'O(N^{-2})'}, ...
           'Location','best','FontSize',11);
    grid on; box on;

    % --- lc labels ---
    for i = 1:height(T)
        text(T.Elements(i), T.RelError_pct(i)*1.15, ...
             sprintf(' lc=%g', T.lc_mm(i)), 'FontSize', 8);
    end

    % --- Save ---
    base = fullfile(outDir, 'error_plot');
    exportgraphics(fig, [base '.png'], 'Resolution', 300);
    exportgraphics(fig, [base '.pdf'], 'ContentType', 'image');
    close(fig);

    fprintf('  Saved: error_plot.png / .pdf\n');
end