function tam = pspm_tam(model, options)
% ● Description
%   TAM stands for Trial Average Model and allows to fit models on trial-averaged data.
%   pspm_tam starts by extracting and averaging signal segments of length `model.window`
%   from each data file individually, then averages these mean segments and finally fits
%   an LTI model.
% ● Arguments
%   ┌───────model
%   ├──.modelfile:  a file name for the model output
%   ├───.datafile:  a file name (single session) OR
%   │               a cell array of file names
%   ├─────.timing:  a multiple condition file name (single session) OR
%   │               a cell array of multiple condition file names OR
%   │               a struct (single session) with fields .names, .onsets,
%   │               and (optional) .durations OR
%   │               a cell array of struct OR
%   │               a struct with fields 'markerinfos', 'markervalues',
%   │               'names' OR
%   │               a cell array of struct
%   ├──.timeunits:  a char array equal to 'seconds', 'samples' or 'markers'
%   ├─────.window:  a scalar in model.timeunits as unit that specifies
%   │               over which time window (starting with the events specified
%   │               in model.timing) the model should be evaluated.
%   │               For model.timeunits == 'markers', the unit of the window
%   │               should be specified in 'seconds'.
%   ├──.modelspec:  [optional] 'dilation' (default); specify the model to be used.
%   │               See pspm_init, defaults.tam() which modelspecs are possible
%   │               with glm.
%   ├───.modality:  [optional] specify the data modality to be processed. By
%   │               default, this is determined automatically from "modelspec"
%   ├─────────.bf:  [optional] basis function/basis set with required subfields (see below)
%   ├─────────.if:  [optional, struct] input function (function which will be fitted)
%   ├────.channel:  [optional] allows to specify channel number or channel type.
%   │               If there is only one element specified, this element
%   │               will be applied to each datafile.
%   │               DEFAULT: last channel of 'pupil' data type
%   ├───────.norm:  [optional] allows to specify whether data should be zscored or not
%   │               DEFAULT: 1
%   ├─────.filter:  [optional] filter settings; modality specific default
%   ├───.baseline:  [optional] allows to specify a baseline in 'seconds' which is
%   │               applied to the data before fitting the model. It has to
%   │               be positive and smaller than model.window. If no baseline
%   │               specified, data will be baselined wrt. the first datapoint.
%   │               DEFAULT: 0
%   ├.std_exp_cond: [optional] allows to specify the standard experimental condition
%   │               as a string or an index in timing.names.
%   │               if specified this experimental condition will be
%   │               substracted from all the other conditions.
%   │               DEFAULT: 'none'
%   └───.norm_max:  [optional] set the first peak at 1 before model fitting.
%                   DEFAULT: 0 (not normalize)
%   ┌────model.bf
%   ├────.fhandle:  function handle or string
%   └───────.args:  arguments; the first two arguments (time resolution and duration)
%                   will be added by pspm_pupil_model.
%                   DEFAULT: specified by the modality
%   ┌────model.if
%   ├────.fhandle:  function handle or string
%   ├────────.arg:  initial arguments, numeric array
%   ├─────────.lb:  lower bounds, numeric array of the same size as .arg
%   └─────────.ub:  upper bounds, numeric array of the same size as .arg
%   ┌─────options
%   ├.marker_chan:  marker channel number
%   │               DEFAULT: 'marker' (i.e. last marker channel)
%   └──.overwrite:  (optional) overwrite existing model output;
%                   [logical] (0 or 1)
%                   Define whether to overwrite existing output files or not.
%                   Default value: determined by pspm_overwrite.
% ● Outputs
%   * tam: a structure 'tam' which is also written to file
% ● Reference
%   [1] Model development:
%       Korn CW & Bach DR (2016). A solid frame for the window on cognition:
%       Modelling event-related pupil responses. Journal of Vision, 16:28,
%       1-6. https://doi.org/10.1167/16.3.28
%   [2] Model application:
%       Abivardi A, Korn CW, Rojkov I, Gerster S, Hurlemann R, Bach DR
%       (2023). Acceleration of inferred neural responses to oddball
%       targets in an individual with bilateral amygdala lesion compared to
%       healthy controls. Scientific Reports, 13, 41357.
%       https://doi.org/10.1038/s41598-023-41357-1
% ● History
%   Introduced In PsPM 4.2
%   Written in 2020 by Ivan Rojkov (University of Zurich)
%   Maintained in 2022 by Teddy
% ● Developer's Notes
%   The fitting process is a residual least square minimisation where the
%   predicted value is calculated as following:
%     Y_predicted = input_function (*) basis_function
%   with (*) represents a convolution. Only parameters of the input
%   function are optimised.
%   ---
%   TIMING - multiple condition file(s) or struct variable(s):
%    The structure is equivalent to SPM2/5/8/12 (www.fil.ion.ucl.ac.uk/spm),
%    such that SPM files can be used.
%    The file contains the following variables:
%    - names: a cell array of string for the names of the experimental
%      conditions
%    - onsets: a cell array of number vectors for the onsets of events for
%      each experimental condition, expressed in seconds, marker numbers, or
%      samples, as specified in timeunits
%    - durations (optional, default 0): a cell array of vectors for the
%      duration of each event. You need to use 'seconds' or 'samples' as time
%      units
%    e.g. produce a simple multiple condition file by typing
%      names = {'condition a', 'condition b'};
%      onsets = {[1 2 3], [4 5 6]};
%      save('testfilcircle_degreee', 'names', 'onsets');


