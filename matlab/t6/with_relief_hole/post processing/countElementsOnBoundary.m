function nElems = countElementsOnBoundary(coordinates, elements, kind, geo)
% =========================================================================
%   countElementsOnBoundary
%   Counts T6 elements that touch a curved boundary (ellipse or circle).
%
% INPUTS:
%   coordinates : [nNodes x 2]
%   elements    : [nElem  x 6]   T6 connectivity (Gmsh ordering)
%   kind        : 'ellipse' | 'circle'
%   geo         : struct with fields:
%                   'ellipse' -> a, b
%                   'circle'  -> cx, cy, r
%
% OUTPUT:
%   nElems : number of T6 elements with >= 1 EDGE on the curve.
%            We use "edge" (2 corner nodes) rather than "any node" because
%            that is what actually contributes to boundary integrals and
%            to the hoop-stress sampling.
%
% USED BY:  run_convergence_study_T6.m  (per-case mesh metrics)
% =========================================================================
%
% Method:
%   1. Build a logical mask `onCurve(node)` for every NODE on the curve,
%      using a relative geometric tolerance.
%   2. A T6 has 3 corner nodes (cols 1:3) and 3 mid-side nodes (4:6).
%      The 3 edges are: (1-4-2), (2-5-3), (3-6-1).
%      An element is "on the curve" iff at least one of these triplets is
%      fully on the curve.
%   3. Count such elements.
%
% Why three-node-per-edge check, not just two corners?
%   T6 mid-side nodes are placed exactly on the curve by Gmsh when
%   Mesh.ElementOrder=2 with curved boundary. Requiring the mid node too
%   eliminates false positives where a corner happens to coincide with the
%   curve but the edge actually cuts across the interior.
% =========================================================================

    nNodes = size(coordinates, 1);
    onCurve = false(nNodes, 1);

    switch lower(kind)
        case 'ellipse'
            a = geo.a;  b = geo.b;
            % Use relative tolerance: lenient enough for mid-side nodes
            % that Gmsh places on the curve numerically (not exactly).
            tol = 5e-3;
            for n = 1:nNodes
                x = coordinates(n,1);  y = coordinates(n,2);
                if abs((x/a)^2 + (y/b)^2 - 1) < tol
                    onCurve(n) = true;
                end
            end

        case 'circle'
            cx = geo.cx;  cy = geo.cy;  r = geo.r;
            tol = 5e-3 * r^2;     % scale tolerance with r^2 (matches the metric used)
            for n = 1:nNodes
                x = coordinates(n,1);  y = coordinates(n,2);
                if abs((x-cx)^2 + (y-cy)^2 - r^2) < tol
                    onCurve(n) = true;
                end
            end

        otherwise
            error('countElementsOnBoundary:BadKind', ...
                  'kind must be ''ellipse'' or ''circle''.');
    end

    % T6 edge triplets in Gmsh ordering: (1-4-2), (2-5-3), (3-6-1)
    edges = [1 4 2; 2 5 3; 3 6 1];

    nElem  = size(elements, 1);
    isOn   = false(nElem, 1);

    for e = 1:nElem
        nd = elements(e, :);
        for k = 1:3
            triplet = nd(edges(k,:));
            if all(onCurve(triplet))
                isOn(e) = true;
                break;
            end
        end
    end

    nElems = sum(isOn);
end
