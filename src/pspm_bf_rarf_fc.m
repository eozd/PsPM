function [bs, x] = pspm_bf_rarf_fc(varargin)
% ● Description
%   pspm_bf_rarf_fc is a basis function.
% ● Format
%   [bs, x] = pspm_bf_rarf_fc(td, bf_type)
%   [bs, x] = pspm_bf_rarf_fc([td, bf_type])
% ● Arguments
%   *      td:  The time the response function should have.
%   * bf_type:  Which type of response function should be generated. Can be either 1 or 2.
%               If 1, first type response function is generated (default)                     : gamma_early + gamma_late.
%               If 2, second type response function is generated (recommended for longer SOAs): gamma_early + gamma_early'.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by G Castegnetti, Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings), pspm_init; end
%% check input arguments
if nargin==0
  errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
end
td = varargin{1}(1);
if numel(varargin{1}) == 1 && nargin == 1
  bf_type = 1;
elseif numel(varargin{1}) == 2
  bf_type = varargin{1}(2);
else
  bf_type = varargin{2}(1);
end
if td > 30
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end
%% define paramters
% order: k, G, n0
% can use any amplitude, since glm resizes them
amp = 1;
p_early = [25701021.9751273, 0.000312409767612504, -8024.33886550365, amp];
p_late = [3.41301736200870 1.10734203371767 7.58288130400132 amp];
%% fix value of bf_type
if (bf_type<1)||(bf_type>2)
  bf_type = 1;
end
x = (0:td:30-td)';
x0_e = p_early(3);
b_e = p_early(2);
a_e = p_early(1);
A_e = p_early(4);
x0_l = p_late(3);
b_l = p_late(2);
a_l = p_late(1);
A_l = p_late(4);
g_early = A_e * gampdf(x-x0_e, a_e, b_e);
g_late = A_l * gampdf(x-x0_l, a_l, b_l);
g_early = g_early/max(g_early);
g_late = g_late/max(g_late);
if bf_type == 1
  bs = [g_early g_late];
else
  bs = [g_early(1:end-1) diff(g_early)];
end
% orthogonalise
bs = spm_orth(bs);
% normalise
bs = bs./repmat((max(bs) - min(bs)), size(bs, 1), 1);
return
