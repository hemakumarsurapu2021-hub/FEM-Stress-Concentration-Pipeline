clc;
close all;
clear;

[coordinates, elements] = meshParserQ4("Elliptical_Hole_with_circular_hole.msh");   % Mesh Parsing Function

plotMesh(coordinates, elements);            % Mesh Plotting Function

E = 70e3; %MPa
nu = 0.33;
t = 5;  %mm
sigma_x = 10; % Applied stress in MPa
%K_global = assembleGlobalStiffnessQ4(coordinates, elements, E, nu, t);          % Global Stiffness Matrx Function

[U, F, K_global, fixedDOF, freeDOF] = solveFEM_Q4_QuarterPlate(coordinates, elements, E, nu, t, sigma_x);   % Displacement Function

[stress, stressNode] = computeStressQ4(coordinates, elements, U, E, nu);

% --- ellipse ---
a = 25.4;
b = 45.72;

[theta_e, sigma_e, theta_es, sigma_es] = computeHoopStressEllipseQ4(coordinates, stressNode, a, b);

% --- circle ---
cx = 38.10;
cy = 33.02;
r  = 12.70;

[theta_c, sigma_c, theta_cs, sigma_cs] = ...
    computeHoopStressCircleQ4(coordinates, stressNode, cx, cy, r);

% --- SCF ---
Kt_ellipse = max(sigma_es) / sigma_x;
Kt_circle  = max(sigma_cs) / sigma_x;

fprintf('\n--- STRESS RESULTS ---\n');
fprintf('Ellipse σ_max = %.4f MPa\n', max(sigma_es));
fprintf('Circle  σ_max = %.4f MPa\n', max(sigma_cs));
fprintf('SCF Ellipse   = %.4f\n', Kt_ellipse);
fprintf('SCF Circle    = %.4f\n', Kt_circle);

% -----------------------------------------------------
% VISUALIZATION OF DISPLACEMENTS
% -----------------------------------------------------

% ----------- u DOF -----------
Ux = U(1:2:end);
figure;
patch('Faces', elements, ...
      'Vertices', coordinates, ...
      'FaceVertexCData', Ux, ...
      'FaceColor', 'interp', ...
      'EdgeColor', 'k');

colorbar;
title('Displacement Ux');
axis equal tight;
xlabel('X'); ylabel('Y');

% ----------- v DOF -----------
Uy = U(2:2:end);
figure;
patch('Faces', elements, ...
      'Vertices', coordinates, ...
      'FaceVertexCData', Uy, ...
      'FaceColor', 'interp', ...
      'EdgeColor', 'k');

colorbar;
title('Displacement Uy');
axis equal tight;
xlabel('X'); ylabel('Y');

% -----------------------------------------------------
% VISUALIZATION OF STRESSES
% -----------------------------------------------------

% ----------- sigma_xx -----------
figure;
patch('Faces', elements, ...
      'Vertices', coordinates, ...
      'FaceVertexCData', stressNode(:,1), ...
      'FaceColor', 'interp', ...
      'EdgeColor', 'k');

colorbar;
title('\sigma_{xx}');
axis equal tight;
xlabel('X'); ylabel('Y');


% ----------- sigma_yy -----------
figure;
patch('Faces', elements, ...
      'Vertices', coordinates, ...
      'FaceVertexCData', stressNode(:,2), ...
      'FaceColor', 'interp', ...
      'EdgeColor', 'k');

colorbar;
title('\sigma_{yy}');
axis equal tight;
xlabel('X'); ylabel('Y');

% ----------- tau_xy -----------
figure;
patch('Faces', elements, ...
      'Vertices', coordinates, ...
      'FaceVertexCData', stressNode(:,3), ...
      'FaceColor', 'interp', ...
      'EdgeColor', 'k');

colorbar;
title('\tau_{xy}');
axis equal tight;
xlabel('X'); ylabel('Y');


% -----------------------------------------------------
% VISUALIZATION OF SIGMA THETA PLOT
% -----------------------------------------------------

% Smooth curve
figure;
plot(theta_es, sigma_es, 'LineWidth',2);
xlabel('\theta (rad)');
ylabel('\sigma_{\theta\theta} (MPa)');
title('Hoop Stress along Elliptical Hole');
grid on;

% Raw scatter
figure;
scatter(theta_e, sigma_e, 15, 'filled');
xlabel('\theta (rad)');
ylabel('\sigma_{\theta\theta} (MPa)');
title('Raw Hoop Stress (unsorted)');
grid on;

% ----------- Smooth contour -----------
figure;
patch('Faces', elements, ...
      'Vertices', coordinates, ...
      'FaceVertexCData', stressNode(:,1), ...
      'FaceColor', 'interp', ...
      'EdgeColor', 'none');

colorbar;
title('\sigma_x distribution (Flat FEM contour)');
axis equal tight;
xlabel('X'); ylabel('Y');

figure;
plot(theta_es, sigma_es, 'b', 'LineWidth', 2); hold on;
plot(theta_cs, sigma_cs, 'r', 'LineWidth', 2);
legend('Ellipse','Circle');
xlabel('\theta'); ylabel('\sigma_{\theta\theta}');
title('Hoop Stress Comparison');
grid on;
