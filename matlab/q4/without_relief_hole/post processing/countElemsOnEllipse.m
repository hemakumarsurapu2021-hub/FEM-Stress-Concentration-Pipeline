function n = countElemsOnEllipse(coordinates, elements)
% =========================================================================
%  countElemsOnEllipse  —  Count Q4 elements adjacent to the elliptical hole
% =========================================================================
%  Uses the same centroid-proximity test as computeHoopStressEllipseQ4.
%  An element is "on the hole" if its centroid satisfies:
%       0.90 < x²/a² + y²/b² < 1.10
%
%  Matches the filter in computeHoopStressEllipseQ4 (phi range 0.95–1.05).
%  Slightly wider band used here for counting to avoid undercounting
%  coarse meshes where centroids sit a little further from the boundary.
% =========================================================================

    a = 25.40;
    b = 45.72;

    n = 0;
    for e = 1:size(elements, 1)
        nodeIDs = elements(e, :);
        xc = mean(coordinates(nodeIDs, 1));
        yc = mean(coordinates(nodeIDs, 2));
        phi = xc^2/a^2 + yc^2/b^2;
        if phi > 0.90 && phi < 1.10
            n = n + 1;
        end
    end
end
