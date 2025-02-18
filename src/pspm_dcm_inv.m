function [sts, dcm] = pspm_dcm_inv(model, options)
% ● Description
%   pspm_dcm_inv does trial-by-trial inversion of a DCM for skin conductance
%   created by pspm_dcm. This includes estimating trial by trial estimates of
%   sympathetic arousal as well as estimation of the impulse response
%   function, if required.
%   Whether the IR is estimated from the data or not is determined by pspm_dcm
%   and passed to the inversion routine in the options.
% ● Format
%   [sts, dcm] = pspm_dcm_inv(model, options)
% ● Arguments
%   ┌─────────model
%   ├──────────.scr:  [cell_array] normalised and min-adjusted time series
%   ├──────.zfactor:  Normalisation denominator from pspm_dcm
%   ├───────────.sr:  [numeric] sampling rate (must be the same across sessions).
%   ├───────.events:  [a cell of cell array] flexible and fixed events:
%   │                 model.events{1}{sn} - flexible;
%   │                 model.events{2}{sn} - fixed.
%   ├─────.trlstart:  [cell] trial start for each trial (created in pspm_dcm)
%   ├──────.trlstop:  [cell] trial end for each trial (created in pspm_dcm)
%   ├──────────.iti:  [cell] ITI for each trial (created in pspm_dcm).
%   ├─────────.norm:  [optional, default as 0]
%   │                 whether to normalise data.
%   │                 i. e. data are normalised during inversion but results
%   │                 transformed back into raw data units.
%   ├───.flexevents:  [optional] flexible events to adjust amplitude priors
%   ├────.fixevents:  [optional] fixed events to adjust amplitude priors
%   ├─.missing_data:  [optional] missing epoch data, originally loaded as model.missing
%   │                 from pspm_dcm, but calculated into .missing_data (created
%   │                 in pspm_dcm and then transferred to pspm_dcm_inv.
%   └──.constrained:  [optional] constrained model for flexible responses which have
%                     have fixed dispersion (0.3 s SD) but flexible latency
%   ┌───────options
%   ├─────────.eSCR:  [optional] contains the data to estimate RF from
%   ├─────────.aSCR:  [optional] contains the data to adjust the RF to
%   ├──────.meanSCR:  [optional] data to adjust the response amplitude priors to
%   ├────.crfupdate:  [optional] update CRF priors to observed SCRF, or use
%   │                 pre-estimated priors (default)
%   ├────────.getrf:  [optional] only estimate RF, do not do trial-wise DCM
%   ├───────────.rf:  [optional] use pre-specified RF, provided in file, or as 4-element
%   │                 vector in log parameter space
%   ├────────.depth:  [optional, numeric, default as 2]
%   │                 no of trials to invert at the same time.
%   ├────────.sfpre:  [optional, numeric, default as 2, unit: second]
%   │                 sf-free window before first event.
%   ├───────.sfpost:  [optional, numeric, default: 5, unit: second]
%   │                 sf-free window after last event.
%   ├───────.sffreq:  [optional, numeric, default: 0.5, unit: /second or Hz]
%   │                 maximum frequency of SF in ITIs.
%   ├───────.sclpre:  [optional, numeric, default: 2, unit: second]
%   │                 scl-change-free window before first event.
%   ├──────.sclpost:  [optional, numeric, default: 5, unit: second]
%   │                 scl-change-free window after last event.
%   ├─.aSCR_sigma_offset:
%   │                 [optional, numeric, default: 0.1, unit: second]
%   │                 minimum dispersion (standard deviation) for flexible
%   │                 responses.
%   ├──────.dispwin:  [optional, bool, default as 1]
%   │                 display progress window.
%   └─.dispsmallwin:  [optional, bool, default as 0]
%                     display intermediate windows
% ● Outputs
%   *           dcm:  Output units, all timeunits are in seconds. eSCR
%                     and aSCR amplitude are in SN units such that an
%                     eSCR SN pulse with 1 unit amplitude causes an eSCR
%                     with 1 mcS amplitude (unless model.norm = 1).
% ● Developer Notes
%   There are two event types: flexible and fixed. The terminology is to call
%   flexible responses aSCR (anticipatory) and fixed responses eSCR (evoked
%   SCR).
%   All parameters are extracted as parameter values and are transformed
%   back to meaningful values at the end (to avoid transformation at each
%   step), apart from SF timing.
%   The SCR timeseries is z-transformed in pspm_dcm, and amplitude parameter
%   estimates transformed back at the end (to standardise priors and
%   precisions).
% ● References
%   [1] Bach DR, Daunizeau J, Friston KJ, Dolan RJ (2010).
%       Dynamic causal modelling of anticipatory skin conductance changes.
%       Biological Psychology, 85(1), 163-70
%   [2] Staib, M., Castegnetti, G., & Bach, D. R. (2015).
%       Optimising a model-based approach to inferring fear learning from skin
%       conductance responses.
%       Journal of Neuroscience Methods, 255, 131-138.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2011-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

dcm = [];
fprintf('Computing non-linear model: %s ...\n', model.modelfile);

% check input
% ------------------------------------------------------------------------
if nargin < 1, warning('Input model undefined'); return; end

% set model
% ------------------------------------------------------------------------
try model.scr; catch, warning('Input data not defined.'); return; end
try model.sr; catch, warning('Sample rate not defined.'); return; end
try model.events; catch, warning('Event timing not defined.'); return; end
try model.trlstart; catch, warning('Trial starts not defined.'); return; end
try model.trlstop; catch, warning('Trial ends not defined.'); return; end
try model.iti; catch, warning('ITIs not defined.'); return; end
try model.norm; catch, model.norm = 0; end
try model.constrained; catch, model.constrained = 0; end
try model.constrained_upper; catch, model.constrained_upper = 0; end


try model.aSCR; catch, model.aSCR = 0; end
try model.eSCR; catch, model.eSCR = 0; end
try model.meanSCR; catch, model.meanSCR = 0; end
% These parameters were set with default fallback values but will be
% determined later by processing (same to pspm_dcm)
% try model.fixevents; catch, warning('model.fixevents not defined.'); end
% try model.flexevents; catch, warning('model.flexevents not defined.'); end
% try model.missing_data; catch, warning('model.missing_data not defined.'); end
% These parameters do not need to have a default value and will be
% determined later (same to pspm_dcm)

% set options
options = pspm_options(options, 'dcm_inv');
if options.invalid
  return
end
try invopt.DisplayWin = options.dispwin; catch, invopt.DisplayWin = 1; end
try invopt.GnFigs = options.dispsmallwin; catch, invopt.GnFigs = 0; end
sigma_offset_temp = settings.dcm{1}.sigma_offset;
try settings.dcm{1}.sigma_offset = options.aSCR_sigma_offset; catch; end

% set general priors and initial conditions
% -------------------------------------------------------------------------
% SF priors --
sftheta = pspm_sf_theta;
sf_unit = 1./exp(sftheta(5));
sftheta = sftheta(1:3);
fixedSD = 0.3;

% CRF priors generated on 27.04.2010 --
% numeric values given in log(parameter space) such that these
% numeric values in the log expression are consistent with manual 12.05.2014
% (before, numeric values were given in log space)
crftheta = log([0.122505, 1.411425, 1.342052, 1.533879]);
prior.eTheta(1).a = 0.7064;

% combine output function priors --
theta = [crftheta sftheta];
theta_n = numel(theta);

% get pre-specified values if required --
if isfield(options, 'rf')
  if isnumeric(options.rf) && options.rf == 0
    % do nothing
  elseif any(model.eSCR) || any(model.aSCR) || options.crfupdate
    warning('RF can be provided or estimated, not both.'); return;
  elseif ischar(options.rf)
    [pth, rf, ext] = fileparts(options.rf);
    if ~isempty(pth), addpath(pth); end
    try
      [foo, theta] = feval(str2func(rf), 0.1);
    catch
      warning('Specified RF not found'); return;
    end
    if ~isempty(pth), rmpath(pth); end
  elseif isnumeric(options.rf)
    theta = options.rf;
  else
    warning('Unknown RF format (must be file name or numeric).'); return;
  end
  if numel(theta) ~= theta_n
    warning('Wrong number of parameters specified.'); return;
  end
end

% event numbers per trial --
aSCRno = size(model.events{1}{1}, 2);
eSCRno = size(model.events{2}{1}, 2);

% aSCR priors --
prior.aTheta.m = zeros(1, aSCRno);
if model.constrained
  prior.aTheta.s = 100 * ones(1, aSCRno);
else
  prior.aTheta.s = zeros(1, aSCRno);
end
prior.aTheta.a = log(0.25) * ones(1, aSCRno);

% shorten variable names --
sr = model.sr;
yscr = model.scr;
events = model.events;

% tidy up --
clear sftheta crftheta

% VB settings
% ------------------------------------------------------------------------
g_fname = 'g_SCR';
f_fname = 'f_SCR';
dim.n_phi   =  0;                       % nb of observation parameters
dim.n       =  7;                       % nb of hidden states
priors.muPhi = [];
priors.SigmaPhi = [];
priors.muX0 = zeros(dim.n, 1);
priors.SigmaX0 = zeros(dim.n);
priors.a_sigma = 1e2;
priors.b_sigma = 1e-2;
priors.a_alpha = Inf;
priors.b_alpha = 0;
invopt.inG.ind = 1;
% that should be sufficient as max(lambda(J))>.1 for standard theta values
invopt.inF.decim = 0.1;


% (1) Estimate CRF priors
% =======================================================================
% This is to make this function immune to modifications of f_SCR

if options.crfupdate
  c = clock;
  fprintf('----------------------------------------------------------\n');
  fprintf('%02.0f:%02.0f:%02.0f: Estimate CRF priors', c(4:6));
  load([settings.path, 'Data' filesep 'CRF_observed.mat']);
  observed_sr = 10;
  invopt.inF.dt = 1/observed_sr;

  % prepare inversion
  u = [];
  u(1, :) = (0:numel(observed))/sr;
  u(2, :) = 0;
  u(3, :) = 1;
  u(4, :) = 0;
  u(5, :) = 0;
  u(6, :) = 0;
  u(:, 1) = 0;
  priors.muTheta = [theta, prior.eTheta.a]';
  dim.n_theta = numel(priors.muTheta);    % nb of evolution parameters
  priors.SigmaTheta = eye(dim.n_theta);
  priors.SigmaX0(1:3,1:3) = eye(3);
  % initialise priors in correct dimensions
  priors.iQy = cell(numel(observed), 1);
  priors.iQx = cell(numel(observed), 1);
  for k = 1:numel(observed)  % default priors on noise covariance
    priors.iQy{k} = 1;
    priors.iQx{k} = eye(dim.n);
  end
  invopt.priors = priors;
  % estimate
  [post, out] = VBA_NLStateSpaceModel(observed(:)',u,f_fname,g_fname,dim,invopt);

  % extract parameters
  theta(1:4) = post.muTheta(1:4)';
  prior.eTheta(1).a  = post.muTheta(8);
  prior.posterior(1) = post;
  prior.output(1)    = out;
  clear observed
end

% adapt inversion options to actual sampling rate
invopt.inF.dt = 1/sr;

% (2) Estimate response function
% =======================================================================
if numel(model.eSCR) > 1
  c = clock;
  fprintf('----------------------------------------------------------\n');
  fprintf('%02.0f:%02.0f:%02.0f: Estimate response function', c(4:6));

  % prepare observed data
  observed = model.eSCR;

  % prepare inversion
  u = [];
  u(1, :) = (0:numel(observed))/sr;
  u(2, :) = 0;
  u(3, :) = 1;
  u(4, :) = 0;
  u(5, :) = 0;
  u(6, :) = 0;
  u(:, 1) = 0;
  priors.muTheta = [theta, prior.eTheta.a]';
  dim.n_theta = numel(priors.muTheta);    % nb of evolution parameters
  priors.SigmaTheta = eye(dim.n_theta);
  priors.SigmaX0(1:3,1:3) = eye(3);
  % initialise priors in correct dimensions
  priors.iQy = cell(numel(observed), 1);
  priors.iQx = cell(numel(observed), 1);
  for k = 1:numel(observed)  % default priors on noise covariance
    priors.iQy{k} = 1;
    priors.iQx{k} = eye(dim.n);
  end
  invopt.priors = priors;
  % estimate
  [post, out] = VBA_NLStateSpaceModel(observed(:)',u,f_fname,g_fname,dim,invopt);

  % extract parameters
  theta(1:4) = post.muTheta(1:4)';
  prior.eTheta(1).a        = post.muTheta(8);
  prior.aTheta(1).a        = prior.eTheta(1).a + prior.aTheta(1).a;
  prior.posterior(2) = post;
  prior.output(2)    = out;
end

% (3) Update this on full trial window
% =======================================================================
if numel(model.aSCR) > 1
  c = clock;
  fprintf('----------------------------------------------------------\n');
  fprintf('%02.0f:%02.0f:%02.0f: Adjust response function', c(4:6));

  % prepare observed data
  observed = model.aSCR;

  % prepare inversion
  u = [];
  u(1, :) = (0:numel(observed))/sr;
  u(2, :) = aSCRno;
  u(3, :) = eSCRno;
  u(4, :) = 0;
  u(5, :) = 0;
  for k = 1:aSCRno
    u(5 + k, :)                 = model.flexevents(k, 1);
    u(5 + aSCRno + k, :)        = model.flexevents(k, 2);            % aSCR mean upper bound
    u(5 + 2 * aSCRno + k, :)    = diff(model.flexevents(k, :))/2;    % aSCR SD upper bound
  end
  for k = 1:eSCRno
    u(5 + 3 * aSCRno + k, :)    = model.fixevents(k);                % eSCR onset
  end
  u(:, 1) = 0;
  priors.muTheta = [theta(1:7) repmat([prior.aTheta.m(1) prior.aTheta.s(1) prior.aTheta.a(1)], 1, aSCRno) repmat(prior.eTheta.a, 1, eSCRno)]';
  dim.n_theta = numel(priors.muTheta);    % nb of evolution parameters
  priors.SigmaTheta = eye(dim.n_theta);
  priors.SigmaX0 = zeros(dim.n);
  priors.SigmaX0(1:3,1:3) = eye(3);
  % initialise priors in correct dimensions
  priors.iQy = cell(numel(observed), 1);
  priors.iQx = cell(numel(observed), 1);
  for k = 1:numel(observed)  % default priors on noise covariance
    priors.iQy{k} = 1;
    priors.iQx{k} = eye(dim.n);
  end
  invopt.priors = priors;

  % estimate
  [post, out] = VBA_NLStateSpaceModel(observed(:)',u,f_fname,g_fname,dim,invopt);

  % extract parameters
  theta                = post.muTheta(1:7)';

  % extract params
  for k = 1:aSCRno
    prior.aTheta.m(1, k) = post.muTheta(theta_n + 3 * (k - 1) + 1);
    prior.aTheta.s(1, k) = post.muTheta(theta_n + 3 * (k - 1) + 2);
    prior.aTheta.a(1, k) = post.muTheta(theta_n + 3 * (k - 1) + 3);
  end
  for k = 1:eSCRno
    prior.eTheta.a(1, k) = post.muTheta(theta_n + 3 * aSCRno + k);
  end

  prior.posterior(3) = post;
  prior.output(3)    = out;
end


% (4) estimate the amplitude of the averaged response for use as prior
% =======================================================================
if (numel(model.meanSCR) > 1) && (~options.getrf)
  c = clock;
  fprintf('----------------------------------------------------------\n');
  fprintf('%02.0f:%02.0f:%02.0f: Estimate mean response amplitude', c(4:6));

  % prepare inversion
  u = [];
  u(1, :) = (0:numel(model.meanSCR))/sr;
  u(2, :) = aSCRno;
  u(3, :) = eSCRno;
  u(4, :) = 0;
  u(5, :) = 0;
  for k = 1:aSCRno
    u(5 + k, :)                 = model.flexevents(k, 1);
    u(5 + aSCRno + k, :)        = model.flexevents(k, 2);            % aSCR mean upper bound
    if model.constrained
      u(5 + 2 * aSCRno + k, :)    = fixedSD - settings.dcm{1}.sigma_offset;    % aSCR SD upper bound
    elseif model.constrained_upper
      u(5 + 2 * aSCRno + k, :)    = model.constrained_upper - settings.dcm{1}.sigma_offset;    % aSCR SD upper bound
    else
      u(5 + 2 * aSCRno + k, :)    = diff(model.flexevents(k, :))/2 - settings.dcm{1}.sigma_offset;    % aSCR SD upper bound
    end
  end
  for k = 1:eSCRno
    u(5 + 3 * aSCRno + k, :)    = model.fixevents(k);                % eSCR onset
  end
  u(:, 1) = 0;
  aSCRpriors = repmat([prior.aTheta.m' prior.aTheta.s' prior.aTheta.a']', aSCRno, 1);
  eSCRpriors = repmat(prior.eTheta.a, eSCRno, 1);
  priors.muTheta = [theta(1:7) aSCRpriors(:)' eSCRpriors(:)']';
  dim.n_theta = numel(priors.muTheta);    % nb of evolution parameters
  priors.SigmaTheta = eye(dim.n_theta);

  % output function parameters are now fixed
  for n = 1:theta_n, priors.SigmaTheta(n, n) = 0; end

  % if model constrained, flexible response dispersion is fixed
  if model.constrained
    aSCRindx = theta_n + 3 * ((1:aSCRno) - 1) + 2;
    for n = 1:theta_n, priors.SigmaTheta(n, n) = 0; end
  end

  priors.SigmaX0 = zeros(dim.n);
  priors.SigmaX0(1:3,1:3) = eye(3);
  % initialise priors in correct dimensions
  priors.iQy = cell(numel(model.meanSCR), 1);
  priors.iQx = cell(numel(model.meanSCR), 1);
  for k = 1:numel(model.meanSCR)  % default priors on noise covariance
    priors.iQy{k} = 1;
    priors.iQx{k} = eye(dim.n);
  end
  invopt.priors = priors;

  % estimate
  [post, out] = VBA_NLStateSpaceModel(model.meanSCR(:)',u,f_fname,g_fname,dim,invopt);

  % extract params
  for k = 1:aSCRno
    prior.aTheta.m(1, k) = post.muTheta(theta_n + 3 * (k - 1) + 1);
    prior.aTheta.s(1, k) = post.muTheta(theta_n + 3 * (k - 1) + 2);
    prior.aTheta.a(1, k) = post.muTheta(theta_n + 3 * (k - 1) + 3);
  end
  for k = 1:eSCRno
    prior.eTheta.a(1, k) = post.muTheta(theta_n + 3 * aSCRno + k);
  end

  prior.posterior(4) = post;
  prior.output(4)    = out;
end

% complete prior structure for output
prior.theta = theta;

% (5) extract eSCR scaling, given response parameters, and SCL scaling,
% given f_SCR
% =======================================================================
% script to check the eSCR scaling: pspm_f_check_amplitudes.m in backroom
% an eSCR pulse of amplitude 1 elicits an eSCR of amplitude 1
% scaling is not done within ODE because it depends on the parameters which
% are set outside the ODE
intsr = 1000; % sample rate for the integration
u = [];
u(1, :) = (0:(30*intsr))/intsr;
u(2, :) = 0;
u(3, :) = 1;
u(4, :) = 0;
u(5, :) = 0;
u(6, :) = 0;
u(:, 1) = 0;
Theta = [theta, log(1)]';
Xt = zeros(dim.n, size(u, 2));
in = []; in.dt = 1/intsr;
for k = 1:size(u, 2)
  Xt(:, k + 1) = f_SCR(Xt(:, k), Theta, u(:, k), in);
end
eSCR_unit = 1/max(Xt(1, :));
clear u Xt in Theta

u = [];
u(1, :) = (0:(30*intsr))/intsr;
u(2, :) = 0;
u(3, :) = 0;
u(4, :) = 0;
u(5, :) = 1;
u(6, :) = 5;
u(7, :) = 10;
Theta = [theta, 1 1]';
Xt = zeros(7, size(u, 2));
in = []; in.dt = 1/intsr;
for k = 1:size(u, 2)
  Xt(:, k + 1) = f_SCR(Xt(:, k), Theta, u(:, k), in);
end
SCL_unit = 1/max(Xt(7, :));
clear u Xt in Theta


% (6) proceed session by session
% =========================================================================

if ~options.getrf
  for sn = 1:numel(yscr)
    % initialise
    Xt = zeros(dim.n, numel(yscr{sn}));
    sfc = 0;
    SCLtheta = [];
    sfTheta  = [];
    trlno = max([size(events{1}{sn}, 1), size(events{2}{sn}, 1)]);

    trlstart = model.trlstart{sn};
    trlstop  = model.trlstop{sn};
    iti      = model.iti{sn};
    miniti   = min(iti);                                                % minimum ITI

    c = clock;
    fprintf('----------------------------------------------------------\n');
    fprintf('%02.0f:%02.0f:%02.0f: Session %1.0f - %1.0f Trials\n', c(4:6), sn, trlno);


    % estimate trial-by-trial
    % =======================================================================
    if options.depth > trlno
        trlindx = 1;
    else
        trlindx = 1:trlno;
    end

    for trl = trlindx
      c = clock;
      tic;
      fprintf('----------------------------------------------------------\n');
      fprintf('%02.0f:%02.0f:%02.0f: Session %1.0f - Trial %1.0f\n', c(4:6), sn, trl);

      % -- initialise
      priors.muTheta = [];
      priors.SigmaTheta = [];
      u = [];

      % -- timewindow: start of current trial until start of adepth trials
      start = floor(sr * trlstart(trl));  % note there were rounding problems when using ceil here so use floor and exlude zeros
      if start == 0, start = 1; end
      if (trl + options.depth) <= trlno
        adepth = options.depth;
        stop = floor((sr * trlstart(trl + adepth)));
        win = start:stop;
      else
        adepth = trlno - trl + 1;
        % for last trial, if possible use at least 10 s of data, and at
        % most min ITI. If this is not possible, use all available data.
        stop = min([floor((sr * (trlstop(end) + min([miniti, 10])))), numel(yscr{sn})]);
        win = start:stop;
      end

      % this leaves so many trials
      trls = trl - 1 + (1:adepth);

      % assign data
      y = yscr{sn}(win);
      ymissing = model.missing_data{sn}(win);

      % intial states
      priors.SigmaX0 = zeros(7);
      priors.muX0 = zeros(7, 1);
      if trl == 1
        y_non_nan = y(~isnan(y));
        priors.muX0(1) = mean(y_non_nan(1:3));%) - min(y);
        priors.muX0(2) = mean(diff(y_non_nan(1:3)));
        priors.muX0(3) = diff(diff(y_non_nan(1:3)));
        priors.muX0(7) = 0;%min(y);
        for n = [1:3 7]
          priors.SigmaX0(n, n) = 1e-2;
        end
      else
        priors.muX0 = Xt(:, win(1));
      end

      % -- prepare priors theta and input u
      u(1, :) = (0:numel(y))/sr;
      priors.muTheta = theta';

      % -- define aSCR based on adepth (no of trials to be estimated) and
      % -- asCRno (no of aSCR per trial)
      % -- structure: trl 1 aSCR 1 - trl 1 aSCR 2 - trl 2 aSCR 1 - ...
      % -- and for each aSCR: m - s - a

      if aSCRno > 0
        % get trial onsets and identify `dummy` events
        aSCR_dummy = zeros(aSCRno, adepth);
        aSCR_on = events{1}{sn}(trls, :, 1)';
        aSCR_dummy(aSCR_on < 0) = 1;
        % - get aSCR priors from previous estimations
        aSCR_ind = theta_n  + (1:3:(3 * aSCRno * adepth));
        if trl == 1
          priors.muTheta(aSCR_ind)     = repmat(prior.aTheta.m, 1, adepth);
          priors.muTheta(aSCR_ind + 1) = repmat(prior.aTheta.s, 1, adepth);
          priors.muTheta(aSCR_ind + 2) = repmat(prior.aTheta.a, 1, adepth);
        else
          priors.muTheta(aSCR_ind)     = [[aTheta(trl + (0:(adepth - 2))).m], prior.aTheta.m];
          priors.muTheta(aSCR_ind + 1) = [[aTheta(trl + (0:(adepth - 2))).s], prior.aTheta.s];
          priors.muTheta(aSCR_ind + 2) = [[aTheta(trl + (0:(adepth - 2))).a], prior.aTheta.a];
        end
        % - define prior indices to be set to zero later on
        aSCR_dummyind = aSCR_ind(aSCR_dummy == 1);
        aSCR_dummyind = [aSCR_dummyind, aSCR_dummyind + 1, aSCR_dummyind + 2];
        % - get aSCR number
        u(2, :) = aSCRno * adepth;
        % insert aSCR onsets (-10 s for dummy events)
        aSCR_on(aSCR_dummy == 1) = -10;
        u(5 + (1:u(2, 1)), :) = repmat(aSCR_on(:) - win(1)/sr, 1, size(u, 2));
        % - get aSCR latency upper bound (0.1 for dummy events)
        foo = diff(events{1}{sn}(trls, :, :), [], 3)';
        foo(aSCR_dummy == 1) = 0.1;
        u(5 + u(2, 1) + (1:u(2, 1)), :) = repmat(foo(:), 1, size(u, 2));
        aSCR_ln(1:aSCRno, trl) = foo(:, 1); % save first trial for transformation of parameter values into seconds
        % - get aSCR SD upper bound (zero for dummy events, fixed SD for constrained models)
        if model.constrained
            u(5 + 2 * u(2, 1) + (1:u(2, 1)), :) = repmat(fixedSD, numel(foo), size(u, 2)) - settings.dcm{1}.sigma_offset;
        elseif model.constrained_upper > 0
            u(5 + 2 * u(2, 1) + (1:u(2, 1)), :) = repmat(model.constrained_upper, numel(foo), size(u, 2)) - settings.dcm{1}.sigma_offset;
        else
            u(5 + 2 * u(2, 1) + (1:u(2, 1)), :) = repmat(foo(:)/2, 1, size(u, 2)) - settings.dcm{1}.sigma_offset;
        end
        % tidy up
        clear aSCR_on foo aSCR_dummy
      else
        u(2, :) = 0; aSCR_dummyind = [];
      end

      % - get eSCR priors from previous estimations
      if eSCRno > 0
        % - identify `dummy` events
        eSCR_dummy = zeros(eSCRno, adepth);
        eSCR_on = events{2}{sn}(trls, :)';
        eSCR_dummy(eSCR_on < 0) = 1;
        % - get eSCR priors from previous estimations
        eSCR_ind = theta_n + 3 * u(2, 1) + (1:(eSCRno * adepth));
        if trl == 1
          priors.muTheta(eSCR_ind) = repmat(prior.eTheta.a, 1, adepth);
        else
          priors.muTheta(eSCR_ind) = [[eTheta(trl + (0:(adepth - 2))).a], prior.eTheta.a];
        end
        % - define prior indices to be set to zero later on
        eSCR_dummyind = eSCR_ind(eSCR_dummy == 1);
        % - get eSCR number
        u(3, :) = eSCRno * adepth;
        % - insert eSCR onsets (-10 s for dummy events)
        eSCR_on(eSCR_dummy == 1) = -10;
        u(5 + 3 * u(2, 1) + (1:u(3, 1)), :) =  repmat((eSCR_on(:) - win(1)/sr), 1, size(u, 2));
        % tidy up
        clear eSCR_on eSCR_dummy
      else
        u(3, :) = 0; eSCR_dummyind = [];
      end

      % - insert SF if inter-trial intervals are long enough
      sf = {}; lb = {}; ub = {};
      for k = 1:adepth
        if iti(trls(k)) > (options.sfpre + options.sfpost)
          if trls(k) < trlno
            lb{k, 1} = trlstop(trls(k)) + options.sfpost - win(1)/sr;
            ub{k, 1} = trlstart(trls(k) + 1) - options.sfpre  - win(1)/sr;
          else
            lb{k, 1} = trlstop(trls(k)) + options.sfpost - win(1)/sr;
            ub{k, 1} = win(end)/sr - win(1)/sr;
          end
          sf{k, 1} = (lb{k}:(1/options.sffreq):ub{k})' - lb{k, 1};
          lb{k, 1} = repmat(lb{k, 1}, numel(sf{k, 1}), 1);
          ub{k, 1} = repmat(ub{k, 1}, numel(sf{k, 1}), 1);
        end
      end
      % -- number of responses to save
      if isempty(sf)
        sft = 0;
      else
        sft = numel(sf{1});
      end
      sf = cell2mat(sf);
      lb = cell2mat(lb);
      ub = cell2mat(ub);
      % -- insert SF number and lower/upper bounds into u
      if numel(sf) > 0
        u(4, :) = numel(lb);
        u(5 + 3 * u(2, 1) + u(3, 1) + (1:numel(sf)), :) = repmat(lb, 1, size(u, 2));
        u(5 + 3 * u(2, 1) + u(3, 1) + numel(sf) + (1:numel(sf)), :) = repmat(ub, 1, size(u, 2));
        % -- determine starting values from sigma function
        sig.beta = 0.5; sig.G0 = 1;
        val = -10:0.1:10;
        sigma = sigm(val, sig);
        start = theta_n + 3 * u(2, 1) + u(3, 1);
        for n = 1:numel(sf)
          [foo, ind] = min(abs(sigma - sf(n)/(ub(n) - lb(n))));
          priors.muTheta(start + (n - 1) * 2 + 1)  = val(ind);
        end
        priors.muTheta(start + (2:2:(2 * numel(sf)))) = -3; % such that exp(a) < .1, which is the cutoff value for SF in Bach et al. (2010) Psychophysiology
      end
      clear int sf k start val sigma foo ind
      % - add SCL changes if ITI is long enough
      scllb = []; sclub = []; sclt = []; scla = [];
      rmscltrl = zeros(size(trls));
      c = 1;
      for k = 1:numel(trls)
        if iti(trls(k)) > (options.sclpre + options.sclpost)
          if trls(k) < trlno
            scllb(c) = trlstop(trls(k)) + options.sclpost - win(1)/sr;
            sclub(c) = trlstart(trls(k) + 1) - options.sclpre  - win(1)/sr;
          else
            scllb(c) = trlstop(trls(k)) + options.sfpost - win(1)/sr;
            sclub(c) = win(end)/sr;
          end
          try
            sclt(c) = SCLtheta(trls(k)).t;
            scla(c) = SCLtheta(trls(k)).a;
          catch
            sclt(c) = 0;
            scla(c) = 0;
          end
          c = c + 1;
        else
          rmscltrl(k) = 1;
        end
      end
      % if all trials are estimated at once, then retain this information
      % for all trials; otherwise just extract the first trial.
      if trlindx == 1
          for k = 1:numel(trls)
              if rmscltrl(k) == 1
                  scl_lb(k) = -1; scl_ln(k) = -1;
              else
                  scl_lb(k) = scllb(k) + win(1)/sr; scl_ln(k) = sclub(k) - scllb(k);
              end
          end
      else
          if rmscltrl(1) == 1
              scl_lb(trl) = -1; scl_ln(trl) = -1;
          else
              scl_lb(trl) = scllb(1) + win(1)/sr; scl_ln(trl) = sclub(1) - scllb(1);
          end
      end
      % -- insert priors
      u(5, :) = numel(scllb);
      if u(5, 1) > 0
        u(5 + 3 * u(2, 1) + u(3, 1) + 2 * u(4, 1) + (1:numel(scllb)), :) = repmat(scllb', 1, size(u, 2));
        u(5 + 3 * u(2, 1) + u(3, 1) + 2 * u(4, 1) + numel(sclub) + (1:numel(sclub)), :) = repmat(sclub', 1, size(u, 2));
        start = theta_n + 3 * u(2, 1) + u(3, 1) + 2 * u(4, 1);
        priors.muTheta(start + (1:2:(2 * u(5, 1)))) = sclt; % prior timing, or zero
        priors.muTheta(start + (2:2:(2 * u(5, 1)))) = scla; % amplitude: zero
      end

      % -- finalise prior structure
      dim.n_theta = numel(priors.muTheta);
      priors.SigmaTheta = 1e1 * eye(dim.n_theta);
      % output function parameters are fixed
      for n = 1:theta_n, priors.SigmaTheta(n, n) = 0; end
      % allow more uncertainty for SF amplitude and less for SF timing
      for n = (theta_n + 3 * u(2,1) + u(3,1) + 1):2:(theta_n + 3 * u(2,1) + u(3,1) + 2 * u(4, 1)), priors.SigmaTheta(n, n) = 1e-1; end
      for n = (theta_n + 3 * u(2,1) + u(3,1) + 2):2:(theta_n + 3 * u(2,1) + u(3,1) + 2 * u(4, 1)), priors.SigmaTheta(n, n) = 1e-1; end
      % allow less uncertainty for SCL changes
      for n = (theta_n + 3 * u(2,1) + u(3,1) + 2 * u(4, 1) + 1):2:size(priors.SigmaTheta, 1), priors.SigmaTheta(n, n) = 1e-5; end
      for n = (theta_n + 3 * u(2,1) + u(3,1) + 2 * u(4, 1) + 2):2:size(priors.SigmaTheta, 1), priors.SigmaTheta(n, n) = 1e-5; end
      % allow no uncertainty for previous SCL change
      if trl > 1
        priors.SigmaTheta((end-1):end, (end-1):end) = zeros(2);
      end
      % allow no uncertainty for dummy events
      for n = [aSCR_dummyind eSCR_dummyind], priors.SigmaTheta(n, n) = 0; end
      % allow no uncertainty for aSCR dispersion of model is
      % constrained
      if model.constrained
        aSCR_ind = theta_n  + (1:3:(3 * aSCRno * adepth)) + 1;
        for n = aSCR_ind
          priors.SigmaTheta(n, n) = 0;
        end
      end
      % set u0
      u(:, 1) = 0;
      % initialise priors in correct dimensions
      priors.iQy = cell(numel(y), 1);
      priors.iQx = cell(numel(y), 1);
      % default priors on noise covariance
      for k = 1:numel(y)
        priors.iQy{k} = 1;
        priors.iQx{k} = eye(dim.n);
      end
      invopt.priors = priors;

      % handle missing values
      invopt.isYout = ymissing(:)';

      % -- invert model
      [post, out]= VBA_NLStateSpaceModel(y(:)',u,f_fname,g_fname,dim,invopt);

      % -- extract aSCR and eSCR parameters from theta structure
      for k = 1:adepth
        m = trl + k - 1;
        n = theta_n + 3 * aSCRno * (k - 1);
        aTheta(m).m = post.muTheta(n + (1:3:(3*aSCRno)))';
        aTheta(m).s = post.muTheta(n + (2:3:(3*aSCRno)))';
        aTheta(m).a = post.muTheta(n + (3:3:(3*aSCRno)))';
        n = theta_n + 3 * u(2, 2) + eSCRno * (k - 1);
        eTheta(m).a = post.muTheta(n + (1:eSCRno))';
      end

      % -- extract SF parameters from theta structure (and transform timing
      % right away)
      if sft > 0
        for sf = 1:sft
          n = theta_n + 3 * u(2, 2) + u(3, 2) + 2 * (sf - 1) + 1;
          sig.G0 = ub(sf) - lb(sf);
          sfTheta(sf + sfc).t = win(1)/sr + lb(sf) + sigm(post.muTheta(n), sig);
          sfTheta(sf + sfc).a = post.muTheta(n + 1);
        end
        sfc = sfc + sf;
      end
      % -- extract SCL parameters from theta structure (but don't
      % transform timing)
      for k = 1:u(5, 2)
        n = theta_n + 3 * u(2, 2) + u(3, 2) + 2 * u(4, 2) + 2 * (k - 1) + 1;
        SCLtheta(trls(k)).t = post.muTheta(n);
        SCLtheta(trls(k)).a = post.muTheta(n + 1);
      end
      % -- extract hidden states
      Xt(:, win) = post.muX;
      % -- save results
      posterior(trl) = post;
      output(trl)    = out;
      indata{trl}    = y(:)';
      inwin{trl}     = win;
      ut{trl}        = u;
      mdl_time(trl)  = toc;
      % - tidy up
      clear sf sft post out trls start stop ub lb sig scllb sclub scla sclt

    end

    % transform parameters
    % =======================================================================

    sig.beta = 0.5;

    if model.norm == 1
      newzfactor = 1;
    else
      newzfactor = model.zfactor;
    end

    for trl = trlindx
      for k = 1:aSCRno
        sig.G0 = aSCR_ln(k, trl);
        aTheta(trl).m(k) = sigm(aTheta(trl).m(k), sig);
        if model.constrained
          sig.G0 = fixedSD - settings.dcm{1}.sigma_offset;
        else
          sig.G0 = aSCR_ln(k, trl)/2 - settings.dcm{1}.sigma_offset;
        end
        aTheta(trl).s(k) = sigm(aTheta(trl).s(k), sig) + settings.dcm{1}.sigma_offset;
      end
      aTheta(trl).a = newzfactor .* exp(aTheta(trl).a) ./ eSCR_unit;
      eTheta(trl).a = newzfactor .* exp(eTheta(trl).a) ./ eSCR_unit;
    end

    for trl = 1:numel(sfTheta)
      % SF response function includes a parameter for the amplitude of an
      % SN burst that causes a 1 mcS response, see pspm_sf_get_theta
      sfTheta(trl).a = newzfactor * exp(sfTheta(trl).a) * sf_unit;
    end

    for trl = 1:numel(SCLtheta)
      if scl_ln(trl) > 0
        sig.G0 = scl_ln(trl);
        SCLtheta(trl).t = scl_lb(trl) + sigm(SCLtheta(trl).t, sig);
        SCLtheta(trl).a = newzfactor * SCLtheta(trl).a * SCL_unit;
      else
        SCLtheta(trl).t = 0;
        SCLtheta(trl).a = 0;
      end
    end

    % extract timecourse
    yhat = sum(Xt([1 4 7], :));

    % tidy up
    clear sig

    % assemble results
    % =======================================================================
    if isfield(output, 'options')
      for i=1:length(output)
        if isstruct(output(i).options) && isfield(output(i).options, 'hf')
          output(i).options = rmfield(output(i).options, 'hf');
        end
      end
    end
    if isfield(prior, 'output')
      for i=1:length(prior.output)
        if isstruct(prior.output(i).options) && isfield(prior.output(i).options, 'hf')
          prior.output(i).options = rmfield(prior.output(i).options, 'hf');
        end
      end
    end
    dcm.sn{sn}.a = aTheta;
    dcm.sn{sn}.e = eTheta;
    dcm.sn{sn}.sf = sfTheta;
    dcm.sn{sn}.scl = SCLtheta;
    dcm.sn{sn}.Xt = Xt;
    dcm.sn{sn}.yhat = yhat;
    dcm.sn{sn}.prior = prior;
    dcm.sn{sn}.posterior = posterior;
    dcm.sn{sn}.output = output;
    dcm.sn{sn}.u = ut;
    dcm.sn{sn}.y = yscr{sn};
    dcm.sn{sn}.indata = indata;
    dcm.sn{sn}.win  = inwin;
    dcm.sn{sn}.zfactor = model.zfactor;
    dcm.sn{sn}.newzfactor = newzfactor;
    dcm.sn{sn}.eSCR_unit = eSCR_unit;
    dcm.sn{sn}.options = options;
    dcm.sn{sn}.model = model;
    dcm.sn{sn}.time = sum(mdl_time);

    clear aTheta eTheta sfTheta SCLtheta Xt yhat posterior output ut indata inwin
  end
else
  dcm.prior = prior;
end

%% (7) clear up
% ========================================================================
settings.dcm{1}.sigma_offset = sigma_offset_temp;
dcm.invmodel = model;
sts = 1;
return
