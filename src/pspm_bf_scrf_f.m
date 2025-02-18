function [ft, p, t] = pspm_bf_scrf_f(td, p)
% ● Description
%   pspm_bf_scrf_f is the canonical skin conductance response function.
%   (exponentially modified gaussian, EMG).
% ● Format
%   [bf p] = pspm_bf_scrf_f(td, p)
% ● Arguments
%   *  td : Time resolution in s.
%   *   p : An array with variables as (1) Time to peak; (2) Variance of rise defining 
%           gaussian; and (3--4) Decay constants.
% ● References
%   Bach DR, Flandin G, Friston KJ, Dolan RJ (2010). Modelling event-related skin
%   conductance responses. International Journal of Psychophysiology, 75, 349-356.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2009-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% initialise
global settings;
if isempty(settings), pspm_init; end;
%% processing
if nargin < 1
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
elseif nargin < 2
  p = [3.0745  0.7013 0.3176 0.0708];
end
if td > 90
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end
t0 = p(1);
sigma = p(2);
lambda1 = p(3);
lambda2 = p(4);
t = (0:td:90-td)';
gt = exp(-((t - t0).^2)./(2.*sigma.^2));
ht = exp(-t*lambda1) + exp(-t*lambda2);
ft = conv(gt, ht);
ft = ft(1:numel(t));
ft = ft/max(ft);
return
