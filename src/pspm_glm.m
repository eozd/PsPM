    function [sts, glm] = pspm_glm(model, options)
% ● Description
%   pspm_glm specifies a within-subject general linear convolution model 
%   (GLM) of predicted signals and calculates amplitude estimates for these 
%   responses.
%   GLMs can be used for analysing evoked responses that follow an event 
%   with (approximately) fixed latency. This is similar to standard 
%   analysis of fMRI data. 
%   The user specifies events for different conditions. These are used to 
%   estimate the mean response amplitude per condition. These mean 
%   amplitudes can later be expored for statistical analysis, using 
%   pspm_export.
% ● Format
%   [sts, glm] = pspm_glm(model, options)
% ● Arguments
%   ┌─────model
%   ├.modelfile:  a file name for the model output
%   ├─.datafile:  a file name (single session) OR
%   │             a cell array of file names
%   ├───.timing:  a multiple condition file name (single session) OR
%   │             a cell array of multiple condition file names OR
%   │             a struct (single session) with fields .names, .onsets,
%   │             and (optional) .durations and .pmod  OR
%   │             a cell array of struct OR a struct with fields 
%   │             'markervalues' and 'names' (when model.timeunits
%   │             is set to be 'markervalues')
%   │             OR a cell array of struct
%   ├.timeunits:  one of 'seconds', 'samples', 'markers', 'markervalues'
%   ├.modelspec:  [optional] 'scr' (default); specify the model to be used.
%   │             See pspm_init, defaults.glm() which modelspecs are possible
%   │             with glm.
%   ├─.modality:  [optional] specify the data modality to be processed.
%   │             When model.modality is set to be sps, the model.channel
%   │             should be set among sps_l, sps_r, or defaultly sps. By
%   │             default, this is determined automatically from "modelspec"
%   ├───────.bf:  [optional] basis function/basis set; modality specific default
%   │             with subfields .fhandle (function handle or string) and
%   │             .args (arguments, first argument sampling interval will
%   │             be added by pspm_glm). The optional subfield .shiftbf = n
%   │             indicates that the onset of the basis function precedes
%   │             event onsets by n seconds (default: 0: used for
%   │             interpolated data channels)
%   ├──.channel:  [optional] channel number or channel type. if a channel type is
%   │             specified the LAST channel matching the given type will
%   │             be used. The rationale for this is that, in general channels
%   │             later in the channel list are preprocessed/filtered versions
%   │             of raw channels.
%   │             SPECIAL: if 'pupil' is specified the function uses the
%   │             last pupil channel returned by
%   │             <a href="matlab:help pspm_load_data">pspm_load_data</a>.
%   │             pspm_load_data loads 'pupil' channels according to a specific
%   │             precedence order described in its documentation. In a nutshell,
%   │             it prefers preprocessed channels and channels from the best eye
%   │             to other pupil channels.
%   │             SPECIAL: for the modality 'sps', the model.channel
%   │             accepts only 'sps_l', 'sps_r', or 'sps'.
%   │             DEFAULT: last channel of the specified modality
%   │             (for PSR this is 'pupil')
%   ├─────.norm:  [optional] normalise data; default 0
%   ├───.filter:  [optional] filter settings; modality specific default
%   ├──.missing:  [optional] allows to specify missing (e. g. artefact) epochs in the
%   │             data file. See pspm_get_timing for epoch definition;
%   │             specify a cell array for multiple input files. This
%   │             must always be specified in SECONDS.
%   │             Default: no missing values
%   ├─.nuisance:  [optional] Allows to specify nuisance regressors. Must be a file
%   │             name; the file is either a .txt file containing the
%   │             regressors in columns, or a .mat file containing the
%   │             regressors in a matrix variable called R. There must be
%   │             as many values for each column of R as there are data
%   │             values. SCRalyze will call these regressors R1, R2, ...
%   ├──.latency:  [optional] Specify whether latency should be 'fixed'
%   │             (default) or 'free'. In 'free' models an
%   │             additional dictionary matching algorithm will try to
%   │             estimate the best latency. Latencies will then be added
%   │             at the end of the output. In 'free' models the field
%   │             model.window is MANDATORY and single basis functions
%   │             are allowed only.
%   ├───.window:  Only required if model.latency equals 'free' and ignored
%   │             otherwise. A scalar or 2-element vector in seconds that
%   │             specifies over which time window (relative to the event
%   │             onsets specified in model.timing) the model should be
%   │             evaluated. Positive values mean that the response 
%   │             function is shifted to later time points, negative values│             
%   │             that it is shifted to earlier time points.
%   └.centering:  [optional] If set to 0 the function would not perform the
%                 mean centering of the convolved X data. For example, to
%                 invert SPS model, set centering to 0. Default: 1
%   ┌───options
%   ├──.overwrite:
%   │             [optional] logical, 0 or 1.
%   │             Define whether to overwrite existing output files or not.
%   │             Default value: determined by pspm_overwrite.
%   ├──.marker_chan_num:
%   │             [optional] marker channel number; default first marker channel.
%   └──.exclude_missing:
%                 [optional] marks trials during which NaN percentage exceeds
%                 a cutoff value. Requires two subfields:
%                 'segment_length' (in s after onset) and 'cutoff'
%                 (in % NaN per segment). Results are written into
%                 model structure as fields .stats_missing and
%                 .stats_exclude but not used further.
% ● Outputs
%   *       glm:  a structure 'glm' which is also written to file
% ● References
%   * Skin conductance response analysis
%   [1] GLM for SCR:
%       Bach DR, Flandin G, Friston KJ, Dolan RJ (2009). Time-series analysis for
%       rapid event-related skin conductance responses. Journal of Neuroscience
%       Methods, 184, 224-234.
%   [2] Canonical skin conductance response function, and GLM assumptions:
%       Bach DR, Flandin G, Friston KJ, Dolan RJ (2010). Modelling event-related
%       skin conductance responses. International Journal of Psychophysiology,
%       75, 349-356.
%   [3] Validating GLM assumptions with intraneural recordings:
%       Gerster S, Namer B, Elam M, Bach DR (2018). Testing a linear time
%       invariant model for skin conductance responses by intraneural
%       recording and stimulation. Psychophysiology, 55, e12986.
%   [4] Fine-tuning of SCR CLM:
%       Bach DR, Friston KJ, Dolan RJ (2013). An improved algorithm for
%       model-based analysis of evoked skin conductance responses. Biological
%       Psychology, 94, 490-497.
%   [5] SCR GLM validation and comparison with Ledalab:
%       Bach DR (2014).  A head-to-head comparison of SCRalyze and Ledalab, two
%       model-based methods for skin conductance analysis. Biological Psychology,
%       103, 63-88.
%   * Pupil size analysis
%   [6] GLM for fear-conditioned pupil dilation:
%       Korn CK, Staib M, Tzovara A, Castegnetti G, Bach DR (2017).
%       A pupil size response model to assess fear learning.
%       Psychophysiology, 54, 330-343.
%   * Heart rate/period analysis
%   [7] GLM for evoked heart period responses:
%       Paulus PC, Castegnetti G, & Bach DR (2016). Modeling event-related
%       heart period responses. Psychophysiology, 53, 837-846.
%   [8] GLM for fear-conditioned bradycardia:
%       Castegnetti G, Tzovara A, Staib M, Paulus PC, Hofer N, & Bach DR
%       (2016). Modelling fear-conditioned bradycardia in humans.
%       Psychophysiology, 53, 930-939.
%   [9] GLM for reward-conditioned bradycardia:
%       Xia Y, Liu H, Kälin OK, Gerster S, Bach DR (under review). Measuring
%       human Pavlovian appetitive conditioning and memory retention.
%   * Respiration analysis
%  [10] GLM for evoked respiratory responses:
%       Bach DR, Gerster S, Tzovara A, Castegnetti G (2016). A linear model
%       for event-related respiration responses. Journal of Neuroscience
%       Methods, 270, 174-155.
%  [11] GLM for fear-conditioned respiration amplitude responses:
%       Castegnetti G, Tzovara A, Staib M, Gerster S, Bach DR (2017).
%       Assessing fear learning via conditioned respiratory amplitude
%       responses. Psychophysiology, 54, 215-223.
%   * Startle eye-blink analysis
%  [12] GLM for startle eye-blink responses:
%       Khemka S, Tzovara A, Gerster S, Quednow B and Bach DR (2017)
%       Modeling Startle Eyeblink Electromyogram to Assess
%       Fear Learning. Psychophysiology
%   * Eye gaze analysis
%  [13] GLM for saccadic scanpath speed:
%       Xia Y, Melinščak F, Bach DR (2020). Saccadic scanpath length: an
%       index for human threat conditioning. Behavior Research Methods, 53,
%       1426-1439.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2008-2016 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy
% ● Developer's Notes
%   TIMING - multiple condition file(s) or struct variable(s):
%   The structure is equivalent to SPM2/5/8/12 (www.fil.ion.ucl.ac.uk/spm),
%   such that SPM files can be used.
%   The file contains the following variables:
%   - names: a cell array of string for the names of the experimental
%     conditions
%   - onsets: a cell array of number vectors for the onsets of events for
%     each experimental condition, expressed in seconds, marker numbers, or
%     samples, as specified in timeunits
%   - durations (optional, default 0): a cell array of vectors for the
%     duration of each event. You need to use 'seconds' or 'samples' as time
%     units
%   - pmod: this is used to specify regressors that specify how responses in
%     an experimental condition depend on a parameter to model the effect
%     e.g. of habituation, reaction times, or stimulus ratings.
%     pmod is a struct array corresponding to names and onsets and containing
%     the fields
%   - name: cell array of names for each parametric modulator for this
%       condition
%   - param: cell array of vectors for each parameter for this condition,
%       containing as many numbers as there are onsets
%   - poly (optional, default 1): specifies the polynomial degree
%     e.g. produce a simple multiple condition file by typing
%     names = {'condition a', 'condition b'};
%     onsets = {[1 2 3], [4 5 6]};
%     save('testfile', 'names', 'onsets');

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
glm = struct([]); % output model structure
tmp = struct([]); % temporary model structure

