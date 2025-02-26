function [fx, dfdx, dfdP] = f_SF(Xt, Theta, ut, in)
% ● Description
%   f_SF implements a biophysically informed, phenomenological forward model
%   for spontaneous fluctuations of the skin conductance.
%   output function: 
%   third order differential equation the parameters of which are estimated 
%   across trials
%   event input: 
%   gaussian bumps with 0.3 s variance, emulating sudomotor firing.
%   Note:
%   different from f_SCR, the delay in neural conductance is not explicitly 
%   modelled here but substracted afterwards
% ● Format
%   [fx, dfdx] = f_SF(Xt,Theta,ut,in)
% ● Arguments
%   * Theta: 3 general constants
%            2 value  per SF (time, log(amplitude))
%   *    ut: row 1 - time (after cue onset)
%            row 2 - number of SF
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% initialise
global settings;
if isempty(settings), pspm_init; end
% settings
Theta_n = 3;  % number of parameters for the peripheral function (the rest is for the neural function)
try
    dt = in.dt;
catch
    dt = 0.1;
end
try
    sigma = in.sigma;  % std for event-related sudomotor input function
catch
    sigma = 0.3;
end
Xt = Xt(:);
Theta = Theta(:)';
% unpack parameters
Theta = Theta(:)';
if ut(2) > 0
    for n = 1:ut(2)
        sfTheta(n, 1) = Theta((n - 1) * 2 + Theta_n + 1);
        sfTheta(n, 2) = sigma;
        sfTheta(n, 3) = exp(Theta((n - 1) * 2 + Theta_n + 2));
    end
else
    sfTheta = [];
end
% ODE 3rd order + gaussian
xdot = [Xt(2)
        Xt(3)
        - Theta(1:3) * Xt(1:3) + gu(ut(1), sfTheta, 1)];
fx = Xt + dt .* xdot;
J = [0 1 0
     0 0 1
     -Theta(1:3)];
dfdx = (dt .* J + eye(3))';
Jp = zeros(numel(Xt), numel(Theta));
Jp(3, 1:3) = -Xt;
Jp(3, 4:2:numel(Theta)) = gu(ut(1), sfTheta, 0) .* 1./(sigma.^2) .* (ut(1) - sfTheta(:, 1));
Jp(3, 5:2:numel(Theta)) = gu(ut(1), sfTheta, 0);
dfdP = dt .* Jp';
function [gu] = gu(ut, theta, f)
if ~isempty(theta)
    ut       = repmat(ut, size(theta, 1), 1);
    mu       = theta(:, 1);
    sigma    = theta(:, 2);
    a        = theta(:, 3);
    gu = a .* exp(-(ut - mu).^2 ./ (2 .* sigma.^2));
    if f
        gu = sum(gu);
    end
else
    gu = 0;
end
return;