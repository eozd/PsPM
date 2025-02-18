function [bs, x] = pspm_bf_spsrf_box(varargin)
% ● Description
%   pspm_bf_spsrf_box constructs a boxcar function to produce the averaged
%   scanpath speed over a 2-s time window in the end of SOA. This equals
%   to scanpath length over a 2-s time window divided by 2.
% ● Format
%   [bs, x] = pspm_bf_spsrf_box(td, soa)
%   [bs, x] = pspm_bf_spsrf_box([td, soa])
% ● Arguments
%   *    td : time resolution in second.
% ● References
%   Xia Y, Melinščak F, Bach DR (2020). Saccadic scanpath length: an
%   index for human threat conditioning. Behavior Research Methods, 53,
%   1426-1439.
% ● History
%   Introduced in PsPM 4.0

%% initialize
global settings
if isempty(settings), pspm_init; end
%% check input arguments
if nargin == 0
  errmsg = 'No sampling interval stated';
  warning('ID:invalid_input', errmsg);
  return
elseif nargin == 1
  n_el = numel(varargin{1});
  td = varargin{1}(1);
  if n_el > 1, soa = varargin{1}(2); else , soa=3.5; end;
elseif nargin > 1
  td = varargin{1};
  soa = varargin{2};
end
%% create border of interval
stop = soa;
start = soa - 2;
start_idx = floor(start/td)+1;
if start_idx == 0
  start_idx = start_idx+1;
end
stop_idx = floor(stop/td);
if td > (stop-start)
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
elseif soa < 2
  soa = 2;
  stop = soa;
  start = soa-2;
  warning('Changing SOA to 2s to avoid implausible values (<2s).');
elseif soa > 8
  warning(['SOA longer than 8s is not recommended. ', ...
    'Use at own risk.']);
end;
x = (0:td:stop-td)';
bs = zeros(stop_idx,1);
bs(start_idx:stop_idx) = 1;
return
