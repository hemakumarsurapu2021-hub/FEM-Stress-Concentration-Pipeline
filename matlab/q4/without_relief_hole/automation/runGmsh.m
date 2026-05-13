function runGmsh(gmshPath, geoFile, mshFile)
% =========================================================================
%  runGmsh  —  Call Gmsh from MATLAB to generate a 2D quad mesh
% =========================================================================
%  Builds the system command:
%      gmsh <geoFile> -2 -o <mshFile> -format msh2
%
%  -2          : 2D mesh only
%  -format msh2: write Gmsh v2 ASCII format (compatible with meshParserQ4)
%  -v 0        : suppress Gmsh console output (set to 3 for debugging)
% =========================================================================

    % Build command string (cross-platform quoting for paths with spaces)
    cmd = sprintf('"%s" "%s" -2 -o "%s" -format msh2 -v 0', ...
                  gmshPath, geoFile, mshFile);

    % Execute
    [status, output] = system(cmd);

    if status ~= 0
        error(['Gmsh failed (exit code %d).\n' ...
               'Command: %s\n' ...
               'Output:\n%s\n\n' ...
               'Check that gmshPath is correct and Gmsh is installed.'], ...
               status, cmd, output);
    end

    % Verify output file was created
    if ~isfile(mshFile)
        error('Gmsh ran but .msh file was not created: %s', mshFile);
    end
end
