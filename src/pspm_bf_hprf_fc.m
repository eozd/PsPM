function [bs, x] = pspm_bf_hprf_fc(varargin)
% ● Description
%   pspm_bf_hprf_fc is a basis function.
% ● Format
%   [bs, x] = pspm_bf_hprf_fc(TD, D, soa)
%   [bs, x] = pspm_bf_hprf_fc([TD, D, soa])
% ● Arguments
%   *    td : time resolution in second.
%   *     d : number of derivatives. Default is 1.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

% initialise
global settings
if isempty(settings), pspm_init; end
% check input arguments
if nargin==0
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
end
td = varargin{1}(1);
if numel(varargin{1}) == 1 && nargin == 1
  d = 1;
  soa = 3.5;
else
  if numel(varargin) > 1
    va = [varargin{:}];
  elseif numel(varargin{1}) > 1
    va = varargin{1};
  end
  if numel(va) > 1
    d = va(2);
  else
    d = 1;
  end
  if numel(va) > 2
    soa = va(3);
  else
    soa = 3.5;
  end
end
if td > (10 + abs(soa))
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end
if (d<0)||(d>1), d=0; end
% get parameters and basis function
[bs(:, 1), x, ~] = pspm_bf_hprf_fc_f(td, soa);
if d>0
  bs(:, 2) = [0; diff(bs(:,1))];
  bs(:, 2) = bs(:,2)/sum(abs(bs(:,2)));
end
% orthogonalise
bs = spm_orth(bs);
% normalise
bs = bs./repmat((max(bs) - min(bs)), size(bs, 1), 1);
return
