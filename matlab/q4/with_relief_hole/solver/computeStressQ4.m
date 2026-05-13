function [stress, stressNode, deltaSigmaNode] = computeStressQ4(coordinates, elements, U, E, nu)
% =========================================================================
%  computeStressQ4  —  Gauss-point and nodal stresses for Q4 plane stress
% =========================================================================
%
%  CHANGES vs. original:
%    • Added third output: deltaSigmaNode  [nNodes x 1]
%      Δσ = σ_max_principal − σ_min_principal  (σ2 − σ1 per assignment)
%      where σ1 ≤ σ2 (algebraic convention consistent with the assignment).
%
%  All original outputs (stress, stressNode) are UNCHANGED.
%
%  INPUTS
%    coordinates : [nNodes x 2]  nodal coordinates
%    elements    : [nElem  x 4]  connectivity matrix
%    U           : [2*nNodes x 1] displacement vector
%    E, nu       : material constants
%
%  OUTPUTS
%    stress        : [nElem x 4 x 3]  Gauss-point stresses [sxx syy txy]
%    stressNode    : [nNodes x 3]     averaged nodal stresses
%    deltaSigmaNode: [nNodes x 1]     Δσ = σ2 − σ1 (principal stress difference)
% =========================================================================

    % Material matrix (plane stress)
    D = (E/(1-nu^2)) * [1  nu       0;
                        nu  1       0;
                        0   0  (1-nu)/2];

    nElem  = size(elements, 1);
    nNodes = size(coordinates, 1);

    % 4 Gauss points (same as original)
    gp = [-1 -1;
           1 -1;
           1  1;
          -1  1] / sqrt(3);

    % Pre-allocate
    stress      = zeros(nElem, 4, 3);
    stressNode  = zeros(nNodes, 3);
    count       = zeros(nNodes, 1);

    % Per-node principal stress accumulators (for averaging before Δσ)
    s1Node = zeros(nNodes, 1);   % min principal
    s2Node = zeros(nNodes, 1);   % max principal
    % (averaged the same way as stressNode, then Δσ computed at end)

    % ---- Loop over elements ----
    for e = 1:nElem

        nodeIDs       = elements(e, :);
        elementCoords = coordinates(nodeIDs, :);

        % Element displacement vector
        Ue = zeros(8, 1);
        for i = 1:4
            Ue(2*i-1) = U(2*nodeIDs(i)-1);
            Ue(2*i)   = U(2*nodeIDs(i));
        end

        % ---- Loop over Gauss points ----
        for g = 1:4

            xi  = gp(g, 1);
            eta = gp(g, 2);

            dN_dxi  = [-0.25*(1-eta),  0.25*(1-eta), ...
                        0.25*(1+eta), -0.25*(1+eta)];
            dN_deta = [-0.25*(1-xi), -0.25*(1+xi), ...
                        0.25*(1+xi),  0.25*(1-xi)];

            J   = [dN_dxi; dN_deta] * elementCoords;
            dN  = J \ [dN_dxi; dN_deta];

            B = zeros(3, 8);
            for j = 1:4
                B(1, 2*j-1) = dN(1, j);
                B(2, 2*j)   = dN(2, j);
                B(3, 2*j-1) = dN(2, j);
                B(3, 2*j)   = dN(1, j);
            end

            epsilon       = B * Ue;
            sigma         = D * epsilon;
            stress(e,g,:) = sigma;

        end

        % ---- Nodal averaging (identical to original) ----
        avg_sigma = squeeze(mean(stress(e,:,:), 2));   % [3 x 1]: [sxx syy txy]

        % Principal stresses from averaged element stress
        sxx_avg = avg_sigma(1);
        syy_avg = avg_sigma(2);
        txy_avg = avg_sigma(3);

        centre  = (sxx_avg + syy_avg) / 2;
        radius  = sqrt(((sxx_avg - syy_avg)/2)^2 + txy_avg^2);
        s1_elem = centre - radius;   % minimum principal (algebraic)
        s2_elem = centre + radius;   % maximum principal

        for i = 1:4
            node = nodeIDs(i);
            stressNode(node, :) = stressNode(node, :) + avg_sigma';
            s1Node(node) = s1Node(node) + s1_elem;
            s2Node(node) = s2Node(node) + s2_elem;
            count(node)  = count(node) + 1;
        end

    end

    % ---- Normalize ----
    stressNode    = stressNode ./ count;
    s1Node        = s1Node     ./ count;
    s2Node        = s2Node     ./ count;

    % ---- Δσ = σ2 − σ1 (assignment convention: difference of max and min) ----
    deltaSigmaNode = s2Node - s1Node;   % always ≥ 0

end