%% 2 Check input
% 2.1 check missing input --
if nargin < 1; errmsg = 'Nothing to do.'; warning('ID:invalid_input', errmsg); return
elseif nargin < 2; options = struct(); end

% 2.2 check model and options
[model, options] = pspm_check_model(model, options, 'glm');
if model.invalid || options.invalid
    return
end

%% 3 Check & get data
fprintf('Computing GLM: %s ...\n', model.modelfile);
fprintf('Getting data ...');
nFile = numel(model.datafile);
for iFile = 1:nFile
    % 3.3 get and filter data
    [sts, data] = pspm_load_channel(model.datafile{iFile}, model.channel, model.modality);
    if sts == -1, return; end
    y{iFile} = data.data(:);
    sr(iFile) = data.header.sr;
    fprintf('.');
    if any(strcmp(model.timeunits, {'marker', 'markers','markervalues'}))
        [sts, data] = pspm_load_channel(model.datafile{iFile}, options.marker_chan_num, 'marker');
        if sts == -1
            warning('ID:invalid_input', 'Could not load the specified markerchannel');
            return
        end
        % here, data.header.sr correponds to the time resolution of the
        % time stamps which should always be 1, but this will convert any
        % potentially deviating time stamp resolution to seconds
        events{iFile} = data.data(:) / data.header.sr;
        if strcmp(model.timeunits,'markervalues')
            model.timing{iFile}.markerinfo = data.markerinfo;
        end
    else
        events{iFile} = [];
    end
