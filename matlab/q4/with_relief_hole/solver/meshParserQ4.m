
function [coordinates, elements] = meshParserQ4(filename)

% -----------------------------------------------------
% Mesh Parser for Gmsh (.msh) - Q4 Elements Only
% -----------------------------------------------------
% INPUT:
%   filename    : name of .msh file
%
% OUTPUT:
%   coordinates : [N x 2] node coordinates (x, y)
%   elements    : [Ne x 4] connectivity matrix (Q4)
% -----------------------------------------------------
    
    % Load the mesh data from a GMSH file
    fid = fopen('Elliptical_Hole_with_circular_hole.msh','r');            % fid = File ID, r = read
    
    if fid == -1
        error(['File could not be opened: ', Elliptical_Hole_with_circular_hole.geo]);
    end

    % Initialize
    coordinates = [];                 % Preparing empty array to store the nodal values
    elements = [];
    
    while ~feof(fid)            % feof = File end of File, ~feof = file not ended
        line = strtrim(fgetl(fid));              % Read one line from the file by removing the extra spaces
                                                 % strtrim - Remove leading and trailing whitespace from strings
        
        % ------------------- NODES ------------------- %                                        
        if strcmp(line,'$Nodes')                 % If current line is exactly $Nodes, starts node parsing
            data = sscanf(fgetl(fid),'%f');      % str2double - Convert strings to double precision values
            
            if length(data) == 1
                nNodes = data(1);                % Gmsh version 2
            else
                nNodes = data(2);                % Gmsh version 4
            end
    
            nodes = zeros(nNodes,4);              % 3 rows for Line id, x, y
            for i = 1:nNodes                     % Reading each node
                data = sscanf(fgetl(fid),'%f');  % Extract data from string and convert it to specified format
                nodes(i,:) = data';              % data' is used becuase sscanf gives column vector
            end
            coordinates = nodes(:,2:3);
    
        end

        % ------------------- ELEMENTS ------------------- %
        if strcmp(line,'$Elements')
            nElem = str2double(fgetl(fid));
            elemList = zeros(0,4);
            for i = 1:nElem
                data = sscanf(fgetl(fid),'%f');
                elemType = data(2);                  % [element_id, element_type, numTags, tag, tag, node id x, y, z]
                
                % Only Quadrilateral elements
                if elemType == 3                     % 1 - line, 2 - triangle, 3 - quadrilateral
                    numTags = data(3);
                    nodeIDs = data(4+numTags : end)';
                    if length(nodeIDs) == 4
                        elemList = [elemList; nodeIDs];
                    end
                end
            end
            elements = elemList;
        end
    end

    fclose(fid);

    fprintf('Number of nodes : %.4f\n',size(coordinates, 1));
    fprintf('Number of elements : %.4f\n',size(elements, 1));

end
