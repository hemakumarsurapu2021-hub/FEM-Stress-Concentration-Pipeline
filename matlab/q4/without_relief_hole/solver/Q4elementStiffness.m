function Ke = Q4elementStiffness(elementCoords, E, nu, t)

% -----------------------------------------------------
% Q4 Element Stiffness Matrix (Plane Stress)
% -----------------------------------------------------
% INPUT:
%   elementCoords : [4 x 2] nodal coordinates
%   E             : Young's modulus
%   nu            : Poisson's ratio
%   t             : thickness
%
% OUTPUT:
%   Ke : [8 x 8] element stiffness matrix
% -----------------------------------------------------

    % Material matrix (plane stress)
    D = (E/(1-nu^2)) * [1 nu 0;
                        nu 1 0;
                        0 0 (1-nu)/2];
    % Gauss Points
    gaussPoints = [-1 -1; 1 -1; 1 1; -1 1]/sqrt(3);         % 1st column --> xi, 2nd column --> eta
    weights = [1 1 1 1];                                    % W1, W2

    % Initializing the stiffness matrix
    Ke = zeros(8, 8);
    
    for i = 1:4
    
        xi = gaussPoints(i,1);
        eta = gaussPoints(i,2);
    
        dN_dxi = [-0.25*(1 - eta), 0.25*(1 - eta), 0.25*(1 + eta), -0.25*(1 + eta) ];
        dN_deta = [-0.25*(1 - xi), -0.25*(1 + xi), 0.25*(1 + xi), 0.25*(1 - xi) ];
    
        J = [dN_dxi; dN_deta]*elementCoords;
        detJ = det(J);
        %invJ = inv(J);
    
        %dN = invJ * [dN_dxi; dN_deta];
        dN = J \ [dN_dxi; dN_deta];
    
        % Compute the B matrix
        B = zeros(3, 8);
        for j = 1:4
            B(1, 2*j-1) = dN(1,j);
            B(2, 2*j) = dN(2,j);
            B(3, 2*j-1) = dN(2,j);
            B(3, 2*j) = dN(1,j);
        end
    
        Ke = Ke + B' * D * B * t * detJ * weights(i);
    
    end

end
