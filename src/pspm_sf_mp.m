function [sts, out] = pspm_sf_mp(model, options)
% ● Description
%   pspm_sf_mp does the inversion of a DCM for SF of the skin conductance, using a
%   matching pursuit algorithm, and f_SF for the forward model the input data is assumed
%   to be in mcS, and sampling rate in Hz.
% ● Format
%   [sts, out] = pspm_sf_mp(model, options)
% ● Arguments
%   ┌─model
%   ├─────scr : skin conductance epoch (maximum size depends on computing power, a
%   │           sensible size is 60 s at 10 Hz)
%   └──────sr : sampling rate in Hz
%   ┌─options
%   ├─.threshold: threshold for SN detection (default 0.1 mcS)
%   ├──.theta : a (1 x 5) vector of theta values for f_SF (default: read from pspm_sf_theta)
%   ├──.fresp : maximum frequency of modelled responses (default 0.5 Hz).
%   ├.dispwin : display result window (default 1).
%   └.diagnostics:
%               Add further diagnostics to the output. Is disabled if set to be false.
%               If set to true this will add a further field 'D' to the output struct.
%               Default is false.
% ● Output
%   ┌─────out
%   ├──────.n : number of responses above threshold
%   ├──────.f : frequency of responses above threshold in Hz
%   ├─────.ma : mean amplitude of responses above threshold
%   ├──────.t : timing of responses (adjusted for conduction delay)
%   ├──────.a : amplitude of responses (re-estimated via ML)
%   ├───.rawa : amplitude of responses (initial greedy estimate)
%   ├──.theta : parameters used for f_SF
%   ├─.threshold : threshold applied for response detection
%   ├───.yhat : fitted time series (using reestimated amplitudes)
%   ├.yhatraw : fitted time series (using initial amplitudes)
%   ├──────.ind : indices of selected dictionary atoms in D.D
%   ├──.sortind : sorted indices of selected atoms (after pruning)
%   ├───────.y : preprocessed input data (baseline-centered scr)
%   ├───.time : total execution time in seconds
%   ├──────.S : inversion settings (struct with algorithm parameters)
%   └──────.D : inversion dictionary (struct with atoms and metadata)
% ● References
%   [1] Bach DR, Staib M (2015). A matching pursuit algorithm for inferring tonic
%       sympathetic arousal from spontaneous skin conductance fluctuations.
%       Psychophysiology, 52, 1106-12.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (UZH, WTCN) last edited 18.08.2014
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
tstart = tic;
out = [];

try model.scr; catch, warning('Input data is not defined.'); return; end
try model.sr; catch, warning('Sample rate is not defined.'); return; end
scr = model.scr;
sr = model.sr;

% check input arguments
% ------------------------------------------------------------------------
if ~isnumeric(sr) || numel(sr) > 1
  errmsg = sprintf('No valid sample rate given.');
elseif (sr < 1) || (sr > 1e5)
  errmsg = sprintf('Sample rate out of range.');
elseif nargin < 1 || ~isnumeric(scr)
  errmsg = 'No data.';
elseif ~any(size(scr) == 1)
  errmsg = 'Input SCR is not a vector';
else
  scr = scr(:);
end;

if exist('errmsg') == 1, warning(errmsg); return; end;


% options
% ------------------------------------------------------------------------
options = pspm_options(options, 'sf_mp');

% inversion settings in structure S
% ------------------------------------------------------------------------
S.dt = 1/sr;                    % sampling interval of the data
S.n = numel(scr);               % n: number of samples in the data segment
S.sfduration = 30;              % duration of the modelled SF
S.fresp = options.fresp;
S.sftail = 10;                  % model tail of SF in previous seconds
S.ntail = S.sftail/S.dt;        % number of samples in SF tail to model
S.nsf = S.sfduration/S.dt;      % number of samples in modelled SF
S.maxsf = S.n * S.dt * S.fresp; % maximum number of SF to account for
S.sfsets = {[1, 0]};            % model single response only (latency 1, amplitude 0)
S.tonicsets = {[],[]};          % no tonic response components
S.theta = pspm_sf_theta;         % get SF CRF
S.maxres = 0.001 * S.n;         % residual threshold per sample
S.options = options;
S.threshold = options.threshold;

% generate over-complete dictionary D.D
% -------------------------------------------------------------------------

% generate SF templates ---
for iSet = 1:numel(S.sfsets)
  % generate each set of predefined SF by calling ODE
  Xt = zeros(3, 1);
  ut = S.dt:S.dt:S.sfduration;
  ut(2, :) = numel(S.sfsets{iSet})/2;
  in.dt = S.dt;
  Theta = [S.theta(1:3), S.sfsets{iSet}];
  for k = 1:(size(ut, 2) - 1)
    Xt(:, k + 1) = f_SF(Xt(:, k), Theta, ut(:, k), in);
  end;
  % extract SF amplitude and normalise to 1 unit
  if iSet == 1
    sfa = max(Xt(1, :));
  end;
  sf{iSet} = Xt(1, :)/sfa;
end;

% initialise D.D ---
D.D = zeros(numel(S.sfsets) * S.n + S.ntail + numel(S.tonicsets{1}) * numel(S.tonicsets{2}), S.n);

