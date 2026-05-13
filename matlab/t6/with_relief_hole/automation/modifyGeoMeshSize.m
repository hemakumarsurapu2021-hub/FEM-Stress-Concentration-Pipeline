function modifyGeoMeshSize(templateFile, outFile, lc)
% =========================================================================
%   modifyGeoMeshSize
%   Copies the .geo template to outFile, updating the mesh size lc and
%   forcing T6 elements + Gmsh .msh v2.2 output.
%
% INPUTS:
%   templateFile : path to original .geo (read-only)
%   outFile      : path to per-case .geo (will be created/overwritten)
%   lc           : new characteristic mesh size (mm)
%
% USED BY:  run_convergence_study_T6.m  (called inside runOneCase)
% =========================================================================
%
% STRATEGY:
%   1. Read the entire template.
%   2. Replace any existing `lc = ... ;` definition with the new value.
%      If the template uses a different variable name, we also append a
%      generic `lc = <value>;` line at the top so any DefineConstant /
%      MeshSize references resolve to the new value as long as the symbol
%      is `lc`.  If your template uses a different symbol (e.g. `cl1`),
%      pass that name in via a small edit below — see KNOWN_LC_NAMES.
%   3. Strip any existing Mesh.ElementOrder / Mesh.MshFileVersion lines so
%      our enforced settings can't be overridden.
%   4. Append the enforced settings at the end:
%         Mesh.ElementOrder    = 2;
%         Mesh.MshFileVersion  = 2.2;
%         Mesh.SecondOrderIncomplete = 0;   // ensure full T6 (not T6 incomplete)
%
%   This keeps geometry, physical groups, and meshing controls intact.
% =========================================================================

    if ~isfile(templateFile)
        error('modifyGeoMeshSize:NoTemplate', ...
              'Template .geo file not found: %s', templateFile);
    end

    % --- Read template ---------------------------------------------------
    raw = fileread(templateFile);

    % --- Names this routine recognises as "the mesh size variable" ------
    % Add more here if your .geo uses a different symbol.
    KNOWN_LC_NAMES = {'lc', 'cl', 'cl1', 'h', 'meshSize'};

    % --- Replace `<name> = <value>;` for each known name ----------------
    % Pattern is intentionally robust to whitespace.
    for k = 1:numel(KNOWN_LC_NAMES)
        name  = KNOWN_LC_NAMES{k};
        % Word-bounded LHS, anything up to ;
        pat   = ['(^|\n)\s*' name '\s*=\s*[^;]+;'];
        repl  = ['$1' name ' = ' num2str(lc, '%.10g') ';'];
        raw   = regexprep(raw, pat, repl);
    end

    % --- Strip any pre-existing element-order / msh-version lines -------
    raw = regexprep(raw, 'Mesh\.ElementOrder\s*=\s*[^;]+;',          '');
    raw = regexprep(raw, 'Mesh\.MshFileVersion\s*=\s*[^;]+;',        '');
    raw = regexprep(raw, 'Mesh\.SecondOrderIncomplete\s*=\s*[^;]+;', '');

    % --- Make sure `lc` itself is defined (insurance for templates ----
    %     that referenced lc only inside Point(...) calls) ---------------
    if isempty(regexp(raw, '(^|\n)\s*lc\s*=', 'once'))
        raw = sprintf('lc = %s;\n%s', num2str(lc, '%.10g'), raw);
    end

    % --- Append enforced meshing settings -------------------------------
    enforced = sprintf([ ...
        '\n\n// === injected by modifyGeoMeshSize ===\n' ...
        'Mesh.ElementOrder = 2;\n' ...
        'Mesh.SecondOrderIncomplete = 0;\n' ...
        'Mesh.MshFileVersion = 2.2;\n']);
    raw = [raw enforced];

    % --- Write out -------------------------------------------------------
    fid = fopen(outFile, 'w');
    if fid == -1
        error('modifyGeoMeshSize:Write', ...
              'Could not open output .geo for writing: %s', outFile);
    end
    fwrite(fid, raw);
    fclose(fid);
end
