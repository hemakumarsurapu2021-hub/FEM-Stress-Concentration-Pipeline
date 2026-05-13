function [theta, sigma_theta, theta_s, sigma_s] = ...
    computeHoopStressEllipseT6(coordinates, elements, stressNode, a, b)
% =========================================================================
%  computeHoopStressEllipseT6
%  Computes hoop stress along elliptical boundary using nodal stresses
%
% INPUTS:
%   coordinates : [nNodes x 2]
%   elements    : [nElem x 6]
%   stressNode  : [nNodes x 3]  -> [sigma_xx, sigma_yy, tau_xy]
%   a, b        : ellipse semi-axes
%
% OUTPUTS:
%   theta         : parametric angles (unsorted)
%   sigma_theta   : hoop stress values (unsorted)
%   theta_s       : parametric angles (sorted)
%   sigma_s       : hoop stress values (sorted)
% =========================================================================

    tol = 1e-3;

    % --- 1. Find boundary edges (edges appearing once) ---
    theta = [];
    sigma_theta = [];
    
    tol = 5e-4;   % tighter tolerance
    
    for node = 1:size(coordinates,1)
    
        x = coordinates(node,1);
        y = coordinates(node,2);
    
        % Check if node is ON ellipse
        if abs((x/a)^2 + (y/b)^2 - 1) < tol
    
            % Parametric angle
            th = atan2(y/b, x/a);
    
            % Tangent direction (CORRECT)
            tx = -a*sin(th);
            ty =  b*cos(th);
            T = [tx ty] / norm([tx ty]);
    
            % Stress tensor
            sxx = stressNode(node,1);
            syy = stressNode(node,2);
            txy = stressNode(node,3);
    
            S = [sxx txy;
                 txy syy];
    
            sigma_t = T * S * T';
    
            theta = [theta; th];
            sigma_theta = [sigma_theta; sigma_t];
        end
    end

    % --- 3. Remove duplicates ---
    [theta, ia] = unique(round(theta,4));
    sigma_theta = sigma_theta(ia);
    
    [theta_s, idx] = sort(theta);
    sigma_s = sigma_theta(idx);

    fprintf('Maximum Hoop Stress (sigma_theta) = %.4f MPa\n', max(sigma_s));

end
