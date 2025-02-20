function [bf, x] = pspm_bf_sebrf(varargin)
% ● Description
%   pspm_bf_sebrf constructs the startle eyeblink response function consisting of gamma 
%   probability functions. Basis functions will be orthogonalized using spm_orth by default.
% ● Format
%   [bf, x] = pspm_bf_sebrf(td, d, g)
%   [bf, x] = pspm_bf_sebrf([td, d, g])
% ● Arguments
%   *    td : Time resolution in s.
%   *     d : Whether first derivative should be included (1) or not (0). Default as 0.
%   *     g : Whether gaussian to model the tail should be included (1) or not (0). Default as 0.
% ● References
%   Khemka S, Tzovara A, Gerster S, Quednow B and Bach DR (2016)
%   Modeling Startle Eyeblink Electromyogram to Assess Fear Learning.
%   Psychophysiology. 2017 Feb; 54(2): 204–214.
%   doi: 10.1111/psyp.12775
% ● History
%   Introduced in PsPM 3.1
%   Written in 2015 by Tobias Moser (University of Zurich)

%% input checks
global settings;
if isempty(settings), pspm_init; end
varargin = cell2mat(varargin);
if length(varargin) >= 1
  td = varargin(1);
else
  warning('ID:invalid_input', 'No sampling interval stated.');
  return
end
if length(varargin) >= 2
  d = varargin(2);
  if ~islogical(d) && ~isnumeric(d)
    warning('ID:invalid_input', 'Parameter ''d'' needs to be logical.');
    return
  end
else
  d = 0;
end
if length(varargin) >= 3
  g = varargin(3);
  if ~islogical(g) && ~isnumeric(g)
    warning('ID:invalid_input', 'Parameter ''g'' needs to be logical.');
    return
  end
else
  g = 0;
end
%% initialise
td = varargin(1);
if td > 1
  warning('ID:invalid_input', ...
  'Time resolution is larger than duration of the function.');
  return
elseif td == 0
  warning('ID:invalid_input', ...
  'Time resolution must be larger than 0.');
  return
end
x = (0:td:1-td);
bf=zeros(length(x), 1 + g + d);
%% create gampdf
A = 1;
k = 3.5114;
Theta = 0.0108;
x0 = 0.0345;
bf(:, 1) = A*gampdf(x-x0,k, Theta);
if d
  bf(:, 1+d) = [0; diff(bf(:, 1))];
end
sigma = 0.1854;
mu = 0.2119;
if g
  bf(:, 1+d+g) = normpdf(x, mu, sigma);
end
%% orthogonalize
bf = spm_orth(bf);
% normalise
bf = bf./repmat((max(bf) - min(bf)), size(bf, 1), 1);
return
