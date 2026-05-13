function [stress, stressNode] = computeStressQ4(coordinates, elements, U, E, nu)
% -----------------------------------------------------
% COMPUTE STRESS FOR Q4 ELEMENTS (PLANE STRESS)
% -----------------------------------------------------
% Computes stress at 4 Gauss points per element and
% visualizes sigma_x distribution
%
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem x 4] connectivity matrix
%   U           : displacement vector [nDof x 1]
%   E, nu       : material properties
%
% OUTPUT:
%   stress      : [nElem x 4 x 3] --> [sigma_x, sigma_y, tau_xy] for each element
%                 (element, gauss point, stress component)
%   stressNode  : averaged nodal stress (for visualization)
% -----------------------------------------------------

    % Material matrix (plane stress)
    D = (E/(1-nu^2)) * [1 nu 0;
                        nu 1 0;
                        0  0 (1-nu)/2];

    nElem = size(elements,1);

    % 4 Gauss points
    gp = [-1 -1;
           1 -1;
           1  1;
          -1  1] / sqrt(3);

    % Store stress: (element, gauss point, [sx sy txy])
    stress = zeros(nElem,4,3);

    % For visualization (averaged to nodes)
    nNodes = size(coordinates,1);
    stressNode = zeros(nNodes,3);
    count = zeros(nNodes,1);

    % Loop over elements
    for e = 1:nElem

        nodeIDs = elements(e,:);
        elementCoords = coordinates(nodeIDs,:);

        % Extract element displacement vector
        Ue = zeros(8,1);
        for i = 1:4
            Ue(2*i-1) = U(2*nodeIDs(i)-1);
            Ue(2*i)   = U(2*nodeIDs(i));
        end

        % Loop over Gauss points
        for g = 1:4

            xi  = gp(g,1);
            eta = gp(g,2);

            % Shape function derivatives
            dN_dxi = [-0.25*(1 - eta), 0.25*(1 - eta), ...
                       0.25*(1 + eta), -0.25*(1 + eta)];

            dN_deta = [-0.25*(1 - xi), -0.25*(1 + xi), ...
                        0.25*(1 + xi),  0.25*(1 - xi)];

            % Jacobian
            J = [dN_dxi; dN_deta] * elementCoords;

            % Convert derivatives
            dN = J \ [dN_dxi; dN_deta];

            % B matrix
            B = zeros(3,8);
            for j = 1:4
                B(1,2*j-1) = dN(1,j);
                B(2,2*j)   = dN(2,j);
                B(3,2*j-1) = dN(2,j);
                B(3,2*j)   = dN(1,j);
            end

            % Strain and stress
            epsilon = B * Ue;
            sigma = D * epsilon;

            % Store
            stress(e,g,:) = sigma;

        end

        % --------- SIMPLE NODAL AVERAGING (σx only) ---------
        avg_sigma = squeeze(mean(stress(e,:,:),2));

        for i = 1:4
            node = nodeIDs(i);
            stressNode(node,:) = stressNode(node,:) + avg_sigma';
            count(node) = count(node) + 1;
        end

    end

    % Normalize nodal stress
    stressNode = stressNode ./ count;

end