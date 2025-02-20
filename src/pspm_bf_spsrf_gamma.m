function [bs, t] = pspm_bf_spsrf_gamma(varargin)
% ● Description
%   pspm_bf_spsrf_gamma constructs a gamma probability density function for
%   scanpath speed responses with a total duration of 10 seconds and a shift
%   of (SOA - 3) seconds.
% ● Format
%   [bf p] = pspm_bf_spsrf_gamma(td,soa,p)
%   [bf p] = pspm_bf_spsrf_gamma([td,soa,p])
% ● Arguments
%   *   td : time resolution in second.
%   *    p : An array of A, x0, a, and b (in order).
% ● References
%   Xia Y, Melinscak F, Bach DR (2020)
%   Saccadic Scanpath Length: An Index for Human Threat Conditioning
%   Behavioral Research Methods 53, pages 1426–1439 (2021)
%   doi: 10.3758/s13428-020-01490-5
% ● History
%   Introduced in PsPM 4.0

%% initialize
global settings
if isempty(settings), pspm_init; end;
%% check input arguments
if nargin==0
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
elseif nargin == 1
  n_el = numel(varargin{1});
  td = varargin{1}(1);
  if n_el > 1, soa = varargin{1}(2); else , soa=3.5; end;
  if n_el > 2, p = varargin{1}(3:end); else , p = NaN; end;
elseif nargin > 1
  td = varargin{1};
  soa = varargin{2};
  if nargin > 2, p = varargin{3}; else , p=NaN; end;
end;
%% Check td
if td > 10
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
end;
%% Check soa
if ~isnumeric(soa)
  warning('The SOA should be a numeric value.'); return;
elseif soa < 3
  soa = 3;
  warning('Changing SOA to 3s to avoid implausible values (<3s).');
elseif soa > 7
  warning(['SOA longer than 7s is not recommended. Use at own risk.']);
end
%% Check p
if ~isnan(p)
  p = varargin{3};
  errmsg = 'Basis function parameter must be a numeric vector with 4 elements.';
  if ~isnumeric(p) || numel(p)~=4, warning('ID:invalid_input', errmsg); return; end;
else
  % parameters obtained by fitting a gamma function to smoothed test data
  p = [-0.00953999201164847,-1.90202591900308,10.0912982464000,0.421253777432825];
end
%% Computation of bs
A  = p(1);
x0 = p(2);
a  = p(3);
b  = p(4);
start = 0;
stop  = 10;  % duration of bs 10s by default
shift = x0 + (soa - 3);
t = (start:td:stop-td)';
bs = A * gampdf(t - shift, a, b);
bs = bs/max(bs); % Normalizing by the max value
bs = bs./repmat((max(bs) - min(bs)), size(bs, 1), 1); % making it between [0,1]
return
