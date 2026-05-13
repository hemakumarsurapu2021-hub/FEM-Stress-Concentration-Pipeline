function validateConfig(cfg)
% =========================================================================
%  validateConfig  —  Basic sanity checks on the config struct
% =========================================================================

    assert(~isempty(cfg.meshSizes) && isnumeric(cfg.meshSizes) && all(cfg.meshSizes > 0), ...
        'cfg.meshSizes must be a non-empty vector of positive numbers.');

    if ~isfile(cfg.geoTemplate)
        error(['Template .geo file not found: %s\n' ...
               'Make sure the file is in the MATLAB working directory.'], ...
               cfg.geoTemplate);
    end

    assert(cfg.E > 0,  'Young''s modulus E must be positive.');
    assert(cfg.nu > 0 && cfg.nu < 0.5, 'Poisson''s ratio nu must be in (0, 0.5).');
    assert(cfg.t > 0,  'Thickness t must be positive.');
    assert(cfg.sigma_x ~= 0, 'Applied stress sigma_x cannot be zero.');

    % Check Gmsh is callable (do a quick version query, fail gracefully)
    [status, ~] = system(sprintf('"%s" --version 2>&1', cfg.gmshPath));
    if status ~= 0
        warning(['Gmsh not found at: %s\n' ...
                 'Update cfg.gmshPath in run_convergence_study.m before running.\n' ...
                 'Windows default: ''C:/Program Files/Gmsh/gmsh.exe''\n' ...
                 'macOS   default: ''/Applications/Gmsh.app/Contents/MacOS/gmsh''\n' ...
                 'Linux   default: ''gmsh'' (if on PATH)'], cfg.gmshPath);
    end
end