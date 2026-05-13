clc;
close all;
clear;

[coordinates, elements] = meshParserQ4("Elliptical_Hole_quad");   % Mesh Parsing Function

plotMesh(coordinates, elements);            % Mesh Plotting Function

E = 70e3; %MPa
nu = 0.33;
t = 5;  %mm
sigma_x = 10; % Applied stress in MPa
%K_global = assembleGlobalStiffnessQ4(coordinates, elements, E, nu, t);          % Global Stiffness Matrx Function

[U, F, K_global, fixedDOF, freeDOF] = solveFEM_Q4_QuarterPlate(coordinates, elements, E, nu, t, sigma_x);   % Displacement Function

[stress, stressNode] = computeStressQ4(coordinates, elements, U, E, nu);              % Stress Computing Function

[theta, sigma_theta, theta_sorted, sigma_theta_sorted] = computeHoopStressEllipseQ4(coordinates, elements, stress);

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
plot(theta_sorted, sigma_theta_sorted,'LineWidth',2);
xlabel('\theta (rad)');
ylabel('\sigma_{\theta\theta} (MPa)');
title('Hoop Stress along Elliptical Hole');
grid on;

% Raw scatter
figure;
scatter(theta, sigma_theta, 15, 'filled');
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
