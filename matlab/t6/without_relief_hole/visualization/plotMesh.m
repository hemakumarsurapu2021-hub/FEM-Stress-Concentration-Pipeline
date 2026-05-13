function plotMesh(coordinates, elements)

    patch('Faces', elements, ...
          'Vertices', coordinates, ...
          'FaceColor', 'none', ...
          'EdgeColor', 'k');

    axis equal
    xlabel('X')
    ylabel('Y')
    title('Mesh Visualization')

end