% model atoms for SF tail ---
for k = 1:S.ntail
  D.D(k, 1:min(S.n, S.nsf - S.ntail + k - 1)) = sf{1}((S.ntail - k + 2):min(S.nsf, S.ntail - k + 1 + S.n));
  D.tindx(k) = 1 - (S.ntail - k + 1) .* S.dt;
end;
Dindx = k;

% model atoms for SF occuring in data segment --
for iSet = 1:numel(S.sfsets)
  maxn = S.n;
  for k = 1:maxn
    D.D(Dindx + k, k:min(k + S.nsf - 1, S.n)) = sf{iSet}(1:min(S.nsf, S.n - k + 1));
    D.tindx(Dindx + k) = 1 + (k - 1) .* S.dt;
  end;
  Dindx = Dindx + k;
end;
D.phasicterms = Dindx;

Dindx = Dindx + 1;

% model tonic atoms
for ia = 1:numel(S.tonicsets{1})
  for ib = 1:numel(S.tonicsets{2})
    D.D(Dindx, :) = S.tonicsets{1}(ia) + (1:S.n) * S.dt * S.tonicsets{2}(ib);
    D.D(Dindx + 1, :) = (S.tonicsets{1}(ia) + S.n * S.dt * S.tonicsets{2}(ib)) - (1:S.n) * S.dt * S.tonicsets{2}(ib);
    D.tindx(Dindx + (0:1)) = NaN;
    Dindx = Dindx + 2;
  end;
end;

% % normalise D.D and retain original amplitudes --
% (this is to make inner product interpretable)
D.aD = sqrt(diag(D.D*D.D'));
D.D = D.D./repmat(D.aD, 1, size(D.D, 2));

% clear local variables ---
clear Xt ut in Theta k iSet sfa maxsn D.Dindx

% prepare data
% -------------------------------------------------------------------------
y = scr(:);
y = y - min(y);

% iterative greedy search algorithm
% -------------------------------------------------------------------------
% initialise algorithm ---
S.cont = 1;
S.nosf = 0;
k = 1;
S.Yres = y;
% initialise diagnostics
S.diagnostics.neg = 0; % stop because of zero or negative amplitude
S.diagnostics.num = 0; % number of iterations
S.diagnostics.error = NaN; % error

a = [];
asf = [];
ind = [];

% run algorithm ---
while S.cont
  % remove used atoms from dictionary
  S.Dind = find(~ismember(1:(size(D.D, 1)), ind));
  S.Dtemp = D.D(S.Dind, :);
  % compute inner product
  anew = S.Dtemp * S.Yres;
  % search for largest value and retain index
  [a(k, 1), tempindx] = max(anew);
  % translate temporary index into index for entire dictionary
  ind(k, 1) = S.Dind(tempindx);
  % stopping criterion: negative and zero values
  if a(k, 1) <=0
    a(k) = []; ind(k) = [];
    S.cont = 0;
    S.diagnostics.neg = 1;
  else
    % compute amplitude in original values
    asf(k, 1) = a(k)/D.aD(ind(k));
    % compute residual
    S.Yres = S.Yres - a(k) * D.D(ind(k), :)';
    % stopping criteria: smaller than threshold, maximum number of sf
    if sum(S.Yres.^2) < S.maxres || k >= S.maxsf
      S.cont = 0;
    end;
    k = k + 1;
  end;
end;

S.diagnostics.num = numel(a); % number of iterations
S.diagnostics.error = sum(S.Yres.^2); % error

% reestimate all amplitudes simultaneously using ML as engendered in pinv
% -------------------------------------------------------------------------
aprime = pinv(D.D(ind, :))' * y;
asfprime = aprime./D.aD(ind);

% reconstruct responses
% -------------------------------------------------------------------------
Yhat = sum(repmat(a, 1, size(D.D, 2)) .* D.D(ind, :), 1);
Yhatprime = sum(repmat(aprime, 1, size(D.D, 2)) .* D.D(ind, :), 1);

% revert normalisation of dictionary
% -------------------------------------------------------------------------
D.D = D.D .* repmat(D.aD, 1, size(D.D, 2));

% extract timing and amplitudes
% -------------------------------------------------------------------------
[ind, sortind] = sort(ind);
t = D.tindx(ind);        % retrieve timing from dictionary index
ex = find(t < -2 | t > (numel(scr)/sr - 1)); % find SA responses the SCR peak of which is outside episode
t(ex) = []; sortind(ex) = []; ind(ex) = [];
out.t = t - S.theta(4);  % subtract conduction delay
out.a = asfprime(sortind);
out.rawa = asf(sortind);
out.n = numel(find(out.a > S.threshold));
out.f = out.n/(numel(scr)/sr);
out.ma = mean(out.a(out.a > S.threshold));

% cleanup S.Dtemp
S = rmfield(S, 'Dtemp');
out.S = S;

% only add field D if options.diagnostics is set to true.
if options.diagnostics
  out.D = D;
end;
out.ind = ind;
out.sortind = sortind;
out.y = y;
out.yhat = Yhatprime;
out.yhatraw = Yhat;
out.threshold = S.threshold;
out.time = toc(tstart);

% diagnostic plot
% -------------------------------------------------------------------------
if options.dispwin
  figure;
  ind = ind(out.a > S.threshold);
  plot(Yhatprime, 'g'); hold on
  plot(y, 'k');
  plot(D.D(ind, :)', 'b');
  plot(Yhat, 'r');
end;