%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
tam = struct();

%% 2 Check input
% 2.1 check missing input --
if nargin < 1; errmsg = 'Nothing to do.'; warning('ID:invalid_input', errmsg); return
elseif nargin < 2; options = struct(); end

% 2.2 check model and options
[model, options] = pspm_check_model(model, options, 'tam');
if model.invalid || options.invalid
    return
end

%% Loading files

fprintf('Computing Trial Average Model: %s \n', model.modelfile);

n_exp_cond = numel(model.timing{1}.names);      % number of experimental conditions
n_file = numel(model.datafile);                 % number of files

% Loading data and sr
fprintf('Getting data .');
for iFile = 1:n_file
    [sts, data] = pspm_load_channel(model.datafile{iFile}, model.channel, model.modality);
    if sts < 1, warning('ID:load_data_fail', 'Problem encountered while loading data.'); return; end

    % Filling up the data and the sampling rates
    y{iFile} = data.data(:);
    sr(iFile) = data.header.sr;
    fprintf('.');

    % If the timeunits is markers
    if strcmpi(model.timeunits, 'markers')
        [sts, data] = pspm_load_channel(model.datafile{iFile}, options.marker_chan{iFile}, 'marker');
        if sts < 1
            warning('ID:invalid_input','Could not load the specified marker channel.');
            return;
        end
        markers{iFile} = data.data;
    end

    fprintf('.');
end

% Old sampling rate
oldsr = sr;

% Checking if the sampling rate is the same for all samples.
if n_file > 1 && any(diff(sr) > 0)
  if model.filter.down > min(sr)) ||...                                    % if filter.down is less than the minimal sr
      strcmpi(model.filter.down,'none')                                    % if filter.down is none
    model.filter.down = min(sr);
    fprintf('\nSampling rate differs between sessions. Data will be downsampled.\n')
  end
else
  fprintf('\n');
end

%%  Zscoring the data
if model.norm
  fprintf('Zscoring ...\n')
  n_file = numel(model.datafile);
  for iFile = 1:n_file
    % NANZSCORE found in src/VBA/stats&plots
    [y{iFile},~,~] = nannorm(y{iFile});
  end
end

%%  Extracting segments
fprintf('Extracting segments ...\n')

% temporary structure which is deleted after extracting segments
extrsgopt.timeunits = model.timeunits;
extrsgopt.length = model.window;       % segments of 'model.window' time unit long
extrsgopt.plot = 0;                    % do not plot mean value and std

for k=1:n_file
  if strcmpi(model.timeunits, 'markers')
    extrsgopt.marker_chan = markers(k);
  end

  [lsts, s] = pspm_extract_segments('manual', y(k), sr(k), model.timing(k), extrsgopt);
  if lsts<1, warning('ID:error_extract_segments','An error occured in pspm_extract_segments.'); return; end

  for i=1:n_exp_cond
    tmp_data.mean = s.segments{i,1}.mean;
    tmp_data.std = s.segments{i,1}.std;
    tmp_data.sem = s.segments{i,1}.sem;
    tmp_data.t = s.segments{i,1}.t;
    % a cell array of struct and of size (n_file x n_exp_cond) where each
    % line correspond to a given file and each column to an
    % experimental condition
    segm{k,i} = tmp_data;
    clear tmp_data
  end

end
clear extrsg tmp_data s lsts

%% Downsample the data
% if a filter was specified or if the data differ in sr
fprintf('Filtering ...\n')
for i = 1:n_exp_cond
    for k = 1:n_file

        model.filter.sr = sr(k);

        [lsts, segm{k,i}, ~] = structfun(@(x) pspm_prepdata(x, model.filter),segm{k,i},'UniformOutput',false);
        if any(structfun(@(x) x<1,lsts)), warning('ID:error_prepdata','An error occured in pspm_prepdata.'); return; end

        clear new_sr lsts
    end
end

% changing the sampling rate
sr = model.filter.down*ones(size(sr));


%% Determining mean values
fprintf('Preparing for fitting ...\n')

baseline_index = floor(sr(1)*model.baseline)+1;

if exist('std_exp_cond','var')
  tmp_data = [segm{:,std_exp_cond.ind}];

  std_exp_cond.data = nanmean([tmp_data.mean],2);
  std_exp_cond.std = nanmean([tmp_data.std],2);
  std_exp_cond.sem = nanmean([tmp_data.sem],2);
end

