function [coordinates, elements] = meshParserT6(filename)
% -----------------------------------------------------
% Mesh Parser for Gmsh (.msh v2) — T6 Elements Only
% -----------------------------------------------------
% T6 = 6-node quadratic triangle, Gmsh element type 9
%
% INPUT:
%   filename    : path to .msh file (Gmsh format v2)
%
% OUTPUT:
%   coordinates : [nNodes x 2] node coordinates (x, y)
%   elements    : [nElem  x 6] connectivity matrix (T6)
%                 node ordering follows Gmsh convention:
%                 [corner1, corner2, corner3, mid12, mid23, mid13]
% -----------------------------------------------------

    fid = fopen(filename, 'r');
    if fid == -1
        error('File could not be opened: %s', filename);
    end

    coordinates = [];
    elements    = [];

    while ~feof(fid)
        line = strtrim(fgetl(fid));

        % ------------------- NODES ------------------- %
        if strcmp(line, '$Nodes')
    
            header = sscanf(fgetl(fid), '%d');
            
            if length(header) == 1
                % -------- Gmsh v2 --------
                nNodes = header(1);
                nodes = zeros(nNodes, 3);
                
                for i = 1:nNodes
                    data = sscanf(fgetl(fid), '%f');
                    nodes(i,:) = data(2:4)';
                end
                
            else
                % -------- Gmsh v4 --------
                nBlocks = header(1);
                nNodes  = header(2);
                
                nodes = zeros(nNodes, 3);
                count = 1;
                
                for b = 1:nBlocks
                    blockInfo = sscanf(fgetl(fid), '%d');
                    nBlockNodes = blockInfo(end);
                    
                    % Read node IDs (ignore)
                    for i = 1:nBlockNodes
                        fgetl(fid);
                    end
                    
                    % Read coordinates
                    for i = 1:nBlockNodes
                        data = sscanf(fgetl(fid), '%f');
                        nodes(count,:) = data';
                        count = count + 1;
                    end
                end
            end
            
            coordinates = nodes(:,1:2);
        end

        % ------------------- ELEMENTS ------------------- %
        if strcmp(line, '$Elements')
            nElem    = str2double(fgetl(fid));
            elemList = zeros(0, 6);

            for i = 1:nElem
                data     = sscanf(fgetl(fid), '%f');
                elemType = data(2);

                % Gmsh element type 9 = 6-node quadratic triangle (T6)
                if elemType == 9
                    numTags = data(3);
                    nodeIDs = data(4 + numTags : end)';
                    if length(nodeIDs) == 6
                        elemList = [elemList; nodeIDs];
                    end
                end
            end
            elements = elemList;
        end
    end

    fclose(fid);

    fprintf('Number of nodes    : %d\n', size(coordinates, 1));
    fprintf('Number of T6 elements : %d\n', size(elements, 1));

end
