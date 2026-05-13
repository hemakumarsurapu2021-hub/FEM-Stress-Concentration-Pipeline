function saveCaseResults(caseDir, caseTag, coordinates, elements, U, ...
                          stressNode, deltaSigmaNode, ...
                          theta_e, sigma_e, theta_c, sigma_c, R, opts)
% =========================================================================
%   saveCaseResults
%   Saves the per-case artefacts for one mesh size:
%     • mesh.png/.pdf
%     • sigma_xx contour
%     • Δσ contour                           (Q4 has Δσ — we plot it)
%     • Ux displacement contour
%     • Hoop stress on ellipse
%     • Hoop stress on circle
%     • summary.txt
%
% INPUTS:
%   caseDir         : output folder (Results/lc_XX)
%   caseTag         : 'lc_10' etc. — used in plot titles
%   coordinates, elements, U, stressNode, deltaSigmaNode : FEM outputs
%   theta_e, sigma_e, theta_c, sigma_c                   : hoop stresses
%   R                                                    : metrics struct
%   opts                                                 : pipeline options
%
% USED BY: run_convergence_study.m
% =========================================================================
%
% We deliberately do NOT call your interactive postProcess routines (they
% open many figures). Instead, we generate a compact, screenshot-friendly
% set of plots with figures invisible during a sweep.
% =========================================================================

    if opts.savePlots
        % ---- Mesh ----------------------------------------------------
        f = figure('Visible','off');
        patch('Faces', elements, 'Vertices', coordinates, ...
              'FaceColor','none','EdgeColor','k');
        axis equal; xlabel('X'); ylabel('Y'); title(['Mesh — ' caseTag]);
        saveFig(f, fullfile(caseDir, 'mesh'));

        % ---- σxx contour --------------------------------------------
        f = figure('Visible','off');
        patch('Faces', elements, 'Vertices', coordinates, ...
              'FaceVertexCData', stressNode(:,1), ...
              'FaceColor','interp','EdgeColor','none');
        colorbar; axis equal tight;
        xlabel('X'); ylabel('Y'); title(['\sigma_{xx} (MPa) — ' caseTag]);
        saveFig(f, fullfile(caseDir, 'sigma_xx'));

        % ---- σyy contour --------------------------------------------
        f = figure('Visible','off');
        patch('Faces', elements, 'Vertices', coordinates, ...
              'FaceVertexCData', stressNode(:,2), ...
              'FaceColor','interp','EdgeColor','none');
        colorbar; axis equal tight;
        xlabel('X'); ylabel('Y'); title(['\sigma_{yy} (MPa) — ' caseTag]);
        saveFig(f, fullfile(caseDir, 'sigma_yy'));

        % ---- Δσ contour (principal stress difference) ---------------
        f = figure('Visible','off');
        patch('Faces', elements, 'Vertices', coordinates, ...
              'FaceVertexCData', deltaSigmaNode, ...
              'FaceColor','interp','EdgeColor','none');
        colorbar; axis equal tight;
        xlabel('X'); ylabel('Y');
        title(['\Delta\sigma  =  \sigma_2 - \sigma_1  (MPa) — ' caseTag]);
        saveFig(f, fullfile(caseDir, 'deltaSigma'));

        % ---- Ux displacement ----------------------------------------
        Ux = U(1:2:end);
        f = figure('Visible','off');
        patch('Faces', elements, 'Vertices', coordinates, ...
              'FaceVertexCData', Ux, ...
              'FaceColor','interp','EdgeColor','none');
        colorbar; axis equal tight;
        xlabel('X'); ylabel('Y'); title(['U_x (mm) — ' caseTag]);
        saveFig(f, fullfile(caseDir, 'Ux'));

        % ---- Hoop stress on ellipse ---------------------------------
        f = figure('Visible','off');
        plot(theta_e, sigma_e, 'LineWidth', 2);
        xlabel('\theta (rad)'); ylabel('\sigma_{\theta\theta} (MPa)');
        title(['Hoop stress on ellipse — ' caseTag]); grid on;
        saveFig(f, fullfile(caseDir, 'hoop_ellipse'));

        % ---- Hoop stress on circle ----------------------------------
        f = figure('Visible','off');
        plot(theta_c, sigma_c, 'LineWidth', 2);
        xlabel('\theta (rad)'); ylabel('\sigma_{\theta\theta} (MPa)');
        title(['Hoop stress on circular hole — ' caseTag]); grid on;
        saveFig(f, fullfile(caseDir, 'hoop_circle'));

        if opts.closeFigures
            close all;
        end
    end

    % ---- Per-case text summary --------------------------------------
    fid = fopen(fullfile(caseDir, 'summary.txt'), 'w');
    fprintf(fid, '=== Case summary ===\n');
    fprintf(fid, 'lc                     : %g\n',   R.lc);
    fprintf(fid, 'nodes                  : %d\n',   R.nodes);
    fprintf(fid, 'elements (Q4)          : %d\n',   R.elements);
    fprintf(fid, 'elems on ellipse       : %d\n',   R.elemsOnEllipse);
    fprintf(fid, 'elems on circle        : %d\n',   R.elemsOnCircle);
    fprintf(fid, 'sigma_max_ellipse      : %.6f MPa  at  theta = %.4f rad\n', ...
            R.sigmaMaxEllipse, R.thetaMaxEllipse);
    fprintf(fid, 'sigma_max_circle       : %.6f MPa  at  theta = %.4f rad\n', ...
            R.sigmaMaxCircle, R.thetaMaxCircle);
    fprintf(fid, 'Kt_ellipse  (FEM)      : %.6f\n', R.Kt_ellipse);
    fprintf(fid, 'Kt_circle   (FEM)      : %.6f\n', R.Kt_circle);
    fprintf(fid, 'ratio circle/ellipse   : %.6f\n', R.ratioCircleToEllipse);
    fprintf(fid, 'Delta sigma (max)      : %.6f MPa\n', R.deltaSigmaMax);
    fprintf(fid, 'absolute error vs 46   : %.6f MPa\n', R.absError);
    fprintf(fid, 'relative error (%%)    : %.4f\n', R.relError);
    fclose(fid);
end


function saveFig(f, basename)
    try
        exportgraphics(f, [basename '.png'], 'Resolution', 200);
        exportgraphics(f, [basename '.pdf']);
    catch
        % Fallback for older MATLAB (pre-R2020a)
        print(f, [basename '.png'], '-dpng', '-r200');
        print(f, [basename '.pdf'], '-dpdf');
    end
    close(f);
end
