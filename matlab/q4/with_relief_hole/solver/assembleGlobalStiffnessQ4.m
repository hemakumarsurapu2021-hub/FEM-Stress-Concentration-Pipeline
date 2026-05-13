function K_global = assembleGlobalStiffnessQ4(coordinates, elements, E, nu, t)
% -----------------------------------------------------
% Assemble Global Stiffness Matrix for Q4 Elements
% -----------------------------------------------------
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem x 4] connectivity matrix
%   E           : Young's modulus
%   nu          : Poisson's ratio
%   t           : thickness
%
% OUTPUT:
%   K_global    : [nDof x nDof] global stiffness matrix (sparse)
% -----------------------------------------------------

    % Number of nodes and DOFs
    nNodes = size(coordinates,1);
    nDof   = 2 * nNodes;

    % Initialize sparse global stiffness matrix
    K_global = sparse(nDof, nDof);

    % Loop over elements
    for e = 1:size(elements,1)

        % ---- Get element node IDs ----
        nodeIDs = elements(e,:);

        % ---- Get element coordinates ----
        elementCoords = coordinates(nodeIDs,:);

        % ---- Compute element stiffness ----
        Ke = Q4elementStiffness(elementCoords, E, nu, t);

        % ---- DOF mapping ----
        dof = zeros(1,8);

        for i = 1:4
            dof(2*i-1) = 2*nodeIDs(i) - 1;   % ux
            dof(2*i)   = 2*nodeIDs(i);       % uy
        end

        % ---- Assembly ----
        K_global(dof, dof) = K_global(dof, dof) + Ke;

        % ---- Progress display (lightweight) ----
        %if mod(e,500) == 0
        %    disp(['Assembling element: ', num2str(e)])
        %end

    end

end