function T = fillRow(T, k, res, cfg)
% =========================================================================
%  fillRow  —  Write one case result into the convergence table
% =========================================================================
    T.lc_mm(k)                = res.lc;
    T.CaseName(k)             = string(res.caseName);
    T.Nodes(k)                = res.nNodes;
    T.Elements(k)             = res.nElements;
    T.ElemsOnHole(k)          = res.nElemsOnHole;
    T.SigmaMax_MPa(k)         = res.sigma_max;
    T.SigmaAnalytical_MPa(k)  = cfg.sigma_analytical;
    T.AbsError_MPa(k)         = abs(res.sigma_max - cfg.sigma_analytical);
    T.RelError_pct(k)         = 100 * abs(res.sigma_max - cfg.sigma_analytical) ...
                                      / cfg.sigma_analytical;
    T.Runtime_sec(k)          = res.runtime_sec;
end