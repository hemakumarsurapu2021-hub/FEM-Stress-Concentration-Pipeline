function Ke = T6elementStiffness(elementCoords, E, nu, t)
% -----------------------------------------------------
% T6 Element Stiffness Matrix (Plane Stress)
% -----------------------------------------------------
% Uses 7-point Gaussian quadrature over the reference triangle.
%
% T6 node numbering (Gmsh convention):
%   1, 2, 3  — corner nodes
%   4 = midpoint(1,2),  5 = midpoint(2,3),  6 = midpoint(1,3)
%
% Natural coordinates (L1, L2, L3 = area coordinates):
%   Node 1: (1,0,0)   Node 2: (0,1,0)   Node 3: (0,0,1)
%   Node 4: (0.5,0.5,0)  Node 5: (0,0.5,0.5)  Node 6: (0.5,0,0.5)
%
% Shape functions in terms of L1=xi, L2=eta, L3=1-xi-eta:
%   N1 = L1(2L1-1)   N2 = L2(2L2-1)   N3 = L3(2L3-1)
%   N4 = 4L1L2       N5 = 4L2L3       N6 = 4L1L3
%
% INPUT:
%   elementCoords : [6 x 2] nodal coordinates (x,y), rows = nodes 1..6
%   E             : Young's modulus
%   nu            : Poisson's ratio
%   t             : thickness
%
% OUTPUT:
%   Ke : [12 x 12] element stiffness matrix
% -----------------------------------------------------

    % ── Material matrix (plane stress) ──────────────────────────────────
    D = (E / (1 - nu^2)) * [1,  nu,        0;
                             nu,  1,        0;
                              0,  0, (1-nu)/2];

    % ── 7-point Gauss quadrature on standard triangle (L1+L2+L3=1) ─────
    % Dunavant degree-5 rule: exact for polynomials up to degree 5.
    % Weights sum to 0.5 (area of reference triangle).
    a1 = 0.059715871789770;  b1 = 0.470142064105115;
    a2 = 0.797426985353087;  b2 = 0.101286507323456;

    GP = [1/3,    1/3;          % centroid
          a1,     b1;
          b1,     a1;
          b1,     b1;
          a2,     b2;
          b2,     a2;
          b2,     b2];

    W  = [0.225000000000000;
          0.132394358382601;
          0.132394358382601;
          0.132394358382601;
          0.125939180544827;
          0.125939180544827;
          0.125939180544827];
    % Weights already include the 1/2 factor for area of reference triangle

    nGP = 7;
    Ke  = zeros(12, 12);

    for gp = 1:nGP
        xi  = GP(gp, 1);
        eta = GP(gp, 2);
        zeta = 1 - xi - eta;    % L3

        % ── Shape function derivatives w.r.t. xi and eta ──────────────
        % dN/dxi  (column = node index 1..6)
        dN_dxi = [4*xi  - 1,   0,           -(4*zeta - 1), ...
                  4*eta,       -4*eta,        4*(zeta - xi)];

        % dN/deta
        dN_deta = [0,           4*eta - 1,  -(4*zeta - 1), ...
                   4*xi,        4*(zeta - eta), -4*xi];

        % ── Jacobian [2x2] ─────────────────────────────────────────────
        J    = [dN_dxi; dN_deta] * elementCoords;   % [2x2]
        detJ = det(J);

        if detJ <= 0
            error('T6elementStiffness: non-positive Jacobian (detJ = %.4e). Check node ordering.', detJ);
        end

        % ── Physical derivatives dN/dx, dN/dy ─────────────────────────
        dN = J \ [dN_dxi; dN_deta];    % [2x6]

        % ── B matrix [3 x 12] ──────────────────────────────────────────
        B = zeros(3, 12);
        for j = 1:6
            B(1, 2*j-1) = dN(1, j);   % dN/dx  → eps_xx
            B(2, 2*j  ) = dN(2, j);   % dN/dy  → eps_yy
            B(3, 2*j-1) = dN(2, j);   % dN/dy  → gamma_xy (u part)
            B(3, 2*j  ) = dN(1, j);   % dN/dx  → gamma_xy (v part)
        end

        % ── Element stiffness contribution ─────────────────────────────
        Ke = Ke + B' * D * B * t * detJ * W(gp);
    end

end
