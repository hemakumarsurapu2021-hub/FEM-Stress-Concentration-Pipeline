function ensureDir(d)
% =========================================================================
%   ensureDir
%   Creates a directory if it does not already exist.  Idempotent.
%
% USED BY: run_convergence_study.m, runOneCase
% =========================================================================
    if ~exist(d, 'dir')
        mkdir(d);
    end
end