end
if nFile > 1 && any(diff(sr) > 0)
    fprintf('\nSample rate differs between sessions.\n')
else
    fprintf('\n');
end


%% 5 get basis functions
basepath = [];
if ischar(model.bf.fhandle)
    [basepath, basefn, ~] = fileparts(model.bf.fhandle);
    model.bf.fhandle = str2func(basefn);
end
if ~isempty(basepath), addpath(basepath); end
try
  td = 1/model.filter.down;
  % model.bf.X contains the function values
  % bf_x contains the timestamps
  [model.bf.X, bf_x] = feval(model.bf.fhandle, [td; model.bf.args(:)]);
  if strcmpi(model.latency, 'free') && size(model.bf.X,2) > 1
    warning('ID:invalid_input', ['With latency ''free'' multiple response ', ...
      'functions are not allowed.']); return;
  end
catch
  warning('ID:invalid_fhandle', 'Specified basis function is faulty.'); return;
end
% 5.1 set shiftbf
if bf_x(1) < 0
  model.bf.shiftbf = abs(bf_x(1));
elseif bf_x(1) > 0
  warning('ID:invalid_basis_function', 'The first basis function timestamp is larger than 0 (not allowed).'); return;
else
  model.bf.shiftbf = 0;
end

%% 6 remove path & clear local variables
if ~isempty(basepath), rmpath(basepath); end
clear basepath basefn baseext


