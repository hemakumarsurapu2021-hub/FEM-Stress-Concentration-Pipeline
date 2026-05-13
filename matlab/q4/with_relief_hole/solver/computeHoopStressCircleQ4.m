function [theta, sigma_theta, theta_s, sigma_s] = ...
    computeHoopStressCircleQ4(coordinates, stressNode, cx, cy, r)
% =========================================================================
%  computeHoopStressCircleQ4  —  Hoop stress σθθ along circular relief hole
% =========================================================================
%
%  Mirrors the logic of computeHoopStressEllipseQ4 exactly.
%  Identifies elements adjacent to the circle by centroid proximity,
%  then projects the Cartesian stress tensor onto the local tangential
%  direction at each centroid.
%
%  INPUTS
%    coordinates  : [nNodes x 2]  nodal coordinates
%    elements     : [nElem  x 4]  Q4 connectivity
%    stress       : [nElem  x 4 x 3]  Gauss-point stresses from computeStressQ4
%    cx, cy       : circle centre coordinates  (mm)
%    r            : circle radius              (mm)
%
%  OUTPUTS
%    theta_circle          : [M x 1]  angular coordinate (rad) — unsorted
%    sigma_theta_circle    : [M x 1]  hoop stress (MPa)        — unsorted
%    theta_circle_sorted   : [M x 1]  sorted by angle
%    sigma_theta_circle_sorted : [M x 1]  corresponding sorted hoop stress
%
%  NOTE: The filter band ±10% of r mirrors the ±5% phi band on the ellipse.
%  For coarser meshes widen to ±15% if no elements are detected.
% =========================================================================

    % --- Filter tolerance (fraction of radius) ---

        tol = 0.01 * r;

    theta = [];
    sigma_theta = [];

    for node = 1:size(coordinates,1)

        x = coordinates(node,1);
        y = coordinates(node,2);

        dist = sqrt((x - cx)^2 + (y - cy)^2);

        if abs(dist - r) < tol

            th = atan2(y - cy, x - cx);

            T = [-sin(th), cos(th)];

            sxx = stressNode(node,1);
            syy = stressNode(node,2);
            txy = stressNode(node,3);

            S = [sxx txy; txy syy];

            sigma_t = T * S * T';

            theta = [theta; th];
            sigma_theta = [sigma_theta; sigma_t];
        end
    end

    [theta, ia] = unique(round(theta,4));
    sigma_theta = sigma_theta(ia);

    [theta_s, idx] = sort(theta);
    sigma_s = sigma_theta(idx);

    fprintf('Max hoop stress (circle) = %.4f MPa\n', max(sigma_s));
end