function [bs, x] = pspm_bf_scrf(varargin)
% ● Description
%   pspm_bf_scrf constructs an informed basis set with a biexponentially
%   modified gaussian function and derivatives to time and dispersion.
% ● Format
%   [bs, x] = pspm_bf_scrf(TD, D)
%   [bs, x] = pspm_bf_scrf([TD, D])
% ● Arguments
%   *    td : Time resolution in second.
%   *     d : Number of derivatives. Default as 0.
% ● References
%   Bach DR, Flandin G, Friston KJ, Dolan RJ (2010). Modelling event-related
%   skin conductance responses. International Journal of Psychophysiology,
%   75, 349-356.
% ● History
%   Introduced in PsPM 3.0
%   Written    in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings), pspm_init; end;
%% check input arguments
if nargin==0
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
end;
td = varargin{1}(1);
if numel(varargin{1}) == 1 && nargin == 1
  d = 0;
elseif numel(varargin{1}) == 2
  d = varargin{1}(2);
else
  d = varargin{2}(1);
end;
if td > 90
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end;
if (d<0)||(d>2), d=0; end;
%% get parameters and basis function
[bs(:, 1), p, x] = pspm_bf_scrf_f(td);
if d>0
  bs(:, 2) = [0; diff(bs(:,1))];
  bs(:, 2) = bs(:,2)/sum(abs(bs(:,2)));
end;
if d>1
  p(2) = 1.8 * p(2);
  bs(:, 3) = bs(:, 1) - pspm_bf_scrf_f(td, p);
  bs(:, 3) = bs(:, 3)/sum(abs(bs(:, 3)));
end;
% orthogonalize
bs=spm_orth(bs);
% normalise
bs = bs./repmat((max(bs) - min(bs)), size(bs, 1), 1);
return