%% 7 check regressor files
[sts, multi] = pspm_get_timing('onsets', model.timing, model.timeunits);

if strcmpi(model.timeunits,'markervalues')
  nr_multi = numel(multi);
  for n_m = 1:nr_multi
    model.timing{n_m} = multi(n_m);
  end
  model.timeunits = 'markers';
end

%% 8 check & get missing values
for iSn = 1:nFile
    if isempty(model.missing{iSn})
      sts = 1; missing{iSn} = [];
    else
      [sts, missing{iSn}] = pspm_get_timing('missing', model.missing{iSn}, 'seconds');
    end
end

%% 9 check and get nuisance regressors
if ~isfield(model, 'nuisance')
  model.nuisance = cell(nFile, 1);
  for iSn = 1:nFile
    R{iSn} = [];
  end
  nR = 0;
else
  if ischar(model.nuisance)
    model.nuisance = {model.nuisance};
  elseif ~iscell(model.nuisance)
    warning('ID:invalid_input', 'Nuisance regressors must be specified as char or cell of file names.'); return;
  end
  if numel(model.nuisance) ~= nFile
    warning('ID:number_of_elements_dont_match',...
      'Same number of data files and nuisance regressor files is needed.'); return;
  end
  for iSn = 1:nFile
    if isempty(model.nuisance{iSn})
      R{iSn} = [];
    else
      try
        indata = load(model.nuisance{iSn});
        if isstruct(indata)
          R{iSn} = indata.R;
        else
          R{iSn} = indata;
        end
      catch
        warning('ID:invalid_file_type',...
          'Unacceptable file format or non-existing file for nuisance file in session %01.0f', iSn); return;
      end
      if size(R{iSn}, 1) ~= numel(y{iSn})
        warning('ID:number_of_elements_dont_match',...
          'Nuisance regressors for session %01.0f must have same number of data points as observed data.', iSn); return;
      end
    end
    if iSn == 1
      nR = size(R{iSn}, 2);
    elseif size(R{iSn}, 2) ~= nR
      warning('ID:number_of_elements_dont_match',...
        'Nuisance regressors for all sessions must have the same number of columns'); return;
    end
  end
end

%% 10 collect output model information
fprintf('Preparing & inverting model ... ');
glm(1).glmfile    = model.modelfile; % this field will be removed in the future so don't use any more
glm.modelfile     = model.modelfile;
glm.input         = model;
glm.input.options = options;
glm.bf            = model.bf;
glm.bf.bfno       = size(glm.bf.X, 2);
% 10.1 prepare timing variables --
onsets = {};
names = {};
durations = {};
pmod = {};
% 10.2 clear local variables --
clear sts iFile modno


