function [FIR, x] = pspm_bf_FIR(varargin)
% ● Description
%   pspm_bf_FIR provides a pre-defined finite impulse response (FIR) model for
%   skin conductance responses with n (default 30) post-stimulus timebins of 1
%   second each.
% ● Format
%   [FIR, x] = pspm_bf_FIR(TD, N, D)
%   [FIR, x] = pspm_bf_FIR([TD, N, D])
% ● Arguments
%   *     TD : sampling interval in seconds.
%   *      N : number of timepoints. Default as 30 s.
%   *      D : duration of bin in seconds. Default as 1 s.
% ● History
%   Introduced in PsPM 3.0
%   Written    in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% Check input arguments
if nargin==0
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
end
n = 30;
d = 1;
td = varargin{1}(1);
if nargin == 1 && numel(varargin{1}) > 1
  n = varargin{1}(2);
  if numel(varargin{1}) >= 3
    d = varargin{1}(3);
  end

elseif nargin > 1
  if nargin >= 2
    n = varargin{2}(1);
  end
  if nargin >= 3
    d = varargin{3}(1);
  end
end
if td > d
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end
% initialise FIR
FIR = [zeros(1, n); zeros(round((d*n/td)), n);];
% generate timestamps
x = (0:td:d-td)';
%% set FIR columns
starts=1;
for reg=1:n
  stops=(d*reg)/td;
  FIR(starts:stops, reg)=1;
  starts=stops+1;
end
return
