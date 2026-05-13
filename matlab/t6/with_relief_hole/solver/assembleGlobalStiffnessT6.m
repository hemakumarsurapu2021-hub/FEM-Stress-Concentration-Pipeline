function K_global = assembleGlobalStiffnessT6(coordinates, elements, E, nu, t)
% -----------------------------------------------------
% Assemble Global Stiffness Matrix for T6 Elements
% -----------------------------------------------------
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem  x 6] connectivity matrix (T6)
%   E           : Young's modulus
%   nu          : Poisson's ratio
%   t           : thickness
%
% OUTPUT:
%   K_global : [nDof x nDof] global stiffness matrix (sparse)
%              nDof = 2 * nNodes
% -----------------------------------------------------

    nNodes = size(coordinates, 1);
    nDof   = 2 * nNodes;
    nElem  = size(elements, 1);

    % ── Sparse triplet pre-allocation ───────────────────────────────────
    % Each T6 element contributes 12x12 = 144 entries
    nnz_est = nElem * 144;
    Iv = zeros(nnz_est, 1);
    Jv = zeros(nnz_est, 1);
    Vv = zeros(nnz_est, 1);

    for e = 1:nElem

        nodeIDs     = elements(e, :);               % [1 x 6]
        elementCoords = coordinates(nodeIDs, :);    % [6 x 2]

        % ── Element stiffness [12 x 12] ────────────────────────────────
        Ke = T6elementStiffness(elementCoords, E, nu, t);

        % ── DOF mapping: [ux1 uy1 ux2 uy2 ... ux6 uy6] ────────────────
        dof = zeros(1, 12);
        for i = 1:6
            dof(2*i - 1) = 2 * nodeIDs(i) - 1;    % x-DOF
            dof(2*i    ) = 2 * nodeIDs(i);          % y-DOF
        end

        % ── Store triplet entries ───────────────────────────────────────
        [ri, ci] = ndgrid(dof, dof);
        base = (e - 1) * 144 + 1;
        Iv(base : base + 143) = ri(:);
        Jv(base : base + 143) = ci(:);
        Vv(base : base + 143) = Ke(:);

    end

    % ── Single sparse assembly call ─────────────────────────────────────
    K_global = sparse(Iv, Jv, Vv, nDof, nDof);

end