%% 11 Prepare data & regressors
Y=[];
M=[];
tmp=struct([]);
for iSn = 1:nFile
  % prepare (filter & downsample) data
  model.filter.sr = sr(iSn);
  % find NaN values
  oldy = y{iSn};
  % find which fields are nan after interoplation and prepdata
  nan_idx = find(isnan(oldy));
  % interpolate y data
  [sts, oldy] = pspm_interpolate(oldy, struct('extrapolate', 1));
  if sts ~= 1, warning('ID:invalid_input', 'Failed to interpolate y data'); return; end
  % filter data
  [sts, newy, newsr] = pspm_prepdata(oldy, model.filter);
  if sts ~= 1, warning('ID:invalid_input', 'Failed to filter data'); return; end
  % if has been downsampled adjust nan_idx
  if numel(oldy) ~= numel(newy)
    nan_idx = round(nan_idx*(model.filter.down/model.filter.sr));
    % sanitize ends
    nan_idx(nan_idx < 1) = 1;
    nan_idx(nan_idx > numel(newy)) = numel(newy);
    % find duplicates
    dupli = diff(nan_idx) == 0;
    % remove duplicates
    nan_idx(dupli) = [];
  end
  % concatenate data
  Y=[Y; NaN(newsr * model.bf.shiftbf, 1); newy(:)];
  % get duration of single sessions
  tmp(1).snduration(iSn) = numel(newy) + newsr * model.bf.shiftbf;
  % process missing values
  newmissing = zeros(size(newy(:)));
  if ~isempty(missing{iSn})
    missingtimes = pspm_time2index(missing{iSn},newsr,length(newmissing));
    for iMs = 1:size(missingtimes, 1)
      newmissing(missingtimes(iMs, 1):missingtimes(iMs, 2)) = 1;
    end
  end
  % copy NaN in y data should be missing
  newmissing(nan_idx) = 1;
  M = [M; ones(newsr * model.bf.shiftbf, 1); newmissing];
  % convert regressor information to samples
  if ~isempty(multi)
      if strcmpi(model.timeunits, 'samples')
          sn_sr = newsr/sr(iSn);
      else
          sn_sr = newsr;
      end
      [msts, newonsets, newdurations] = pspm_multi2index(model.timeunits, ...
          multi(iSn), sn_sr, tmp.snduration(iSn), events(iSn));
      if msts < 1, return; end
      for n = 1:numel(multi(iSn).names)
           if iSn == 1
              names{n} = multi(1).names{n};
              onsets{n} = newonsets{n}{1}(:);
              durations{n} = newdurations{n}{1}(:);
              if isfield(multi, 'pmod') && (numel(multi(iSn).pmod) >= n)
                  for p = 1:numel(multi(iSn).pmod(n).param)
                      pmod(n).param{p} = multi(iSn).pmod(n).param{p}(:);
                  end
                  pmod(n).name = multi(1).pmod(n).name;
              end
          else
               % shift conditions for sessions not being the first
               % (tmp.snduration is in samples)
              newonsets{n}{1}(:) = newonsets{n}{1}(:) + sum(tmp.snduration(1:(iSn - 1)));
              % then insert
              onsets{n} = [onsets{n}; newonsets{n}{1}(:)];
              durations{n} = [durations{n}; newdurations{n}{1}(:)];
              if isfield(multi, 'pmod') && (numel(multi(iSn).pmod) >= n)
                  for p = 1:numel(multi(iSn).pmod(n).param)
                      pmod(n).param{p} = [pmod(n).param{p}; multi(iSn).pmod(n).param{p}(:)];
                  end
              end
          end
      end
  else
      names = {};
      onsets = {};
      durations = {};
  end
end
% 11.1 normalise if desired --
if model.norm
  % ignore nan values
  no_nan = ~isnan(Y);
  % normalise
  Y = (Y - mean(Y(no_nan)))/std(Y(no_nan));
end
Y = Y(:);
% 11.2 collect information into tmp --
tmp.length=numel(Y);
% 11.3 scale pmods before orthogonalisation --
tmp.pmodno=zeros(numel(names), 1);
if exist('pmod', 'var')
  for n=1:numel(pmod)
    if ~isempty(pmod(n).param)
      for p=1:numel(pmod(n).param)
        % mean center and scale pmods
        try
          tmp.pmodscale(n, p) = std(pmod(n).param{p});
        catch
          tmp.pmodscale(n, p) = 1;
        end
        pmod(n).param{p}=(pmod(n).param{p}-mean(pmod(n).param{p}))/tmp.pmodscale(n, p);
      end
      % register number of pmods
      tmp.pmodno(n)=p;
    end
  end
else
  pmod = [];
end

