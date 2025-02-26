function [bs, x] = pspm_bf_ldrf_gu(varargin)
% ● Description
%   pspm_bf_ldrf_gu is the Gaussian response function for pupil dilation.
%   Pupil size models were developed with pupil size data recorded in
%   diameter values. Therefore pupil size data analyzed using these models
%   should also be in diameter.
% ● Format
%   [bs, x]  = pspm_bf_ldrf_gu(td, n, offset, p1, p2, p3, p4)
%   [bs, x]  = pspm_bf_ldrf_gu([td, n, offset, p1, p2, p3, p4])
% ● Arguments
%   *     td : Time resolution in second.
%   *      n : Duration of the function in second. Default as 20 s.
%   * offset : Offset in s. tells the function where to start with the response function.
%              Default as 0.2 s.
%   *     p1 : Shape for Gaussian response function, or a, default as 0.27.
%   *     p2 : Scale for Gaussian response function, or b, default as 2.04.
%   *     p3 : Parameter for Gaussian response function, or x0, default as 1.48.
%   *     p4 : Quantifier or amplitude for Gaussian response function, or A, default as 0.004.
% ● References
%   Korn, C. W., & Bach, D. R. (2016). A solid frame for the window on
%   cognition: Modeling event-related pupil responses. Journal of Vision,
%   16(3), 28. https://doi.org/10.1167/16.3.28
% ● History
%   Introduced in PsPM 3.1
%   Written    in 2015 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings), pspm_init; end
%% set defaults
p = [0.27, 2.04, 1.48, 0.004]; % p = [sigma lambda1 lambda2 a]
n = 20;
offset = 0.2;
%% check input arguments
if nargin == 0
  errmsg = 'No sampling interval stated';
  warning('ID:invalid_input', errmsg);
  return;
elseif nargin == 1
  n_el = numel(varargin{1});
  td = varargin{1}(1);
  if n_el > 1, n = varargin{1}(2); end
  if n_el > 2, offset = varargin{1}(3); end
  if n_el > 3, p(1) = varargin{1}(4); end
  if n_el > 4, p(2) = varargin{1}(5); end
  if n_el > 5, p(3) = varargin{1}(6); end
  if n_el > 6, p(4) = varargin{1}(7); end
elseif nargin > 1
  td = varargin{1};
  n = varargin{2};
  if nargin > 2, offset = varargin{3}; end
  if nargin > 3, p(1) = varargin{4}; end
  if nargin > 4, p(2) = varargin{5}; end
  if nargin > 5, p(3) = varargin{6}; end
  if nargin > 5, p(4) = varargin{7}; end
end
if td > n
  warning('ID:invalid_input', 'Time resolution is larger than or equal to the duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
elseif offset < 0
  warning('ID:invalid_input', 'Offset has to be a positive number.'); return;
elseif n <= 0
  warning('ID:invalid_input', 'Duration has to be a number larger then 0.'); return;
end
%% check if offset is in a valid range or correct it if it is to small
if offset ~= 0
  r = td/offset;
  if r > 1
    % td is bigger than offset -> offset is too small
    if r > 2
      offset = 0;
    elseif r <= 2
      offset = td;
    end
  end
end
%% create x axis
bf_dur = n;
n_bf = round((bf_dur)/td);
bs = zeros(1, n_bf);
x2 = linspace(offset+td,bf_dur,round((bf_dur-offset)/td));
x1 = linspace(0,offset,offset/td);
x = [x1, x2];
%% apply gaussian: estimates for smoothed gaussian
sg_gt = exp(-((x2).^2)./(2.*p(1).^2));
sg_ht = exp(-x2*p(2)) + exp (-x2*p(3));
sg_ft = conv(sg_gt, sg_ht);
bs(round(offset/td + 1):end) = p(4) * sg_ft(1:numel(x2));
return
