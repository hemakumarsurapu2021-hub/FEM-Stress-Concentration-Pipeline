function postProcess_T6(coordinates, elements, U, stressNode, theta_s, sigma_s, theta, sigma_theta)
% =========================================================================
%  postProcess_T6
%  Post-processing and visualization for T6 FEM results
%  Quarter Plate with Elliptical Hole (Plane Stress)
%
% INPUT:
%   coordinates  : [nNodes x 2] nodal coordinates
%   elements     : [nElem  x 6] T6 connectivity matrix
%   U            : displacement vector [nDof x 1]
%   stressNode   : [nNodes x 3] averaged nodal stresses [sigma_xx, sigma_yy, tau_xy]
%   theta_s      : sorted parametric angles along ellipse
%   sigma_s      : sorted hoop stress values (MPa)
%   theta        : unsorted angles
%   sigma_theta  : unsorted hoop stress values
% =========================================================================

    % =========================================================================
    %  VISUALIZATION OF DISPLACEMENTS
    % =========================================================================

    Ux = U(1:2:end);
    figure;
    patch('Faces', elements(:,1:3), ...
          'Vertices', coordinates, ...
          'FaceVertexCData', Ux, ...
          'FaceColor','interp', ...
          'EdgeColor','none');
    colorbar; title('Displacement Ux  (mm)'); axis equal tight;
    xlabel('X'); ylabel('Y');

    Uy = U(2:2:end);
    figure;
    patch('Faces', elements(:,1:3), ...
          'Vertices', coordinates, ...
          'FaceVertexCData', Uy, ...
          'FaceColor','interp', ...
          'EdgeColor','none');
    colorbar; title('Displacement Uy  (mm)'); axis equal tight;
    xlabel('X'); ylabel('Y');

    % =========================================================================
    %  VISUALIZATION OF STRESSES
    % =========================================================================

    figure;
    patch('Faces', elements(:,1:3), ...
          'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,1), ...
          'FaceColor','interp', ...
          'EdgeColor','none');
    colorbar; title('\sigma_{xx}  (MPa)'); axis equal tight;
    xlabel('X'); ylabel('Y');

    figure;
    patch('Faces', elements(:,1:3), ...
          'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,2), ...
          'FaceColor','interp', ...
          'EdgeColor','none');
    colorbar; title('\sigma_{yy}  (MPa)'); axis equal tight;
    xlabel('X'); ylabel('Y');

    figure;
    patch('Faces', elements(:,1:3), ...
          'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,3), ...
          'FaceColor','interp', ...
          'EdgeColor','none');
    colorbar; title('\tau_{xy}  (MPa)'); axis equal tight;
    xlabel('X'); ylabel('Y');

    % sigma_x contour (smooth, no edges)
    figure;
    patch('Faces', elements(:,1:3), ...
          'Vertices', coordinates, ...
          'FaceVertexCData', stressNode(:,1), ...
          'FaceColor','interp', ...
          'EdgeColor','none');
    colorbar; title('\sigma_x distribution  (T6 FEM contour)'); axis equal tight;
    xlabel('X'); ylabel('Y');

    % =========================================================================
    %  VISUALIZATION OF HOOP STRESS
    % =========================================================================

    figure;
    plot(theta_s, sigma_s, 'LineWidth', 2);
    xlabel('\theta  (rad)');
    ylabel('\sigma_{\theta\theta}  (MPa)');
    title('Hoop Stress along Elliptical Hole  (T6)');
    grid on;

    figure;
    scatter(theta, sigma_theta, 15, 'filled');
    xlabel('\theta  (rad)');
    ylabel('\sigma_{\theta\theta}  (MPa)');
    title('Raw Hoop Stress — unsorted  (T6)');
    grid on;

end