%% 12 collect data & regressors for output model
glm.input.data    = y;
glm.input.sr      = sr;
glm.input.events  = events;
glm.Y             = Y;
glm.M             = M; % set to 1 if data is missing, otherwise set to 0
glm.infos.sr      = newsr;
glm.infos.duration     = numel(glm.Y)/glm.infos.sr;
glm.infos.durationinfo = 'duration in seconds';
glm.timing.multi      = multi;
glm.timing.names      = names;
glm.timing.onsets     = onsets;
glm.timing.durations  = durations;
glm.timing.pmod       = pmod;
glm.modality          = model.modality;
glm.modelspec         = model.modelspec;
glm.modeltype         = 'glm';
% 12.1 clear local variables --
clear iSn iMs ynew newonsets newdurations newmissing missingtimes


%% 13 create temporary onset functions
% 13.1 cycle through conditions --
for iCond = 1:numel(names)
  tmp.regscale{iCond} = 1;
  % first process event onset, then pmod
  if strcmpi(model.latency, 'free')
      offset = round(model.window(1) * glm.infos.sr);
      model.infos.offset = offset;
  else
      offset = 0;
  end
  tmp.onsets = onsets{iCond} - offset;
  clear offset
  tmp.durations = durations{iCond};
  if sum(tmp.durations) > 0 && ~strcmpi(model.modality, 'sps')
      warning(sprintf('Non-zero durations in condition %s detected. This is discouraged for modality %s.', ...
          names{iCond}, model.modality));
  end
  % if file starts with first event, set that onset to 1 instead of 0
  if any(tmp.onsets == 0)
    tmp.onsets(tmp.onsets == 0) = 1;
  end
  col=1;
  tmp.colnum=1+tmp.pmodno(iCond);
  tmp.X{iCond}=zeros(tmp.length, tmp.colnum);
  for k = 1:numel(tmp.onsets)
    tmp.X{iCond}(tmp.onsets(k):(tmp.onsets(k) + tmp.durations(k)), col)=1;
  end
  tmp.name{iCond, col}=names{iCond};
  col=col+1;
  if exist('pmod') && ~isempty(pmod)
    if iCond<=numel(pmod)
      if ~isempty(pmod(iCond).param)
        for p=1:numel(pmod(iCond).param)
          for k = 1:numel(tmp.onsets)
            tmp.X{iCond}(tmp.onsets(k):(tmp.onsets(k) + tmp.durations(k)), col)=pmod(iCond).param{p}(k);
          end
          tmp.name{iCond, col}=[names{iCond}, ' x ', pmod(iCond).name{p}];
          tmp.regscale{iCond}(col) = tmp.pmodscale(iCond, col - 1);
          col=col+1;
        end
      end
    end
    % orthogonalize pmods before convolution
    foo = spm_orth(tmp.X{iCond});
    % catch zero matrices (unclear yet why this happens, 01-Apr-2012)
    if all(all(foo==0))
      warning('the pmods in condition %i have not been orthogonalized (because spm_orth returned a zero matrix)', iCond)
    else
      tmp.X{iCond} = foo;
    end
  end
end


