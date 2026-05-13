function [stress, stressNode] = computeStressT6(coordinates, elements, U, E, nu)
% -----------------------------------------------------
% COMPUTE STRESS FOR T6 ELEMENTS (PLANE STRESS)
% -----------------------------------------------------
% Computes stress at 7 Gauss points per element (Dunavant degree-5 rule)
% and performs nodal averaging for visualization.
%
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem  x 6] T6 connectivity matrix
%   U           : displacement vector [nDof x 1]
%   E, nu       : material properties
%
% OUTPUT:
%   stress     : [nElem x 7 x 3]  stress tensor components at each GP
%                index 3 → [sigma_x, sigma_y, tau_xy]
%   stressNode : [nNodes x 3]  averaged nodal stress for visualization
% -----------------------------------------------------

    % ── Material matrix (plane stress) ──────────────────────────────────
    D = (E / (1 - nu^2)) * [1,  nu,        0;
                             nu,  1,        0;
                              0,  0, (1-nu)/2];

    nElem  = size(elements, 1);
    nNodes = size(coordinates, 1);

    % ── 7-point Dunavant quadrature (same as in T6elementStiffness) ─────
    a1 = 0.059715871789770;  b1 = 0.470142064105115;
    a2 = 0.797426985353087;  b2 = 0.101286507323456;

    GP = [1/3, 1/3;
          a1,  b1;
          b1,  a1;
          b1,  b1;
          a2,  b2;
          b2,  a2;
          b2,  b2];

    W = [0.225000000000000;
         0.132394358382601;
         0.132394358382601;
         0.132394358382601;
         0.125939180544827;
         0.125939180544827;
         0.125939180544827];

    nGP = 7;

    % ── Allocate outputs ─────────────────────────────────────────────────
    stress     = zeros(nElem, nGP, 3);
    stressNode = zeros(nNodes, 3);
    count      = zeros(nNodes, 1);

    % ── Element loop ─────────────────────────────────────────────────────
    for e = 1:nElem

        nodeIDs     = elements(e, :);               % [1 x 6]
        elementCoords = coordinates(nodeIDs, :);    % [6 x 2]

        % Extract element displacement vector [12 x 1]
        Ue = zeros(12, 1);
        for i = 1:6
            Ue(2*i - 1) = U(2 * nodeIDs(i) - 1);  % ux
            Ue(2*i    ) = U(2 * nodeIDs(i)    );   % uy
        end

        % ── Gauss point loop ─────────────────────────────────────────────
        for g = 1:nGP

            xi   = GP(g, 1);
            eta  = GP(g, 2);
            zeta = 1 - xi - eta;

            % Shape function derivatives w.r.t. xi and eta
            dN_dxi  = [4*xi - 1,    0,          -(4*zeta - 1), ...
                        4*eta,      -4*eta,       4*(zeta - xi)];

            dN_deta = [0,            4*eta - 1,  -(4*zeta - 1), ...
                        4*xi,        4*(zeta - eta), -4*xi];

            % Jacobian
            J    = [dN_dxi; dN_deta] * elementCoords/2;
            detJ = det(J);

            % Physical derivatives
            dN = J \ [dN_dxi; dN_deta];    % [2 x 6]

            % B matrix [3 x 12]
            B = zeros(3, 12);
            for j = 1:6
                B(1, 2*j-1) = dN(1, j);
                B(2, 2*j  ) = dN(2, j);
                B(3, 2*j-1) = dN(2, j);
                B(3, 2*j  ) = dN(1, j);
            end

            % Strain and stress
            epsilon = B * Ue;
            sigma   = D * epsilon;

            stress(e, g, :) = sigma;

        end

        % ── Nodal averaging: distribute element GP average to corner+midside nodes
        avg_sigma = squeeze(mean(stress(e, :, :), 2));   % [3 x 1]

        for i = 1:6
            node = nodeIDs(i);
            stressNode(node, :) = stressNode(node, :) + avg_sigma';
            count(node)         = count(node) + 1;
        end

    end

    % ── Normalize ────────────────────────────────────────────────────────
    stressNode = stressNode ./ count;

end
