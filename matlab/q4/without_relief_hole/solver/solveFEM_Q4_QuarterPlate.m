function [U, F, K_global, fixedDOF, freeDOF] = solveFEM_Q4_QuarterPlate(coordinates, elements, E, nu, t, sigma_x)
% -----------------------------------------------------
% FEM SOLVER FOR Q4 ELEMENT (QUARTER PLATE WITH HOLE)
% -----------------------------------------------------
% This function performs:
% 1. Global stiffness matrix assembly
% 2. Force vector construction using CONSISTENT TRACTION LOAD
% 3. Application of boundary conditions (symmetry)
% 4. Solution of reduced system KU = F
%
% NOTE:
% Consistent traction replaces lumped nodal force approach
% to eliminate artificial stress concentration at corners.
%
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem x 4] connectivity matrix
%   E           : Young's modulus
%   nu          : Poisson's ratio
%   t           : thickness
%   sigma_x     : applied stress in x-direction (MPa)
%
% OUTPUT:
%   U           : displacement vector [nDof x 1]
%   F           : global force vector (sparse)
%   K_global    : global stiffness matrix (sparse)
%   fixedDOF    : constrained DOFs
%   freeDOF     : unconstrained DOFs
% -----------------------------------------------------

    % ------------------ DOF SETUP ------------------
    nNodes = size(coordinates,1);       
    nDof   = 2 * nNodes;                

    % ------------------ GLOBAL STIFFNESS MATRIX ------------------
    % Already assumed to be assembled using sparse triplet method
    K_global = assembleGlobalStiffnessQ4(coordinates, elements, E, nu, t);

    % -----------------------------------------------------
    % FORCE VECTOR (CONSISTENT TRACTION IMPLEMENTATION)
    % -----------------------------------------------------
    % Instead of lumped nodal forces, we integrate traction
    % using shape functions → avoids artificial stress spikes

    F = sparse(nDof,1);   % Sparse vector improves efficiency

    tol = 1e-6;

    % Identify right boundary nodes (where traction is applied)
    rightNodes = find(abs(coordinates(:,1) - max(coordinates(:,1))) < tol);

    % Sort nodes in Y-direction to ensure correct edge connectivity
    [~, idx] = sort(coordinates(rightNodes,2));
    rightNodes = rightNodes(idx);

    % 2-point Gauss integration for line element
    gp = [-1/sqrt(3), 1/sqrt(3)];
    w  = [1, 1];

    % Loop over boundary edges
    for i = 1:length(rightNodes)-1

        % Edge nodes
        n1 = rightNodes(i);
        n2 = rightNodes(i+1);

        % Coordinates of edge nodes
        x1 = coordinates(n1,:);
        x2 = coordinates(n2,:);

        % Edge length
        L = norm(x2 - x1);

        % Loop over Gauss points
        for g = 1:2

            xi = gp(g);

            % Linear shape functions for edge (2-node element)
            N1 = (1 - xi)/2;
            N2 = (1 + xi)/2;

            % Jacobian for 1D mapping
            J_edge = L/2;

            % Traction vector (only x-direction)
            traction = [sigma_x; 0];

            % Consistent nodal force contribution
            f_local = [N1; N2] * (traction(1) * t * J_edge * w(g));

            % Assemble into global force vector
            F(2*n1 - 1) = F(2*n1 - 1) + f_local(1);
            F(2*n2 - 1) = F(2*n2 - 1) + f_local(2);

        end
    end

    % -----------------------------------------------------
    % BOUNDARY CONDITIONS (SYMMETRY CONDITIONS)
    % -----------------------------------------------------

    % Left boundary (x = 0) → ux = 0
    leftNodes = find(abs(coordinates(:,1)) < tol);

    % Bottom boundary (y = 0) → uy = 0
    bottomNodes = find(abs(coordinates(:,2)) < tol);

    % Initialize constrained DOFs
    fixedDOF = [];

    % Apply ux = 0 on left boundary
    for i = 1:length(leftNodes)
        fixedDOF(end+1) = 2*leftNodes(i) - 1;
    end

    % Apply uy = 0 on bottom boundary
    for i = 1:length(bottomNodes)
        fixedDOF(end+1) = 2*bottomNodes(i);
    end

    % -----------------------------------------------------
    % FREE DOFs
    % -----------------------------------------------------
    allDOF  = 1:nDof;
    freeDOF = setdiff(allDOF, fixedDOF);

    % -----------------------------------------------------
    % SOLVE SYSTEM KU = F
    % -----------------------------------------------------
    U = zeros(nDof,1);

    % Solve reduced system (sparse solver automatically used)
    U(freeDOF) = K_global(freeDOF, freeDOF) \ F(freeDOF);

end