function [bs, x] = pspm_bf_hprf_rew(td)
% ● Description
%   This function implements a canonical gamma response function for
%   reward-conditioned heart period responses, based on exps 1-2 in Xia*, 
%   Liu*, et al. (2024).
% ● Format
%   [bs, x] = pspm_bf_hprf_fc(TD)
% ● Arguments
%   *    td : time resolution in second.
% ● References:
%   GLM for reward-conditioned bradycardia:
%   Xia Y, Liu H, Kälin OK, Gerster S, Bach DR (2024). Measuring
%   human Pavlovian appetitive conditioning and memory retention.
%   Pre-print.
% ● History
%   Introduced in PsPM 7.0
%   Written in 2021 by Oliver Keats Kälin and Yanfang Xia (University of Zurich)

% initialise
global settings
if isempty(settings), pspm_init; end

% check input arguments
if nargin==0
    errmsg='No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
elseif td == 0
    warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end

% default values
duration = 30;
% k, theta, c, t0
% p_cs = [1.716239999852250e+02,0.140004209328788,60.095121886556230,-17.607312178043863]; % generated from REW1 data
p_cs = [73.9977984802746, 0.210014413426350, 71.1984486930105, -9.19655727625912]; % generated from the combined data set of REW1 and REW2

x = (0:td:duration-td)';
bs = zeros(numel(x), 1);

a = p_cs(1); % k
b = p_cs(2); % theta
A = p_cs(3); % c
t0 = p_cs(4); % t0

sta = 1+ceil(abs(t0)/td);
sto = numel(x);
x_cs = (0:td:(duration - t0))';

gl_cs = gammaln(a);
g_cs = A * (exp(log(x_cs).*(a-1) - gl_cs - (x_cs)./b - log(b)*a));

% put into bs
if t0 >= 0
    bs(sta:sto, 1) = g_cs(1:end-1);
elseif t0 < 0
    bs(1:sto, 1) = g_cs(sta:end);
end

% normalise
bs = bs/max(bs);
