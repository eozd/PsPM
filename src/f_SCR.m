function [fx, dfdx, dfdP] = f_SCR(Xt, Theta, ut, in)
% ● Description
%   f_SCR implements a phenomenological forward model for anticipatory and
%   event-related skin conductance responses, taking into account spontaneous
%   fluctuations [SF] in the absence of experimental input, and slow baseline
%   [SCL] changes between experimental inputs that might not be completely
%   removed by filtering.
%   output function:
%   third order differential equation the parameters of which are estimated
%   across trials, plus derivatives wrt time and parameters.
%   event input:
%   gaussian bumps with 0.3 s variance, emulating sudomotor firing
%   sustained input:
%   modeled by gaussian bumps with variable variance
%   spontaneous input:
%   in inter-trial intervals > 7 s, SF are assumed with a
%   frequency of 0.5 Hz and a function analogous to f_SF
% ● Format
%   [fx, dfdx, dfdP] = f_SCR(Xt,Theta,ut,in)
% ● Arguments
% * Theta:  4 ER constants (3 ODE params + time)
%           3 SF constants (3 ODE params)
%           3 values per aSCR (invsigma(peaktime), invsigma(std),
%           log(amplitude))
%           1 value  per eSCR (log(amplitude))
%           2 values per SF (invsigma(peaktime), log(amplitude))
%           2 values per SCL change (invsigma(time), amplitude)
% *    ut:  row 1 - time (after cue onset)
%           row 2 - number of aSCR
%           row 3 - number of eSCR
%           row 4 - number of SF
%           row 5 - number of SCL changes
%           row 6 - ...: event onsets for aSCR
%           row ... - ...: upper bounds for each aSCR.m
%           row ... - ...: upper bounds for each aSCR.s
%           row ... - ...: event onsets for eSCR
%           row ... - ...: lower bound for SF
%           row ... - ...: upper bound for SF
%           row ... - ...: lower bound for SCL
%           row ... - ...: upper bound for SCL
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%                           Jean Daunizeau (Wellcome Trust Centre for Neuroimaging)

%% Initialise settings
global settings
if isempty(settings)
    pspm_init;
end
sts = -1;
sigma = 0.3;  % std for event-related and spontaneous sudomotor input function
sigma_SCL = 1;% std for SCL changes
sigma_offset = settings.dcm{1}.sigma_offset; %  offset for aSCR sigma to constrain the amplitude/sd trade-off
Theta_n = 7;  % number of parameters for the output function (the rest is for the input function)

try
    dt = in.dt;
catch
    dt = 1;
end

% unpack parameters
% ------------------------------------------------------------------------
Xt = Xt(:);
Theta = Theta(:)';

% ODE SCR parameters & eSCR delay
Theta(1:4) = exp(Theta(1:4));

% - anticipatory responses
if ut(2) > 0
    % - unpack ut
    aSCR_o = 5 + (1:ut(2));             % aSCR onsets
    aSCR_m = aSCR_o(end) + (1:ut(2));   % aSCR mean upper bound
    aSCR_s = aSCR_m(end) + (1:ut(2));   % aSCR sigma upper bound
    % - unpack Theta
    aTheta = Theta(Theta_n + (1:(3 * ut(2))))';
    aTheta = reshape(aTheta, [3, ut(2)])';
    % - set sigmoid function defaults
    dmdx = NaN(ut(2), 1);
    dsdx = NaN(ut(2), 1);
    sig.beta = 0.5;
    for k = 1:ut(2)
        sig.G0 = ut(aSCR_m(k));
        [m, dmdx(k)]  = sigm(aTheta(k, 1), sig);
        aTheta(k, 1) = ut(aSCR_o(k)) + m + Theta(4);  % onset plus mean plus physical delay (from eSCR)
        sig.G0 = ut(aSCR_s(k));
        [s, dsdx(k)]  = sigm(aTheta(k, 2), sig);
        aTheta(k, 2) = s + sigma_offset;
        aTheta(k, 3) = exp(aTheta(k, 3));
    end;
    if any(isinf(aTheta(:, 3)))
        aTheta(isinf(aTheta(:, 3)), 3) = 1e200; % an arbitrary value way below realmax
    end;
    clear sig m s
else
    aTheta = [];
    aSCR_s = 5;
end;

% - event-related responses
if ut(3) > 0
    % - unpack ut
    eSCR_o = aSCR_s(end) + (1:ut(3));   % eSCR onsets
    % - unpack Theta
    eTheta(:, 1) = ut(eSCR_o) + Theta(4);
    eTheta(:, 2) = sigma;
    eTheta(:, 3) = exp(Theta((Theta_n + 3 * ut(2)) + (1:ut(3))));
    if any(isinf(eTheta(:, 3)))
        eTheta(isinf(eTheta(:, 3)), 3) = 1e200;
    end;
else
    eTheta = [];
    eSCR_o = aSCR_s(end);
end;

% - spontaneous fluctuations
if ut(4) > 0
    SF_lb = eSCR_o(end) + (1:ut(4)); % SF lower bound
    SF_ub = SF_lb(end) + (1:ut(4));  % SF upper bound
    dtdx = NaN(ut(4), 1);
    sig.beta = 0.5;
    for k = 1:ut(4)
        sig.G0 = ut(SF_ub(k)) - ut(SF_lb(k));
        [t, dtdx(k)] = sigm(Theta(Theta_n + 3 * ut(2) + ut(3) + (k - 1) * 2 + 1), sig);
        sfTheta(k, 1) = ut(SF_lb(k)) + t; % lower bound plus parameter vaue
    end;
    sfTheta(:, 2) = sigma;
    sfTheta(:, 3) = exp(Theta((Theta_n + 3 * ut(2) + ut(3)) + (2:2:(2 * ut(4)))));
