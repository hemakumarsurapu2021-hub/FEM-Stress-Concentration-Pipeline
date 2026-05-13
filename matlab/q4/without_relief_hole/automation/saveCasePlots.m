function saveCasePlots(coordinates, elements, U, stressNode, ...
                        theta_sorted, sigma_theta_sorted, caseDir, caseName)
% =========================================================================
%  saveCasePlots  —  Generate and save all FEM result plots for one case
% =========================================================================
%  Saves PNG + PDF for each figure into caseDir.
%  Uses 'visible','off' so no windows pop up during batch runs.
% =========================================================================

    plotDir = fullfile(caseDir, 'plots');
    ensureDir(plotDir);

    Ux = U(1:2:end);
    Uy = U(2:2:end);

    %% --- Helper: save figure ---
    function saveFig(fig, name)
        base = fullfile(plotDir, [caseName '_' name]);
        exportgraphics(fig, [base '.png'], 'Resolution', 300);
        exportgraphics(fig, [base '.pdf'], 'ContentType', 'image');
        close(fig);
    end

    %% 1. Mesh
    fig = figure('Visible','off','Position',[100 100 700 600]);
    patch('Faces', elements, 'Vertices', coordinates, ...
          'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 0.4);
    axis equal tight; xlabel('X (mm)'); ylabel('Y (mm)');
    title(sprintf('Mesh  |  lc = %g mm  |  %d elems', ...
          diff(minmax_lc(coordinates)), size(elements,1)));
    saveFig(fig, 'mesh');

    %% 2. Displacement Ux
    fig = figure('Visible','off','Position',[100 100 700 600]);
    patch('Faces', elements, 'Vertices', coordinates, ...
          'FaceVertexCData', Ux, 'FaceColor','interp','EdgeColor','none');
    colorbar; axis equal tight;
    title('Displacement  U_x  (mm)'); xlabel('X (mm)'); ylabel('Y (mm)');
    saveFig(fig, 'Ux');

    %% 3. Displacement Uy
    fig = figure('Visible','off','Position',[100 100 700 600]);
    patch('Faces', elements, 'Vertices', coordinates, ...
          'FaceVertexCData', Uy, 'FaceColor','interp','EdgeColor','none');
    colorbar; axis equal tight;
    title('Displacement  U_y  (mm)'); xlabel('X (mm)'); ylabel('Y (mm)');
    saveFig(fig, 'Uy');

    %% 4. sigma_xx
    fig = figure('Visible','off','Position',[100 100 700 600]);
    patch('Faces', elements, 'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,1), 'FaceColor','interp','EdgeColor','none');
    colorbar; axis equal tight;
    title('\sigma_{xx}  (MPa)'); xlabel('X (mm)'); ylabel('Y (mm)');
    saveFig(fig, 'sigma_xx');

    %% 5. sigma_yy
    fig = figure('Visible','off','Position',[100 100 700 600]);
    patch('Faces', elements, 'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,2), 'FaceColor','interp','EdgeColor','none');
    colorbar; axis equal tight;
    title('\sigma_{yy}  (MPa)'); xlabel('X (mm)'); ylabel('Y (mm)');
    saveFig(fig, 'sigma_yy');

    %% 6. tau_xy
    fig = figure('Visible','off','Position',[100 100 700 600]);
    patch('Faces', elements, 'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,3), 'FaceColor','interp','EdgeColor','none');
    colorbar; axis equal tight;
    title('\tau_{xy}  (MPa)'); xlabel('X (mm)'); ylabel('Y (mm)');
    saveFig(fig, 'tau_xy');

    %% 7. Hoop stress along ellipse
    fig = figure('Visible','off','Position',[100 100 800 500]);
    plot(rad2deg(theta_sorted), sigma_theta_sorted, 'b-o', ...
         'LineWidth', 1.8, 'MarkerSize', 4);
    xlabel('\theta (deg)'); ylabel('\sigma_{\theta\theta}  (MPa)');
    title(sprintf('Hoop Stress along Ellipse  |  lc = %g mm', ...
          diff(minmax_lc(coordinates))));
    grid on;
    saveFig(fig, 'hoop_stress');
end

% ── Local helper: extract lc from coordinates range (just for title) ──
function r = minmax_lc(coordinates)
    r = [min(coordinates(:,1)), max(coordinates(:,1))];
end
