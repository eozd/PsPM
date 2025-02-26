function [fx, x, p] = pspm_bf_hprf_fc_f(td, soa, p)
% ● Description
%   pspm_bf_hprf_fc_f is the basis function for heart period response function.
% ● Format
%   [bf p] = pspm_bf_hprf_fc_f(td, soa, p)
% ● Arguments
%   *   td : time resolution in second.
%   *    p : an array with variables (in order) a, b, x0, and A.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Tobias Moser (University of Zurich)

%% initialise
global settings;
if isempty(settings), pspm_init; end
if nargin < 1
  errmsg = 'No sampling interval stated'; warning('ID:invalid_input',errmsg); return;
end
if nargin < 2
  soa = 3.5;
end
if nargin < 3
  % table 2 row 3 in Castegnetti et al. 2016
  %p=[43.2180170215633,0.195621916215104,-6.9671,81.0383536117737];
  % table 2 row 4 in Castegnetti et al. 2016
  % col 3: -3.86 - 3.5 = -7.3600
  p = [48.5, 0.182, -7.3600, 1];
  % col 4 is different to the published parameter because here
  % soa will be added later in the code therefore soa is subtracted
  % before
  % amplitude does not matter because it will be downscaled to 1 by the
  % calling function
end
x0 = p(3);
b = p(2);
a = p(1);
A = p(4);
d = 10;
start = 0;
stop = d + soa;
if td > (stop-start)
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
elseif soa < 2
  soa = 2;
  stop = d + soa;
  warning('Changing SOA to 2s to avoid implausible values (<2s).');
elseif soa > 8
  warning(['SOA longer than 8s is not recommended. ', ...
    'Use at own risk.']);
end
shift = soa + x0;
x = (start:td:stop-td)';
% try not to use stats toolbox, but stats toolbox has very good
% approximations
fx = A * gampdf(x - shift, a, b);
%fx = A * exp(log(x-shift).*(a-1) - gl - (x-shift)./b - log(b)*a);
return