else
    sfTheta = [];
    SF_ub = eSCR_o;
end;

% - SCL changes
if ut(5) > 0
    SCL_lb = SF_ub(end) + (1:(ut(5)));
    SCL_ub = SCL_lb(end) + (1:(ut(5)));
    dtscldx = NaN(ut(5), 1);
    sig.beta = 0.5;
    for k = 1:ut(5)
        sig.G0 = ut(SCL_ub(k)) - ut(SCL_lb(k));
        [t, dtscldx(k)] = sigm(Theta(Theta_n + 3 * ut(2) + ut(3) + 2 * ut(4) + (k - 1) * 2 + 1), sig);
        SCLtheta(k, 1) = ut(SCL_lb(k)) + t; % lower bound plus parameter vaue
    end;
    SCLtheta(:, 2) = sigma_SCL;
    SCLtheta(:, 3) = Theta((Theta_n + 3 * ut(2) + ut(3)) + 2 * ut(4)  + (2:2:(2 * ut(5))));
else
    SCLtheta = [];
end;

% ODE
% ------------------------------------------------------------------------
% 3 states for ER, 3 states for SF, 1 state for SCL
% The ODEs for ER, SF & SCL are combined in g_aSCR
xdot = [Xt(2)
        Xt(3)
        -Theta(1:3) * Xt(1:3) + gu(ut(1), [eTheta; aTheta], 1)
        Xt(5)
        Xt(6)
        -Theta(5:7) * Xt(4:6) + gu(ut(1), sfTheta, 1)
        gu(ut(1), SCLtheta, 1)];


% compute fx
fx = Xt + dt .* xdot;


% compute dfdx
% ------------------------------------------------------------------------
J = [0 1 0       0 0 0      0
     0 0 1       0 0 0      0
     -Theta(1:3) 0 0 0      0
     0 0 0       0 1 0      0
     0 0 0       0 0 1      0
     0 0 0      -Theta(5:7) 0
     0 0 0       0 0 0      0];

dfdx = (dt .* J + eye(7))';

% compute dfdP
% ------------------------------------------------------------------------
Jp = zeros(numel(Xt), numel(Theta));
Jp(3, 1:3) = -Xt(1:3) .* Theta(1:3)';
Jp(6, 5:7) = -Xt(4:6);


 if ~isempty(aTheta)
     Jp(3, 7 + (1:3:(3 * ut(2))))  = gu(ut(1), aTheta, 0) .* (ut(1) - aTheta(:, 1))    .* (aTheta(:, 2)).^-2 .* dmdx;
     Jp(3, 7 + (2:3:(3 * ut(2))))  = gu(ut(1), aTheta, 0) .* (ut(1) - aTheta(:, 1)).^2 .* (aTheta(:, 2)).^-3 .* dsdx;
     Jp(3, 7 + (3:3:(3 * ut(2))))  = gu(ut(1), aTheta, 0);
 end;

if ~isempty(eTheta)
    Jp(3, (7 + 3 * ut(2)) + (1:ut(3)))  = gu(ut(1), eTheta, 0);
end;

if ~(isempty(eTheta) && isempty(aTheta))
    allTheta = [eTheta; aTheta];
    Jp(3, 4) = sum(gu(ut(1), allTheta, 0) .* 1./(allTheta(:, 2).^2) .* (ut(1) - allTheta(:, 1)) .* exp(Theta(4)));
end;

if ~isempty(sfTheta)
    Jp(6, (7 + 3 * ut(2) + ut(3)) + (1:2:(2 * ut(4)))) = gu(ut(1), sfTheta, 0) .* (ut(1) - sfTheta(:, 1)) .* sfTheta(:, 2).^-2 .* dtdx;
    Jp(6, (7 + 3 * ut(2) + ut(3)) + (2:2:(2 * ut(4)))) = gu(ut(1), sfTheta, 0);
end;

if ~isempty(SCLtheta)
    Jp(7, (7 + 3 * ut(2) + ut(3)) + 2 * ut(4) + (1:2:(2 * ut(5)))) = gu(ut(1), SCLtheta, 0) .* 1./(sigma_SCL.^2) .* (ut(1) - SCLtheta(:, 1)) .* dtscldx;
    SCLtheta(:, 3) = 1; % we don't take the exp(amp) here, so dSCLdamp = gu for unit amplitude
    Jp(7, (7 + 3 * ut(2) + ut(3)) + 2 * ut(4) + (2:2:(2 * ut(5)))) = gu(ut(1), SCLtheta, 0);
end;

dfdP = dt .* Jp';

if any(isweird(fx(:))), error('Weird values in f_SCR'); end;
if any(isweird(dfdx(:))), error('Weird values in f_SCR'); end;
if any(isweird(dfdP(:))), error('Weird values in f_SCR'); end;


return;

% =========================================================================


% subfunction gaussian pdf
% ------------------------------------------------------------------------
% f = 1: sum up for use as input
% f = 0: don't sum up for use in derivatives
function [gu] = gu(ut, theta, f)
if ~isempty(theta)
    ut       = repmat(ut, size(theta, 1), 1);
    mu       = theta(:, 1);
    sigma    = theta(:, 2);
    a        = theta(:, 3);
    gu = a .* exp(-(ut - mu).^2 ./ (2 .* sigma.^2));
    if f
        gu = sum(gu);
    end;
else
    gu = 0;
end;
return;

% =========================================================================

