function runGmsh(gmshExe, geoFile, mshFile)
% =========================================================================
%   runGmsh
%   Invokes Gmsh from MATLAB to mesh `geoFile` into `mshFile`.
%   Forces 2D meshing, LINEAR Q4 elements, and .msh format v2.2.
%
% INPUTS:
%   gmshExe : Gmsh executable. Just 'gmsh' if it is on PATH; else full path
%   geoFile : input .geo (already mutated by modifyGeoMeshSize)
%   mshFile : output .msh
%
% USED BY: run_convergence_study.m
% =========================================================================
%
% Command-line flags used:
%   -2          : 2D mesh
%   -order 1    : LINEAR (Q4), not Q8 — overrides .geo if it sneaks in
%   -format msh22  : force .msh v2.2 ASCII (what meshParserQ4 reads)
%
% Quad recombination is controlled by the global Mesh.RecombineAll = 1
% directive injected into the .geo, plus any `Recombine Surface{...}`
% statements your template already had.
% =========================================================================

    if ~isfile(geoFile)
        error('runGmsh:NoGeo', '.geo file not found: %s', geoFile);
    end

    cmd = sprintf('"%s" "%s" -2 -order 1 -format msh22 -o "%s"', ...
                  gmshExe, geoFile, mshFile);

    [status, out] = system(cmd);

    if ~isfile(mshFile)
        error('runGmsh:Failed', ...
              ['Gmsh did not produce mesh.\n' ...
               'Command: %s\nOutput:\n%s'], cmd, out);
    end
end
