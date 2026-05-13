function M = computeMetrics(theta_e, sigma_e, theta_c, sigma_c, geo, mat)
% =========================================================================
%   computeMetrics
%   Extract scalar convergence metrics from boundary stress profiles.
%
% INPUTS:
%   theta_e, sigma_e : sorted (theta, sigma_thetatheta) along ellipse
%   theta_c, sigma_c : sorted (theta, sigma_thetatheta) along circular hole
%   geo              : struct with a, b, cx, cy, r
%   mat              : struct with sigma_x (applied far-field stress)
%
% OUTPUT struct M:
%   sigmaMaxEllipse, thetaMaxEllipse
%   sigmaMaxCircle,  thetaMaxCircle
%   Kt_ellipse, Kt_circle
%   Kt_analytical    -> Inglis: 1 + 2 b/a   (loading along x for plate
%                       with elliptical hole, semi-axes a along x, b along y)
%   absError         -> |Kt_ellipse - Kt_analytical|
%   relError         -> |.|/Kt_analytical * 100   (percent)
%
% USED BY:  run_convergence_study_T6.m
% =========================================================================
%
% NOTE on the analytical reference:
%   The Inglis stress concentration factor Kt = 1 + 2b/a is exact for an
%   INFINITE plate with a single elliptical hole under uniaxial tension
%   along the x-axis, where 'a' is the semi-axis ALONG the load direction
%   and 'b' is the semi-axis PERPENDICULAR to it. The maximum hoop stress
%   sits at the tip of the b-axis (theta = ±pi/2 in our parametrisation
%   x = a cos t, y = b sin t).
%
%   Your geometry is a quarter plate with an additional circular relief
%   hole, so Kt_analytical here is a REFERENCE — not a ground truth. It is
%   the right reference for showing "as we refine, Kt approaches the
%   single-hole Inglis value, modulated by the relief hole." If you have
%   a higher-fidelity benchmark (e.g. Peterson chart or a converged
%   reference run), swap it in below.
% =========================================================================

    M = struct();

    % --- Ellipse: maximum hoop stress and its location -----------------
    [M.sigmaMaxEllipse, ie] = max(sigma_e);
    M.thetaMaxEllipse       = theta_e(ie);

    % --- Circle: maximum hoop stress and its location ------------------
    [M.sigmaMaxCircle, ic] = max(sigma_c);
    M.thetaMaxCircle       = theta_c(ic);

    % --- SCFs ----------------------------------------------------------
    M.Kt_ellipse = M.sigmaMaxEllipse / mat.sigma_x;
    M.Kt_circle  = M.sigmaMaxCircle  / mat.sigma_x;

    % --- Inglis reference for the elliptical hole ----------------------
    M.Kt_analytical = 1 + 2 * geo.b / geo.a;

    % --- Errors --------------------------------------------------------
    M.absError = abs(M.Kt_ellipse - M.Kt_analytical);
    M.relError = 100 * M.absError / M.Kt_analytical;
end
