function [theta, sigma_theta, theta_s, sigma_s] = ...
    computeHoopStressCircleT6(coordinates, stressNode, cx, cy, r)

    tol = 1e-3;

    theta = [];
    sigma_theta = [];

    for node = 1:size(coordinates,1)

        x = coordinates(node,1);
        y = coordinates(node,2);

        % Check if node lies on circle
        if abs((x - cx)^2 + (y - cy)^2 - r^2) < tol

            % Angle around circle
            th = atan2(y - cy, x - cx);

            % Tangent direction (circle)
            T = [-sin(th), cos(th)];

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

    % Remove duplicates & sort
    [theta, ia] = unique(round(theta,4));
    sigma_theta = sigma_theta(ia);

    [theta_s, idx] = sort(theta);
    sigma_s = sigma_theta(idx);

    fprintf('Max hoop stress (circular hole) = %.4f MPa\n', max(sigma_s));
end