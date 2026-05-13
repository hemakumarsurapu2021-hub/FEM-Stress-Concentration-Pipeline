function runGmsh(gmshExe, geoFile, mshFile)
% =========================================================================
%   runGmsh
%   Invokes Gmsh from MATLAB to mesh `geoFile` into `mshFile`.
%   Forces 2D meshing, second-order (T6), and .msh format v2.2.
%
% INPUTS:
%   gmshExe : Gmsh executable. Just 'gmsh' if it is on PATH; else full
%             path, e.g. 'C:\Program Files\gmsh\gmsh.exe'
%   geoFile : input .geo (already mutated by modifyGeoMeshSize)
%   mshFile : output .msh
%
% USED BY:  run_convergence_study_T6.m
% =========================================================================
%
% Why both -order 2 AND Mesh.ElementOrder=2 (already in the .geo)?
% Because command-line flags override .geo settings, and being explicit
% protects against templates that accidentally re-set element order later.
%
% -format msh22 forces Gmsh's legacy v2.2 ASCII format, which is what the
% existing meshParserT6.m parses most reliably.
% =========================================================================

    if ~isfile(geoFile)
        error('runGmsh:NoGeo', '.geo file not found: %s', geoFile);
    end

    % Quote paths to handle spaces (Windows-friendly).
cmd = sprintf('%s "%s" -2 -order 2 -format msh22 -o "%s"', ...
    gmshExe, geoFile, mshFile);

    [status, out] = system(cmd);

    if status ~= 0 || ~isfile(mshFile)
        % Print Gmsh's stdout/stderr so the user can see WHY meshing failed.
        error('runGmsh:Failed', ...
              ['Gmsh failed (status %d).\n' ...
               'Command: %s\n' ...
               'Output:\n%s'], status, cmd, out);
    end
end
