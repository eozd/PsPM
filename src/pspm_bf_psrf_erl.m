function [bs, x] = pspm_bf_psrf_erl(varargin)
% ● Description
%   pspm_bf_psrf_erl is the erlang response function to pupil size changes.
% ● Format
%   [bs, x] = pspm_bf_psrf_erl(TD, n, tmax)
%   [bs, x] = pspm_bf_psrf_erl([TD, n, tmax])
% ● Arguments
%   *    td : Time resolution.
%   *     n : Number of layers / boxes.
%   *  tmax : t of the maximum amplitude in seconds.
% ● References
%   Hoeks, B., & Levelt, W.J.M. (1993).
%   Pupillary Dilation as a Measure of Attention - a Quantitative System-Analysis.
%   Behavior Research Methods Instruments & Computers, 25, 16-26.
% ● History
%   Introduced in PsPM 3.1
%   Written    in 2018 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings), pspm_init; end
%% check input arguments
if nargin==0
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg);
  return;
end
%% default values
duration = 20;
n = 10.1;
tmax = 0.93;
%% set parameters
td = varargin{1}(1);
if nargin > 1
  if nargin > 2
    tmax = varargin{3};
  end
  n = varargin{2};
elseif numel(varargin{1}) > 1
  narg = numel(varargin{1});

  if narg > 2
    tmax = varargin{1}(3);
  end
  n = varargin{1}(2);
end
if td > duration
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end
x = (0:td:duration-td)';
bs = zeros(numel(x), 1);
bs(:,1) = x.^n.*exp(-n.*x/tmax);
% orthogonalise
bs(:,1) = spm_orth(bs(:,1));
% normalise
bs = bs./repmat((max(bs) - min(bs)), size(bs, 1), 1);
return
