function M = extractMetrics(theta_e, sigma_e, theta_c, sigma_c, ...
                              deltaSigmaMax, mat, ref)
% =========================================================================
%   extractMetrics
%   Extract scalar convergence metrics from boundary stress profiles.
%
% INPUTS:
%   theta_e, sigma_e : sorted (theta, sigma_thetatheta) along ellipse
%   theta_c, sigma_c : sorted (theta, sigma_thetatheta) along circular hole
%   deltaSigmaMax    : max principal stress difference Δσ over the domain
%   mat              : struct with sigma_x (applied far-field stress)
%   ref              : struct with sigmaMaxEllipse (analytical = 46 MPa)
%
% OUTPUT struct M:
%   sigmaMaxEllipse, thetaMaxEllipse
%   sigmaMaxCircle,  thetaMaxCircle
%   Kt_ellipse, Kt_circle
%   ratioCircleToEllipse  -> max σθθ_circle / max σθθ_ellipse
%                            (relief-hole effectiveness indicator)
%   deltaSigmaMax         -> passed through
%   absError, relError    -> against ref.sigmaMaxEllipse (= 46 MPa)
%
% USED BY: run_convergence_study.m
% =========================================================================
%
% The relief-hole ratio:
%   A circular relief hole near a high-stress ellipse "borrows" some of
%   the load path. The closer the ratio is to 1, the more the relief hole
%   is itself becoming a critical site. A small ratio (≪ 1) means the
%   ellipse still dominates as the SCF location.  Useful for design
%   sensitivity discussion in the report.
% =========================================================================

    M = struct();

    % --- Ellipse ------------------------------------------------------
    [M.sigmaMaxEllipse, ie] = max(sigma_e);
    M.thetaMaxEllipse       = theta_e(ie);

    % --- Circle -------------------------------------------------------
    [M.sigmaMaxCircle, ic] = max(sigma_c);
    M.thetaMaxCircle       = theta_c(ic);

    % --- SCFs ---------------------------------------------------------
    M.Kt_ellipse = M.sigmaMaxEllipse / mat.sigma_x;
    M.Kt_circle  = M.sigmaMaxCircle  / mat.sigma_x;

    % --- Relief-hole effectiveness ratio -----------------------------
    if M.sigmaMaxEllipse > 0
        M.ratioCircleToEllipse = M.sigmaMaxCircle / M.sigmaMaxEllipse;
    else
        M.ratioCircleToEllipse = NaN;
    end

    % --- Δσ pass-through ---------------------------------------------
    M.deltaSigmaMax = deltaSigmaMax;

    % --- Error vs analytical reference (46 MPa on ellipse) -----------
    M.absError = abs(M.sigmaMaxEllipse - ref.sigmaMaxEllipse);
    M.relError = 100 * M.absError / ref.sigmaMaxEllipse;
end
