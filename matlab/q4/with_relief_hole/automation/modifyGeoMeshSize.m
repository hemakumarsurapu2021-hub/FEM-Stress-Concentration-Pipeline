function modifyGeoMeshSize(templateFile, outFile, lc)
% =========================================================================
%   modifyGeoMeshSize
%   Copies the .geo template to outFile, updating the mesh size lc and
%   forcing LINEAR Q4 elements + Gmsh .msh v2.2 output.
%
% INPUTS:
%   templateFile : path to original .geo (read-only)
%   outFile      : path to per-case .geo (will be created/overwritten)
%   lc           : new characteristic mesh size (mm)
%
% USED BY: run_convergence_study.m  (called inside runOneCase)
% =========================================================================
%
% STRATEGY:
%   1. Read the entire template.
%   2. Replace any existing `lc = ... ;` definition with the new value.
%      Add more variable names to KNOWN_LC_NAMES if your template uses a
%      different symbol (e.g. 'cl1', 'h').
%   3. Strip any pre-existing Mesh.* directives that would conflict.
%   4. Append the enforced settings:
%         Mesh.ElementOrder         = 1;     // Q4 (linear), NOT T6
%         Mesh.RecombineAll         = 1;     // force quads (recombine triangles)
%         Mesh.Algorithm            = 8;     // Frontal-Delaunay for quads
%         Mesh.MshFileVersion       = 2.2;
%
%   The recombine + algorithm 8 setting is what makes Gmsh produce Q4
%   elements (Gmsh meshes triangularly first, then recombines).  If your
%   .geo already uses `Recombine Surface{...}` per surface, these globals
%   are harmless but useful as belt-and-braces.
% =========================================================================

    if ~isfile(templateFile)
        error('modifyGeoMeshSize:NoTemplate', ...
              'Template .geo file not found: %s', templateFile);
    end

    raw = fileread(templateFile);

    % Names this routine recognises as "the mesh size variable"
    KNOWN_LC_NAMES = {'lc', 'cl', 'cl1', 'h', 'meshSize'};

    for k = 1:numel(KNOWN_LC_NAMES)
        name = KNOWN_LC_NAMES{k};
        pat  = ['(^|\n)\s*' name '\s*=\s*[^;]+;'];
        repl = ['$1' name ' = ' num2str(lc, '%.10g') ';'];
        raw  = regexprep(raw, pat, repl);
    end

    % Strip pre-existing meshing directives that we will re-set
    % safer cleanup
    raw = regexprep(raw, 'Mesh\.[^;]+;', '');
    raw = regexprep(raw, 'Recombine Surface\{[^}]+\};', '');

    % Insurance: define `lc` if the template referenced it without defining it
    if isempty(regexp(raw, '(^|\n)\s*lc\s*=', 'once'))
        raw = sprintf('lc = %s;\n%s', num2str(lc, '%.10g'), raw);
    end

    enforced = sprintf([ ...
        '\n\n// === injected by modifyGeoMeshSize ===\n' ...
        'Mesh.ElementOrder   = 1;\n' ...
        'Mesh.RecombineAll   = 1;\n' ...
        'Mesh.Algorithm      = 8;\n' ...
        'Mesh.MshFileVersion = 2.2;\n']);
    raw = [raw enforced];

    fid = fopen(outFile, 'w');
    if fid == -1
        error('modifyGeoMeshSize:Write', ...
              'Could not open output .geo for writing: %s', outFile);
    end
    fwrite(fid, raw);
    fclose(fid);
end
