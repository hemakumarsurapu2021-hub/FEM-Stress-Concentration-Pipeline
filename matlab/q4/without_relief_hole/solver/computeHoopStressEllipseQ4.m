function [theta, sigma_theta, theta_sorted, sigma_theta_sorted] = computeHoopStressEllipseQ4(coordinates, elements, stress)
% -----------------------------------------------------
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

    a = 25.40;    
    b = 45.72;    
    
    tol = 0.01;   % tighter tolerance (IMPORTANT FIX)
    
    theta = [];
    sigma_theta = [];
    
    for e = 1:size(elements,1)
    
        nodeIDs = elements(e,:);
        elementCoords = coordinates(nodeIDs,:);
    
        % ----------- Element center (Barlow point) -----------
        xc = mean(elementCoords(:,1));
        yc = mean(elementCoords(:,2));
    
        % ----------- Ellipse boundary filter -----------
        phi = xc^2/a^2 + yc^2/b^2;
    
        if phi > 0.95 && phi < 1.05
            % ----------- Stress (average of Gauss points) -----------
            sigmaX = mean(stress(e,:,1));
            sigmaY = mean(stress(e,:,2));
            tau_xy = mean(stress(e,:,3));
    
            sigma_mat = [sigmaX tau_xy; tau_xy sigmaY];
    
            % ----------- Angle mapping -----------
            th = atan2(yc/b, xc/a);
    
            % ----------- Tangent vector -----------
            tx = -a*sin(th);
            ty =  b*cos(th);
    
            t_vec = [tx; ty]/norm([tx; ty]);
    
            % ----------- Hoop stress -----------
            sigma_t = t_vec' * sigma_mat * t_vec;
    
            theta = [theta; th];
            sigma_theta = [sigma_theta; sigma_t];
    
        end
    end
    
    if isempty(theta)
        error('No ellipse points detected. Increase tolerance.');
    end
    
    % ----------- Sorting -----------
    [theta_sorted, idx] = sort(theta);
    sigma_theta_sorted = sigma_theta(idx);
    
    %{
    % ----------- Reduce duplicates (smooth curve) -----------
    theta_round = round(theta_sorted,3);
    [theta_unique, ia] = unique(theta_round);
    sigma_unique = sigma_theta_sorted(ia);
    %}
   
    % ----------- Print result -----------
    fprintf('Maximum Hoop Stress (sigma_theta) = %.4f MPa\n',max(sigma_theta_sorted));
    
end