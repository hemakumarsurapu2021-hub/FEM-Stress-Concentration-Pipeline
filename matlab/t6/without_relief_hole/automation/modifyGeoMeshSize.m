function modifyGeoMeshSize(templateFile, outputFile, lc)
% =========================================================================
%  modifyGeoMeshSize  —  Edit lc value in a Gmsh .geo file
% =========================================================================
%  Reads the template, replaces the line  "lc = <value>;"  with the new lc,
%  and writes the result to outputFile (does NOT overwrite the template).
%
%  The regex matches:  lc = <number>;
%  with optional whitespace around '=' and before ';'.
%  It also updates the adaptive field ratios that reference lc/10 etc.
%  because those are text expressions in the .geo file — Gmsh evaluates
%  them at mesh time, so changing lc is sufficient.
% =========================================================================

    % Read template
    fid = fopen(templateFile, 'r');
    if fid == -1
        error('Cannot open template .geo file: %s', templateFile);
    end
    content = fread(fid, '*char')';
    fclose(fid);

    % Replace   lc = <old_value>;
    % Handles integer or float values, optional spaces
    newLine  = sprintf('lc = %g;', lc);
    content  = regexprep(content, 'lc\s*=\s*[0-9.]+\s*;', newLine, 'once');

    % Write to output file
    fid = fopen(outputFile, 'w');
    if fid == -1
        error('Cannot write .geo file: %s', outputFile);
    end
    fprintf(fid, '%s', content);
    fclose(fid);
end
