% =========================================================================
%            T6 FEM PIPELINE — POST PROCESSING SCRIPT
%            Quarter Plate with Elliptical Hole (Plane Stress)
% =========================================================================
% Run this script after all T6 function files are on your MATLAB path.
% Gmsh must be run separately to generate the .msh file from:
%     Elliptical_Hole_T6.geo   (set Mesh.ElementOrder = 2, no recombination)
% =========================================================================

clc;
close all;
clear;

% ── Mesh parsing ─────────────────────────────────────────────────────────
[coordinates, elements] = meshParserT6('Elliptical_Hole_T6.msh');

% ── Mesh visualization ───────────────────────────────────────────────────
figure;
% Use only corner nodes (1,2,3) for patch display (T6 → T3 faces)
patch('Faces',    elements(:, 1:3), ...
      'Vertices', coordinates, ...
      'FaceColor','none', ...
      'EdgeColor','k');
axis equal; xlabel('X'); ylabel('Y'); title('T6 Mesh Visualization');

% ── Material & loading ───────────────────────────────────────────────────
E       = 70e3;   % MPa
nu      = 0.33;
t       = 5;      % mm
sigma_x = 10;     % MPa

% ── FEM solve ────────────────────────────────────────────────────────────
[U, F, K_global, fixedDOF, freeDOF] = ...
    solveFEM_T6_QuarterPlate(coordinates, elements, E, nu, t, sigma_x);

% ── Stress computation ───────────────────────────────────────────────────
[stress, stressNode] = computeStressT6(coordinates, elements, U, E, nu);

% ── Hoop stress ──────────────────────────────────────────────────────────

% Call function
a = 25.4; b = 45.72;
[theta, sigma_theta, theta_sorted, sigma_theta_sorted] = ...
    computeHoopStressEllipseT6(coordinates, elements, stressNode, a, b);


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
plot(theta_sorted, sigma_theta_sorted, 'LineWidth', 2);
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
