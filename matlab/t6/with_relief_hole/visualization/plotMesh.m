function plotMesh(coordinates, elements)
% -----------------------------------------------------
% PLOT T6 MESH
% -----------------------------------------------------
% Displays the finite element mesh using corner nodes only
% (T6 → T3 patch faces for visualization).
%
% INPUT:
%   coordinates : [nNodes x 2] nodal coordinates
%   elements    : [nElem  x 6] T6 connectivity matrix
% -----------------------------------------------------

    figure;
    patch('Faces',    elements(:, 1:3), ...
          'Vertices', coordinates, ...
          'FaceColor','none', ...
          'EdgeColor','k');
    axis equal;
    xlabel('X');
    ylabel('Y');
    title('T6 Mesh Visualization');

end
