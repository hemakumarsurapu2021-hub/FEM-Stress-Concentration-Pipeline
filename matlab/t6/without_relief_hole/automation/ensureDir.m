function ensureDir(d)
% =========================================================================
%  ensureDir  —  Create directory if it does not exist (recursive)
% =========================================================================
    if ~exist(d, 'dir')
        mkdir(d);
    end
end
