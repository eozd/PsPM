function [bf, x, b] = pspm_bf_hprf_e(varargin)
% ● Description
%   pspm_bf_hprf_e constructs the heart period response function consisting of
%   modified Gaussian functions.
% ● Format
%   [bf, x, b] = pspm_bf_hprf_e(td, b)
%   [bf, x, b] = pspm_bf_hprf_e([td, b])
% ● Arguments
%   *       td : time resolution in second.
%   *        b : number of basis functions. Default as 1:6.
% ● Developer
%   Basis functions will be orthogonalized using spm_orth by default. Onsets
%   pspm_glm must be shifted by 5 s to account for the pre-event epoch.
%   Put in values 1:6 for b in order to get following basis functions:
%   1:  BF 1  - mu 1 s, sigma 1.9 s (contains pre event epoch of -5s)
%   2:  BF 2  - mu 5.2 s, sigma 1.9 s
%   3:  BF 3  - mu 7.2 s, sigma 1.5 s
%   4:  BF 4  - mu 7.2 s, sigma 4 s
%   5:  BF 5  - mu 12.6 s, sigma 2 s
%   6:  BF 6  - mu 18.85 s, sigma 1.8 s
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Philipp C Paulus (Technische Universitaet Dresden)
%                      Dominik R Bach (University of Zurich)

%% input checks
global settings;
if isempty(settings), pspm_init; end
if nargin < 1
  errmsg = 'No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
end
varargin = cell2mat(varargin);
if length(varargin)==1
  b=1:6;
elseif varargin(end)<=6 && varargin(end)~=0
  b=varargin(2:end);
  b=sort(b,'ascend');
else
  errmsg='your input for ''b'' is not supported. Choose value(s) between 1 and 6.';
  warning(errmsg); b=[]; bf=[]; return
end

% -------------------------------------------------------------------------
% initialise
td = varargin(1);

if td > 50
  warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
  warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
end

x = (0:td:50-td);
bf=[];


% -------------------------------------------------------------------------
% normpdf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%              ATTENTION � +ts !!                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ts=5;

n(1,:)=[1 5.2 7.2 7.2 12.6 18.85]+ts;
n(2,:)=[1.9 1.9 1.5 4 2 1.8];
% -------------------------------------------------------------------------
% get normpdf functions
for in_b=1:length(b)
  mu = n(1,b(in_b));
  sigma = n(2,b(in_b));

  % use own function (no stats toolbox needed)
  bf(:, in_b) = 1./(sigma*sqrt(2*pi)).*exp((-(x-mu).^2)./(2*(sigma^2)));
end
% shift by 5s
% -------------------------------------------------------------------------
x = x-ts;
% -------------------------------------------------------------------------
% orthogonalize
bf=spm_orth(bf);

% normalise
bf = bf./repmat((max(bf) - min(bf)), size(bf, 1), 1);

% done.
return
