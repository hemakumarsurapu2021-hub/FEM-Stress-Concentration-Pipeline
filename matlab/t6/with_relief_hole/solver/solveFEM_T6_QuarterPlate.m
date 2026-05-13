function [U, F, K_global, fixedDOF, freeDOF] = solveFEM_T6_QuarterPlate(coordinates, elements, E, nu, t, sigma_x)
% -----------------------------------------------------
% FEM SOLVER FOR T6 ELEMENT (QUARTER PLATE WITH HOLE)
% -----------------------------------------------------
% Performs:
%   1. Global stiffness matrix assembly (T6)
%   2. Consistent traction force vector on right boundary
%      (3-node quadratic edge, 3-point Gauss integration)
%   3. Symmetry boundary conditions
%   4. Solution of reduced sparse system KU = F
%
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem  x 6] T6 connectivity matrix
%   E           : Young's modulus (MPa)
%   nu          : Poisson's ratio
%   t           : thickness (mm)
%   sigma_x     : applied far-field stress in x-direction (MPa)
%
% OUTPUT:
%   U        : displacement vector [nDof x 1]
%   F        : global force vector (sparse) [nDof x 1]
%   K_global : global stiffness matrix (sparse) [nDof x nDof]
%   fixedDOF : constrained DOF indices
%   freeDOF  : unconstrained DOF indices
% -----------------------------------------------------

    nNodes = size(coordinates, 1);
    nDof   = 2 * nNodes;

    % ── 1. Global stiffness ─────────────────────────────────────────────
    K_global = assembleGlobalStiffnessT6(coordinates, elements, E, nu, t);

    % ── 2. Consistent traction force vector ─────────────────────────────
    % T6 boundary edges are quadratic (3 nodes: two corners + one midside).
    % We use 3-point Gauss quadrature on the reference interval [-1, 1].

    F   = sparse(nDof, 1);
    tol = 1e-6;

    xMax       = max(coordinates(:, 1));
    rightNodes = find(abs(coordinates(:, 1) - xMax) < tol);

    % Sort right-boundary nodes by Y coordinate
    [~, idx]   = sort(coordinates(rightNodes, 2));
    rightNodes = rightNodes(idx);

    % 3-point Gauss rule on [-1,1]
    gp_xi = [-sqrt(3/5),  0,  sqrt(3/5)];
    gp_w  = [5/9,       8/9,      5/9  ];

    % Identify quadratic boundary edges from the element connectivity.
    % A T6 edge on the right boundary is defined by three nodes that all
    % lie on x = xMax.  We scan every element edge and collect them.
    %
    % T6 local edge node triples (corner-corner-midside, Gmsh ordering):
    %   Edge 1-2 : nodes [1, 2, 4]
    %   Edge 2-3 : nodes [2, 3, 5]
    %   Edge 3-1 : nodes [3, 1, 6]
    localEdges = [1, 2, 4;
                  2, 3, 5;
                  3, 1, 6];

    rightNodeSet = false(nNodes, 1);
    rightNodeSet(rightNodes) = true;

    processedEdges = containers.Map('KeyType','char','ValueType','logical');

    for e = 1:size(elements, 1)
        nodeIDs = elements(e, :);
        for ed = 1:3
            localIdx = localEdges(ed, :);          % [n_a, n_b, n_mid]
            gIDs     = nodeIDs(localIdx);           % global IDs
            if all(rightNodeSet(gIDs))
                % Canonical key (sorted corner IDs) to avoid duplicate edges
                key = sprintf('%d_%d', min(gIDs(1),gIDs(2)), max(gIDs(1),gIDs(2)));
                if ~isKey(processedEdges, key)
                    processedEdges(key) = true;

                    nA   = gIDs(1);   % corner node 1
                    nB   = gIDs(2);   % corner node 2
                    nMid = gIDs(3);   % midside node

                    xA = coordinates(nA,  :);
                    xB = coordinates(nB,  :);
                    xM = coordinates(nMid,:);

                    % Physical length of quadratic edge via 3-GP integration
                    % (for a straight edge this equals norm(xB-xA), but kept
                    %  general for curved edges near the ellipse)
                    for g = 1:3
                        xi = gp_xi(g);

                        % Quadratic shape functions on [-1,1]
                        NA  =  0.5 * xi * (xi - 1);
                        NB  =  0.5 * xi * (xi + 1);
                        NM  =  1   - xi^2;

                        % Physical position (for curved edges)
                        % x(xi) = NA*xA + NB*xB + NM*xM
                        % Jacobian = ||dx/dxi||
                        dxdxi = (xi - 0.5)*xA + (xi + 0.5)*xB + (-2*xi)*xM;
                        J_edge = norm(dxdxi);

                        % Consistent nodal forces (x-direction traction only)
                        fA   = NA  * sigma_x * t * J_edge * gp_w(g);
                        fB   = NB  * sigma_x * t * J_edge * gp_w(g);
                        fM   = NM  * sigma_x * t * J_edge * gp_w(g);

                        F(2*nA  - 1) = F(2*nA  - 1) + fA;
                        F(2*nB  - 1) = F(2*nB  - 1) + fB;
                        F(2*nMid - 1) = F(2*nMid - 1) + fM;
                    end
                end
            end
        end
    end

    % ── 3. Symmetry boundary conditions ─────────────────────────────────
    % Left boundary (x ≈ 0) : ux = 0
    leftNodes   = find(abs(coordinates(:, 1)) < tol);
    % Bottom boundary (y ≈ 0) : uy = 0
    bottomNodes = find(abs(coordinates(:, 2)) < tol);

    fixedDOF = [];
    for i = 1:length(leftNodes)
        fixedDOF(end+1) = 2 * leftNodes(i) - 1;    %#ok<AGROW>
    end
    for i = 1:length(bottomNodes)
        fixedDOF(end+1) = 2 * bottomNodes(i);       %#ok<AGROW>
    end

    allDOF  = 1 : nDof;
    freeDOF = setdiff(allDOF, fixedDOF);

    % ── 4. Solve ─────────────────────────────────────────────────────────
    U = zeros(nDof, 1);
    U(freeDOF) = K_global(freeDOF, freeDOF) \ F(freeDOF);

end
