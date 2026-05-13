function [theta, sigma_theta, theta_s, sigma_s] = computeHoopStressEllipseQ4(coordinates, stressNode, a, b)% -----------------------------------------------------
% COMPUTE HOOP STRESS (σθθ) ALONG ELLIPTICAL HOLE (Q4)
% -----------------------------------------------------
% Uses:
% - FEM solution (displacements)
% - Stress at element center (Barlow point)
% - Projection onto tangential direction
%
% OUTPUT:
%   theta_sorted         : sorted angular coordinate
%   sigma_theta_sorted   : sorted hoop stress
%   sigma_theta          : unsorted hoop stress
% -----------------------------------------------------

    tol = 0.01 %* max(a,b);

    theta = [];
    sigma_theta = [];

    for node = 1:size(coordinates,1)

        x = coordinates(node,1);
        y = coordinates(node,2);

        val = (x/a)^2 + (y/b)^2;

        if abs(val - 1) < tol

            th = atan2(y/b, x/a);

            % tangent
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

    [theta, ia] = unique(round(theta,4));
    sigma_theta = sigma_theta(ia);

    [theta_s, idx] = sort(theta);
    sigma_s = sigma_theta(idx);

    fprintf('Max hoop stress (ellipse) = %.4f MPa\n', max(sigma_s));
end