%% 14 create design matrix
% 14.1 create design matrix filter --
Xfilter = model.filter;
Xfilter.sr = glm.infos.sr;
Xfilter.down = 'none'; % turn off downsampling
Xfilter.lpfreq = NaN; % turn off low pass filter
% 14.2 convolve with basis functions --
snoffsets = cumsum(tmp.snduration);
snonsets  = [1, snoffsets(1:end) + 1];
tmp.XC = cell(1,numel(names));
tmp.regscalec = cell(1,numel(names));
for iCond = 1:numel(names)
  tmp.XC{iCond} = [];
  tmp.regscalec{iCond} = [];
  iXCcol = 1;
  for iXcol = 1:size(tmp.X{iCond}, 2)
    for iBf = 1:glm.bf.bfno
      % process each session individually
      for iSn = 1:numel(tmp.snduration)
        % convolve
        tmp.col{iSn, 1} = conv(tmp.X{iCond}(snonsets(iSn):snoffsets(iSn), iXcol), glm.bf.X(:,iBf));
        % filter design matrix w/o downsampling
        [sts,  tmp.col{iSn, 1}, ~] = pspm_prepdata(tmp.col{iSn, 1}, Xfilter);
        if sts ~= 1, glm = struct([]);warning('ID:invalid_input', 'Failed to filter data');return; end
        % cut away tail
        tmp.col{iSn, 1}((tmp.snduration(iSn) + 1):end) = [];
      end
      tmp.XC{iCond}(:, iXCcol) = cell2mat(tmp.col);
      tmp.namec{iCond}{iXCcol, 1} = [tmp.name{iCond, iXcol}, ', bf ', num2str(iBf)];
      tmp.regscalec{iCond} = [tmp.regscalec{iCond}, tmp.regscale{iCond}(iXcol)];
      iXCcol = iXCcol + 1;
      % clear local variable
      tmp.col = {};
    end
  end
  % 14.3 mean centering --
  if model.centering
    for iXCol=1:size(tmp.XC{iCond},2)
      tmp.XC{iCond}(:,iXCol) = tmp.XC{iCond}(:,iXCol) - mean(tmp.XC{iCond}(:,iXCol));
    end
  end

  % orthogonalize after convolution if there is more than one column per
  % condition
  if size(tmp.XC{iCond}, 2) > 1 && ~(all(tmp.XC{iCond}(:)==0))
    foo=spm_orth(tmp.XC{iCond});
    % catch zero matrices (unclear yet why this happens, 01-Apr-2012)
    if ~(all(foo(:) == 0))
      tmp.XC{iCond} = foo;
    else
      warning('\nOrthogonalisation error in event type #%02.0f\nCorrelation coefficients are: ', iCond);
      cc = corrcoef(tmp.XC{iCond});
      for k = 2:size(cc, 1)
        fprintf('%0.2f, ', cc(1, k));
      end
      fprintf('\n');
    end
  end
end
% 14.4 define model --
glm.X = cell2mat(tmp.XC);
glm.regscale = cell2mat(tmp.regscalec);
glm.names = cell(numel(names), 1);
r=1;
for iCond = 1:numel(names)
  n = numel(tmp.namec{iCond});
  glm.names(r:(r+n-1), 1) = tmp.namec{iCond};
  r = r + n;
end
% 14.5 add nuisance regressors --
for iSn = 1:numel(model.datafile)
  Rf{iSn} = [];
  model.filter.sr = sr(iSn);
  for iR = 1:nR
    [sts, Rf{iSn}(:, iR), ~]  = pspm_prepdata(R{iSn}(:, iR), model.filter);
    if sts ~= 1,warning('ID:invalid_input', 'Failed to filter data'); return; end
  end
  if (model.bf.shiftbf ~= 0) && ~isempty(Rf{iSn})
    Rf{iSn} = [ NaN(model.bf.shiftbf*model.filter.down, nR); Rf{iSn}];
  end
end
Rf = cell2mat(Rf(:));
n = size(glm.names, 1);
for iR = 1:nR
  glm.names{n+iR, 1} = sprintf('R%01.0f', iR);
end
glm.X = [glm.X, Rf];
glm.regscale((end+1):(end+nR)) = 1;
% 14.6 add constant(s) --
r=1;
n = size(glm.names, 1);
for iSn = 1:numel(model.datafile)
  glm.X(r:(r+tmp.snduration(iSn)-1), end+1)=1;
  glm.names{n+iSn, 1} = ['Constant ', num2str(iSn)];
  r = r + tmp.snduration(iSn);
end
glm.interceptno = iSn;
glm.regscale((end+1):(end+iSn)) = 1;
% 14.7 delete missing epochs and prepare output --
% user output on missing values (not accounting for those introduced by
% shiftbf parameter)
perc_missing = (sum(glm.M)  - newsr * model.bf.shiftbf)/length(glm.M);
if perc_missing >= 0.1
  if sr == Xfilter.sr
    warning('ID:invalid_input', ...
      ['More than 10%% of input data was filtered out due to missing epochs. ',...
      'Results may be inaccurate.']);
  else
    warning('ID:invalid_input', ...
      ['More than 10%% of input data was filtered out due to missing epochs, ',...
      'which is possibly caused by downsampling. Results may be inaccurate.']);
  end