for i=1:n_exp_cond

  tmp_data = [segm{:,i}];

  tmp_data_new.data = nanmean([tmp_data.mean],2);
  tmp_data_new.std = nanmean([tmp_data.std],2);
  tmp_data_new.sem = nanmean([tmp_data.sem],2);
  tmp_data_new.t = nanmean([tmp_data.t],2);

  % Subtracting the standard experimental condition
  if exist('std_exp_cond','var') && i~=std_exp_cond.ind
    tmp_data_new.data = tmp_data_new.data - std_exp_cond.data;
    tmp_data_new.std = tmp_data_new.std + std_exp_cond.std;      % the error adds up
    tmp_data_new.sem = tmp_data_new.sem + std_exp_cond.sem;      % the error adds up
  end

  % Baselining data
  tmp_data_new.data = tmp_data_new.data - tmp_data_new.data(baseline_index);

  % Dividing by the max value
  if model.norm_max
    [tmp_max,tmp_max_ind] = max(tmp_data_new.data);
    tmp_data_new.data = tmp_data_new.data/tmp_max;
    tmp_data_new.std = tmp_data_new.std + tmp_data_new.std(tmp_max_ind); % the error adds up
    tmp_data_new.sem = tmp_data_new.sem + tmp_data_new.sem(tmp_max_ind); % the error adds up
  end

  mean{1,i} = tmp_data_new;

  clear tmp_data tmp_data_new tmp_max tmp_max_ind
end

%% Fitting the model
fprintf('Fitting ...\n')

for i=1:n_exp_cond
  raw_y = mean{1,i}.data;

  n = model.window;
  td = n / length(raw_y);

  % Extending the size of the data vector in order to do the fitting,
  % because if size(raw_y)=[n 1], the convolution would produce a vector of
  % size [2*n-1 1] so we have to extend the size of the data vector.
  conv_y = [ raw_y ; zeros(size(raw_y,1)-1,size(raw_y,2))];

  % Predicted signal (LTI model)
  predicted_y = @(x) conv(model.if.fhandle([td,n,x]),model.bf.fhandle([td, n, model.bf.args])).';

  % Residual Sum Square (RSS) calculation (basically error btw conv_y and predicted_y)
  RSS = @(x) norm(conv_y - predicted_y(x), 2)^2;

  % Minimization of RSS
  warning off all
  [~, fitted{1,i}.optargs, fitted{1,i}.fval, sts, fmincon_output] = ...
    evalc('fmincon(RSS,model.if.args,[],[],[],[],model.if.lb,model.if.ub)');
  warning on all
  if sts == 0
    warning('ID:fmincon',['During the fitting process, ''fmincon'' exceeded', ...
      ' the number of iterations or the number of function evaluations.', ...
      ' Try to change the initial arguments and bounds to improve the fitting.'])
  elseif sts == -1
    warning('ID:fmincon',['During the fitting process, ''fmincon''', ...
      ' was terminated by an output function or a plot.']);
    fprintf('Here is the output of fmincon:\n');
    disp(fmincon_output);
  elseif sts == -2
    warning('ID:fmincon',['During the fitting process, ''fmincon''', ...
      ' hasn''t found any feasible point.']);
    fprintf('Here is the output of fmincon:\n');
    disp(fmincon_output);
  end

  % Calculating the predicted signal that will be included in the output structure
  fitted{1,i}.data = predicted_y(fitted{1,i}.optargs);
  % Cutting away tail
  tmp_y = mean{1,i}.data;
  fitted{1,i}.data(size(tmp_y,1)+1:end) = [];

end

%% Saving model
fprintf('Saving model ...\n');

% Collecting input model information
tam.modelfile     = model.modelfile;
tam.input         = model;
tam.input.options = options;
tam.input.sr      = num2cell(oldsr(:).');
tam.bf            = model.bf;
tam.if            = model.if;

% Collecting fitting data
tmp_mean = [mean{1,:}];
tam.data.Y        = {tmp_mean.data};
tam.data.X        = {tmp_mean.t};
tam.data.std      = {tmp_mean.std};
tam.data.sem      = {tmp_mean.sem};
tam.data.sr       = num2cell(sr(:).');
tam.data.filtered = filtered;
tam.data.normd  = model.norm;
tam.data.norm     = model.norm;

if exist('std_exp_cond','var')
  tam.data.std_exp_cond.name  = std_exp_cond.name;
  tam.data.std_exp_cond.ind   = std_exp_cond.ind;
else
  tam.data.std_exp_cond       = 'none';
end

% Collecting fits
tmp_fitted = [fitted{1,:}];
tam.fit.Y         = {tmp_fitted.data};
tam.fit.X         = {tmp_mean.t};
tam.fit.rss       = {tmp_fitted.fval};  % RSS (residual sum square)
tam.fit.args      = {tmp_fitted.optargs};
tam.fit.sr        = num2cell(sr(:).');

tam.infos.duration     = model.window;
tam.infos.durationinfo = 'duration in seconds';

tam.timing        = model.timing;

tam.modeltype     = 'tam';
tam.modality      = model.modality;

tam.names         = model.timing{1}.names(:).';

% Saving structure
savedata = struct('tam', tam);
[sts, ~ , ~ ] = pspm_load1(model.modelfile, 'save', savedata, options);
if sts == -1
  warning('ID:invalid_input', 'call of pspm_load1 failed');
  return;
end
%% User output
fprintf('done. \n');
sts = 1;
return
