function T = initResultsTable(nCases)
% =========================================================================
%  initResultsTable  —  Pre-allocate the results summary table
% =========================================================================
    T = table( ...
        nan(nCases,1), ...          % lc
        repmat("",nCases,1), ...    % caseName
        nan(nCases,1), ...          % nNodes
        nan(nCases,1), ...          % nElements
        nan(nCases,1), ...          % nElemsOnHole
        nan(nCases,1), ...          % sigma_max
        nan(nCases,1), ...          % sigma_analytical
        nan(nCases,1), ...          % error_abs
        nan(nCases,1), ...          % error_pct
        nan(nCases,1), ...          % runtime
        'VariableNames', { ...
            'lc_mm', 'CaseName', ...
            'Nodes', 'Elements', 'ElemsOnHole', ...
            'SigmaMax_MPa', 'SigmaAnalytical_MPa', ...
            'AbsError_MPa', 'RelError_pct', 'Runtime_sec' ...
        });
end
