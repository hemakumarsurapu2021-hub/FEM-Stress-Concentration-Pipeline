function nElems = countElementsOnBoundary(coordinates, elements, kind, geo)
% =========================================================================
%   countElementsOnBoundary
%   Counts Q4 elements that touch a curved boundary (ellipse or circle).
%
% INPUTS:
%   coordinates : [nNodes x 2]
%   elements    : [nElem  x 4]   Q4 connectivity
%   kind        : 'ellipse' | 'circle'
%   geo         : struct with fields:
%                   ellipse -> a, b
%                   circle  -> cx, cy, r
%
% OUTPUT:
%   nElems : number of Q4 elements with >= 1 EDGE on the curve.
%            We use "edge" (2 corner nodes) rather than "any node" because
%            that is what actually contributes to boundary integrals and
%            to hoop-stress sampling. An element with just one corner on
%            the curve is touching it at a point, not lying on it.
%
% USED BY: run_convergence_study.m  (per-case mesh metrics)
% =========================================================================
%
% Method:
%   1. Build a logical mask `onCurve(node)` for every NODE on the curve,
%      using a relative geometric tolerance.
%   2. Q4 has 4 corner nodes and 4 edges: (1-2), (2-3), (3-4), (4-1).
%      An element is "on the curve" iff at least one edge has BOTH its
%      endpoints flagged as onCurve.
%   3. Count such elements.
% =========================================================================

    nNodes  = size(coordinates, 1);
    onCurve = false(nNodes, 1);

    switch lower(kind)
        case 'ellipse'
            a = geo.a;  b = geo.b;
            tol = 5e-3;     % relative tolerance on (x/a)^2 + (y/b)^2 - 1
            for n = 1:nNodes
                x = coordinates(n,1);  y = coordinates(n,2);
                if abs((x/a)^2 + (y/b)^2 - 1) < tol
                    onCurve(n) = true;
                end
            end

        case 'circle'
            cx = geo.cx;  cy = geo.cy;  r = geo.r;
            tol = 5e-3 * r^2;   % scale tolerance with r^2 (matches the metric used)
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

    % Q4 edge pairs
    edgePairs = [1 2; 2 3; 3 4; 4 1];

    nElem = size(elements, 1);
    isOn  = false(nElem, 1);

    for e = 1:nElem
        nd = elements(e, :);
        for k = 1:4
            pair = nd(edgePairs(k, :));
            if all(onCurve(pair))
                isOn(e) = true;
                break;
            end
        end
    end

    nElems = sum(isOn);
end
