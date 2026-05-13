% =========================================================================


function [theta, sigma_theta, theta_sorted, sigma_theta_sorted] = ...
    computeHoopStressEllipseT6(coordinates, elements, stressNode, a, b)

% =========================================================================
%  computeHoopStressEllipseT6
%  Computes hoop stress along elliptical boundary using nodal stresses
%
% INPUTS:
%   coordinates : [nNodes x 2]
%   stressNode  : [nNodes x 3]  -> [σxx, σyy, τxy]
%   a, b        : ellipse semi-axes
%
% OUTPUTS:
%   theta, sigma_theta (unsorted)
%   theta_sorted, sigma_theta_sorted
% =========================================================================



% Robust hoop stress for T6 using boundary edges

    tol = 1e-3;

    % --- 1. Find boundary edges (edges appearing once) ---
    edges = [elements(:,[1 2]);
             elements(:,[2 3]);
             elements(:,[3 1])];

    edges = sort(edges,2);
    [uEdges,~,ic] = unique(edges,'rows');
    counts = accumarray(ic,1);
    bEdges = uEdges(counts==1,:);   % boundary edges

    % --- 2. Select edges on ellipse ---
    nEdges = size(bEdges,1);
    theta = [];
    sigma_theta = [];

    for i = 1:nEdges

        n1 = bEdges(i,1);
        n2 = bEdges(i,2);

        % midpoint (use for detection)
        xm = mean([coordinates(n1,1), coordinates(n2,1)]);
        ym = mean([coordinates(n1,2), coordinates(n2,2)]);

        % check if on ellipse
        if abs((xm/a)^2 + (ym/b)^2 - 1) < 0.02

            % take both nodes
            for node = [n1 n2]

                x = coordinates(node,1);
                y = coordinates(node,2);

                % parametric angle (ellipse)
                th = atan2(y/b, x/a);

                % --- TRUE tangent direction (ellipse) ---
                tx = -a*sin(th);
                ty =  b*cos(th);
                T = [tx ty] / norm([tx ty]);

                % stress tensor
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
    end

    % --- 3. Remove duplicates ---
    [theta, ia] = unique(theta);
    sigma_theta = sigma_theta(ia);

    % --- 4. Sort ---
    [theta_sorted, idx] = sort(theta);
    sigma_theta_sorted = sigma_theta(idx);

    fprintf('Maximum Hoop Stress (sigma_theta) = %.4f MPa\n', ...
        max(sigma_theta_sorted));
end