end
glm.YM = glm.Y;
glm.YM(glm.M(1:length(glm.YM))==1) = [];
glm.Y(glm.M(1:length(glm.Y))==1) = NaN;
glm.XM = glm.X;
glm.XM(glm.M(1:length(glm.XM))==1, :) = [];
glm.X(glm.M(1:length(glm.X))==1, :) = NaN;
glm.Yhat    = NaN(size(Y));
% 14.8 clear local variables --
clear tmp Xfilter r iSn n iCond

%% 15 invert model & save
% this is where the beef is
if strcmpi(model.latency, 'free')
  % prepare dictionary onsets and new design matrix
  D_on = eye(ceil(diff(model.window)*glm.infos.sr));
  XMnew = NaN(size(glm.XM));
  % go through columns
  ncol = size(glm.XM, 2) - nR - glm.interceptno;
  glm.names(2 * ncol + (1:glm.interceptno)) = glm.names(ncol + (1:glm.interceptno));
  for iCol = 1:ncol
    % specify dictionary
    for iD = 1:size(D_on, 2)
      foo = conv(D_on(:, iD), glm.XM(:, iCol));
      D(iD, :) = foo(1:size(glm.XM, 1));
    end
    % obtain inner product and select max
    a = D * glm.YM;
    [~, ind] = max(a);
    lat(iCol) = (ind+model.infos.offset)/glm.infos.sr;
    XMnew(:, iCol) = D(ind, :);
    % create names
    glm.names{iCol + ncol} = [glm.names{iCol}, ' Latency'];
  end
  % add nuisance regressors (if any) and session intercepts
  XMnew(:, (iCol + 1):end) = glm.XM(:, (iCol + 1):end);
  % replace design matrix
  glm.XMold = glm.XM;
  glm.XM = XMnew;
end
% 15.1 estimate amplitudes --
glm.stats = pinv(glm.XM)*glm.YM;           % parameter estimates
glm.Yhat(glm.M==0) = glm.XM*glm.stats;     % predicted response
glm.e    = glm.Y - glm.Yhat;               % residual error
glm.EV   = 1 - (var(glm.e)/var(glm.YM));   % explained variance proportion

%% 16 rescale pmod parameter estimates & design matrix
glm.X = glm.X .* repmat(glm.regscale, size(glm.X, 1), 1);
glm.XM = glm.XM .* repmat(glm.regscale, size(glm.XM, 1), 1);
glm.stats = glm.stats ./ transpose(glm.regscale);

if strcmpi(model.latency, 'free')
  % add latency parameters
  glm.stats = [glm.stats(:); lat(:)];
end

% call pspm_extract_segments if options.exclude_misssing is set
% verify that both fields are set
% when pspm_extract_segments returns set fields in glm
% glm.stats_missing holds the percentage of NaNs per condition
% glm.stats_exclude holds boolean for each condition to indicate if the
% cutoff holds
% glm.stats_exclude_names holds the names of the conditions to be excluded

if isfield(options,'exclude_missing')
  if options.exclude_missing.segment_length > 0
    [sts,segments] = pspm_extract_segments('model', glm, ...
      struct('length', options.exclude_missing.segment_length));
    if sts == -1
      warning('ID:invalid_input', 'call of pspm_extract_segments failed');
      return;
    end
    segments = segments.segments;
    nan_percentages = cellfun(@(x) x.total_nan_percent,segments, ...
      'un',0);
    glm.stats_missing = cell2mat(nan_percentages);
    glm.stats_exclude = glm.stats_missing > options.exclude_missing.cutoff;
    glm.stats_exclude_names = cellfun(@(x) x.name,segments,'un',0);
    glm.stats_exclude_names = glm.stats_exclude_names(glm.stats_exclude);
  end
end

%% 17 save data
% 17.1 overwrite is determined in load1 --
glm.datetime = datetime;
savedata = struct('glm', glm);
[sts, data_load1, mdltype_load1] = pspm_load1(model.modelfile, 'save', savedata, options);

