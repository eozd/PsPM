function [model, options] = pspm_check_model(model, options, modeltype)
% ● Definition
%   pspm_check_model automatically determine the fields of the struct model
%   for the corresponding function. It also checks the options structure
%   and uses it to determine whether overwriting of the model file is
%   allowed
% ● Format
%   model = pspm_check_model(model, modeltype)
% ● Arguments
%   ┌─────model
%   ├─.datafile : Values (any of the following).
%   │             A file name (single session);
%   │             A cell array of file names (multiple sessions, not allowed for SF).
%   ├.modelfile : A file name for the model output.
%   ├.timeunits : A string.
%   │             [for GLM, TAM] can be either 'seconds', 'samples', 'markers', or
%   │                            'markervalues'.
%   │             [for SF] can be either 'seconds', 'samples', 'markers', or 'whole'.
%   ├───.timing :
%   │             [timing for DCM]
%   │               Acceptable values (any of the following):
%   │                (1) A file name/cell array of events (single session);
%   │                (2) A cell array of file names/cell arrays.
%   │               Descriptions:
%   │                 When specifying file names, each file must be a *.mat file that
%   │                   contain a cell variable called 'events'.
%   │                 Each cell should contain either one column (fixed response) or two
%   │                   columns (flexible response).
%   │                 All matrices in the array need to have the same number of rows,
%   │                   i.e. the event structure must be the same for every trial. If
%   │                   this is not the case, include `dummy` events with negative onsets.
%   │             [timing for GLM and TAM]
%   │               Acceptable values (any of the following):
%   │                 (1) A multiple condition file name (single session);
%   │                 (2) A cell array of multiple condition file names;
%   │                 (3) A struct (single session) or a cell array of struct (multiple
%   │                   sessions), where each struct show have the following fields:
%   │                     (3a) .names (mandatory)
%   │                     (3b) .onsets (mandatory)
%   │                     (3c) .durations (optional)
%   │                     (3d) .pmod (optional)
%   │                 (4) A struct (single session) or a cell array of struct (multiple
%   │                   sessions), if model.timeunits is set as 'markervalues', where each
%   │                   struct show have the following fields:
%   │                     (4a) .markervalues
%   │                     (4b) .names
%   │             [timing for SF] (ignored if .timeunits == 'whole' (SF)):
%   │               Acceptable values (any of the following):
%   │                 (1) A SPM style onset file with two following event types:
%   │                     onset
%   │                     offset (other names are ignored)
%   │                 (2) A .mat file with a variable 'epochs', see below
%   │                 (3) A two-column text file with on/offsets
%   │                 (4) e x 2 array of epoch on- and offsets, with e: number of epochs
%   │                     or cell array of any of these, for multiple files.
%   ├──.missing : [optional] allows to specify missing (e. g. artefact) epochs in the
%   │             data file. See pspm_get_timing for epoch definition; specify a cell
%   │             array for multiple input files (not allowed for SF). This must always be specified in SECONDS.
%   │             Default: no missing values
%   ├──.channel : [optional] channel number (or, for GLM, channel type). If a channel type
%   │             is specified the LAST channel matching the given type will be used.
%   │             The rationale for this is that, in general channels later in the channel
%   │             list are preprocessed/filtered versions of raw channels.
%   │             SPECIAL: if 'pupil' is specified the function uses the last pupil channel
%   │             returned by <a href="matlab:help pspm_load_data">pspm_load_data</a>.
%   │             pspm_load_data loads 'pupil' channels according to a specific precedence
%   │             order described in its documentation.
%   │             In a nutshell, it prefers preprocessed channels and channels from the
%   │             best eye to other pupil channels.
%   │             SPECIAL: for the modality 'sps', the model.channel accepts only 'sps_l',
%   │             'sps_r', or 'sps'.
%   │             DEFAULT: last channel of the specified modality for GLM; 'scr' for DCM
%   │             and SF.
%   ├─────.norm : [optional] normalise data; default 0
%   ├───.filter : [optional] filter settings; modality specific default
%   ├──.latency : [optional, GLM (modeltype) only] allows to specify whether latency
%   │             should be 'fixed'. (default) or should be 'free'. In 'free' models, an
%   │             additional dictionary matching algorithm will try to estimate the best
%   │             latency. Latencies will then be added at the end of the output. In
%   │             'free' models the field model.window is MANDATORY and single basis
%   │             functions are allowed only.
%   ├───.window : [optional, GLM (modeltype) only] only required if model.latency equals
%   │             'free' and ignored otherwise. A scalar or 2-element vector in seconds
%   │             that specifies over which time window (relative to the event onsets
%   │             specified in model.timing) the model should be evaluated.
%   ├───────.bf : [optional, GLM (modeltype) only] basis function/basis set; modality
%   │             specific default with subfields
%   │               (1) .fhandle (function handle or string)
%   │               (2) .args (arguments, first argument sampling interval will be added
%   │                   by pspm_glm).
%   │             The optional subfield .shiftbf = n indicates that the onset of the basis
%   │             function precedes event onsets by n seconds (default: 0: used for
%   │             interpolated data channels).
%   ├.modelspec : [optional, GLM (modeltype) only] 'scr' (default); specify the model to
%   │             be used. See pspm_init, defaults.glm() which modelspecs are possible
%   │             with glm.
%   ├─.nuisance : [optional, GLM (modeltype) only] allows to specify nuisance regressors.
%   │             Must be a file name; the file is either a .txt file containing the
%   │             regressors in columns, or a .mat file containing the regressors in a
%   │             matrix variable called R. There must be as many values for each column
%   │             of R as there are data values. SCRalyze will call these regressors R1,
%   │             R2, ...
%   ├.centering : [optional, GLM (modeltype) only] if set to 0 the function would not
%   │             perform the mean centering of the convolved X data. For example, to
%   │             invert SPS model, set centering to 0. Default as 1.
%   ├─.lasttrialcutoff:
%   │             [optional, DCM (modeltype) only] If there fewer data after the end of
%   │             then last trial in a session than this cutoff value (in s), then
%   │             estimated parameters from this trial will be assumed inestimable and
%   │             set to NaN after the inversion. This value can be set as inf to always
%   │             retain parameters from the last trial. Default as 7 s.
%   ├.substhresh: [optional, DCM (modeltype) only] Minimum duration (in seconds) of NaN
%   │             periods to cause splitting up into subsessions which get evaluated
%   │             independently (excluding NaN values). Default as 2.
%   ├.constrained: [optional, DCM (modeltype) only] Constrained model for flexible
%   │             responses which have fixed dispersion (0.3 s SD) but flexible latency.
%   └────method : [optional, SF (modeltype) only] [string/cell_array]
%                   [string] either 'auc', 'scl', 'dcm' (default), or 'mp'.
%                   [cell_array] a cell array of methods mentioned above.
%   options: see calling functions and pspm_options
% ● History
%   Introduced in PsPM 6.1.1
%   Written in 2023 by Dominik Bach (UCL and Bonn)

%% 0. Initialise & check options
global settings
if isempty(settings)
  pspm_init;
end

%% 1. General checks  ------------------------------------------------------
if ~isstruct(model) || isempty(model)
  warning('ID:invalid_input', 'Model must be a non-empty struct.');
  model = struct('invalid', 1);
  return
else
    model.invalid = 1;
end

options = pspm_options(options, modeltype);
if options.invalid
    return
end

%% 2. Reject missing mandatory fields common to all models -----------------
if ~isfield(model, 'datafile')
  warning('ID:invalid_input', 'No input data file specified.'); return;
elseif ~isfield(model, 'modelfile')
  warning('ID:invalid_input', 'No output model file specified.'); return;
elseif ischar(model.datafile)
    model.datafile = {model.datafile};
end
nFile = numel(model.datafile);

% 3. Reject wrong type of mandatory fields --------------------------------
if ~iscell(model.datafile) && ~ischar(model.datafile)
  warning('ID:invalid_input', 'Input data must be a cell or string.'); return;
elseif ~ischar(model.modelfile) 
  warning('ID:invalid_input', 'Output model must be a string.'); return;
end

% NOTE we need to separate the case of DCM timing being
% . a cell array of cell arrays
% . just a cell array
% see below

%% 3. Fill missing fields common to all models, and accept only allowed values
if ~isfield(model, 'timing')
    model.timing = cell(nFile, 1);
elseif ~iscell(model.timing) || ...
  (strcmpi(modeltype, 'dcm') && ~isempty(model.timing) && ~iscell(model.timing{1})  && ~ischar(model.timing{1}))
  % for DCM, model.timing is either a file name or a cell array of
  % events, or a cell array of file names or cell arrays, so we need to
  % take care of cases where model.timing is a cell array but not a cell
  % array of cell arrays or a cell array of char
  model.timing = {model.timing};
end
if ~isfield(model, 'missing')
  model.missing = cell(nFile, 1);
elseif ischar(model.missing) || isnumeric(model.missing)
  model.missing = {model.missing};
elseif ~iscell(model.missing)
  warning('ID:invalid_input',...
    'Missing values must be a filename, matrix, or cell array of these.');
  return
end
if ~isfield(model, 'norm')
  model.norm = 0;
elseif ~any(ismember(model.norm, [0, 1]))
  warning('ID:invalid_input', 'Normalisation must be specified as 0 or 1.'); return;
end

% make sure file extension is '.mat'
[pth, fn, ext] = fileparts(model.modelfile);
model.modelfile = fullfile(pth, [fn, '.mat']);

% check that overwriting output is allowed
options.overwrite = pspm_overwrite(model.modelfile, options);
if ~options.overwrite
  warning('ID:invalid_input', 'Model file exists, and overwriting not allowed by user.');
  return
end

%% 4. Check that session-related field entries have compatible size
if (nFile ~= numel(model.timing)) && ...
    ~(numel(model.timing) == 0 && (isfield(model, 'nuisance') || (isfield(model, 'timeunits') && strcmpi(model.timeunits, 'whole'))))
  warning('ID:number_of_elements_dont_match',...
    'Session numbers of data files and event definitions do not match.');
  return
end
if nFile ~= numel(model.missing)
  warning('ID:number_of_elements_dont_match',...
    'Same number of data files and missing value definitions is needed.');
  return
end

%% 5. Check validity of missing epochs
for iFile = 1:nFile
    if ~isempty(model.missing{iFile})
        sts = pspm_get_timing('missing', model.missing{iFile}, 'seconds');
        if sts < 1, return, end
    end
end

%% 6. GLM-specific checks
% -------------------------------------------------------------------------
if strcmpi(modeltype, 'glm')

    % Reject missing or invalid mandatory fields
    if ~isfield(model, 'timeunits')
        warning('ID:invalid_input', 'No timeunits specified.'); return;
    elseif ~ischar(model.timeunits) || ~ismember(model.timeunits, {'seconds', 'markers', 'samples','markervalues'})
        warning('ID:invalid_input', 'Timeunits (%s) not recognised; only ''seconds'', ''markers'' and ''samples'' are supported', model.timeunits); return;
    elseif sum(cellfun(@(f) isempty(f), model.timing)) > 0
        % model.timing not defined -> check whether model.nuisance is defined
        if ~isfield(model, 'nuisance') || isempty(model.nuisance) || ...
            iscell(model.nuisance) && (sum(cellfun(@(f) isempty(f), model.nuisance)) == numel(model.nuisance))
            warning('ID:invalid_input', 'Event onsets and nuisance file are not specified. At least one of the two must be specified.'); return;
        end
        % model.timing is defined -> check timing definition, unless
        % timeunits are 'markervalues' - these cannot be checked upfront
        % because they require loading the data
    elseif ~strcmpi(model.timeunits, 'markervalues') && ~isempty(model.timing)
        for iFile = 1:nFile
            sts = pspm_get_timing('onsets', model.timing{iFile}, model.timeunits);
            if sts < 1, return; end
        end
    end

    % Check optional fields, set default values and reject invalid values
    if ~isfield(model, 'latency')
      model.latency = 'fixed';
    elseif ~ismember(model.latency, {'free', 'fixed'})
      warning('ID:invalid_input', 'Latency should be either ''fixed'' or ''free''.'); return;
    elseif strcmpi(model.latency, 'free') && (~isfield(model, 'window') || ...
            isempty(model.window) || ~isnumeric(model.window))
      warning('ID:invalid_input', 'Window is expected to be a numeric value.'); return;
    elseif strcmpi(model.latency, 'free') && numel(model.window) == 1
      model.window = [0, model.window];
    elseif strcmpi(model.latency, 'free') && numel(model.window) > 2
      warning('ID:invalid_input', 'Only first two elements of model.window are used');
      model.window = model.window(1:2);
    elseif strcmpi(model.latency, 'fixed') && isfield(model, 'window')
      warning('ID:invalid_input', 'model.window was provided but will be ignored');
      model = rmfield(model, 'window');
    end

    if strcmpi(model.latency, 'free') && diff(model.window) < 0
        warning('ID:invalid_input', 'model.window invalid');
    end

    if ~isfield(model, 'modelspec')
        model.modelspec = settings.glm(1).modelspec;
    elseif ~ismember(model.modelspec, {settings.glm.modelspec})
      warning('ID:invalid_input', 'Unknown model specification %s.', model.modelspec); return;
    end

    modno = find(strcmpi(model.modelspec, {settings.glm.modelspec}));

    if ~isfield(model, 'modality')
        model.modality = settings.glm(modno).modality;
    end

    if ~isfield(model,'centering')
      model.centering = 1;
    elseif ~ismember(model.centering, [0, 1])
        warning('ID:invalid_input', 'Mean centering must be specified as 0 or 1.'); return;
    end

end


%% 7. DCM-specific check
% -------------------------------------------------------------------------
if strcmpi(modeltype, 'dcm')

    % Reject missing or invalid mandatory fields
    if sum(cellfun(@(f) isempty(f), model.timing)) > 0
        warning('ID:invalid_input', 'No event onsets specified.'); return;
    else
        for iFile = 1:nFile
            sts = pspm_get_timing('events', model.timing{iFile});
            if sts < 1, return; end
        end
    end

    % Check optional fields, set default values and reject invalid values
    if ~isfield(model, 'channel')
        model.channel = 'scr'; % this returns the last SCR channel
    elseif ~isnumeric(model.channel) && ~strcmp(model.channel,'scr')
        warning('ID:invalid_input', 'Channel number must be numeric or SCR.'); return;
    end

    if ~isfield(model, 'constrained')
        model.constrained = 0;
    elseif ~any(ismember(model.constrained, [0, 1]))
        warning('ID:invalid_input', 'Constrained model must be specified as 0 or 1.'); return;
    end

    if ~isfield(model, 'substhresh')
        model.substhresh = 2;
    elseif ~isnumeric(model.substhresh)
        warning('ID:invalid_input', 'Subsession threshold must be numeric.');
        return;
    end

    if ~isfield(model, 'lasttrialcutoff')
        model.lasttrialcutoff = 7;
    elseif ~isnumeric(model.lasttrialcutoff)
        warning('ID:invalid_input', 'Last trial cutoff threshold must be numeric.');
        return;
    end

end

%% 8. SF-specific check
% -------------------------------------------------------------------------
if strcmpi(modeltype, 'sf')

    % Reject missing or invalid mandatory fields
    if ~isfield(model, 'timeunits')
        warning('ID:invalid_input', 'No timeunits specified.'); return;
    elseif ~ischar(model.timeunits) || ~ismember(model.timeunits, {'seconds', 'markers', 'samples','whole'})
        warning('ID:invalid_input', 'Timeunits (%s) not recognised; only ''seconds'', ''markers'', ''samples'' and ''whole'' are supported', model.timeunits); return;
    elseif nFile > 1
        warning('ID:invalid_input', 'Only one data file allowed for SF.'); return;
    elseif ~strcmpi(model.timeunits, 'whole') && sum(cellfun(@(f) isempty(f), model.timing)) > 0
        warning('ID:number_of_elements_dont_match',...
            'Number of data files and epoch definitions does not match.'); return;
    end

    % Check optional fields, set default values and reject invalid values
    if ~isfield(model, 'channel')
        model.channel = 'scr'; % this returns the last SCR channel
    elseif ~isnumeric(model.channel) && ~strcmp(model.channel,'scr')
        warning('ID:invalid_input', 'Channel number must be numeric or SCR.'); return;
    end

    if ~isfield(model, 'method')
      model.method = {'dcm'};
    elseif ischar(model.method)
      model.method={model.method};
    elseif ~iscell(model.method)
      warning('Method needs to be a char or cell array'); return;
    end
end

%% 9. TAM-specific checks
% -------------------------------------------------------------------------
if strcmpi(modeltype, 'tam')
  if (~isfield(model, 'window') || isempty(model.window) || ~isnumeric(model.window))
    warning('ID:invalid_input', 'Window is expected to be a numeric value.'); return;
  elseif ~isfield(model, 'modelspec')
    model.modelspec = settings.tam(1).modelspec;
  elseif ~ismember(model.modelspec, {settings.tam.modelspec})
    warning('ID:invalid_input', 'Unknown model specification %s.', model.modelspec); return;
  end

  modno = find(strcmpi(model.modelspec, {settings.tam.modelspec}));

  if ~isfield(model, 'modality')
    model.modality = settings.tam(modno).modality;
  end


  % Checking the input function
  if ~isfield(model, 'if')
    model.if = settings.tam(modno).cif;
  else
    if ~isfield(model.if, 'fhandle')
      warning('No input function given.'); return;
    elseif ischar(model.if.fhandle)
      [~, basefn,~] = fileparts(model.if.fhandle);
      model.if.fhandle = str2func(basefn);
      clear basefn
    elseif ~isa(model.bf.fhandle, 'function_handle')
      warning('Basis function must be a string or function handle.'); return;
    end
    if ~isfield(model.if,'args') || isempty(model.if.args) || ~isnumeric(model.if.args)
      warning('ID:invalid_input',['Arguments for the input',...
        ' function must be a non-empty numeric array.']); return;
    end
    if ~isfield(model.if,'lb') || ~isnumeric(model.if.lb) ...
        || any(size(model.if.lb)~=size(model.if.args))
      warning('ID:invalid_input',['The lower bounds for the input function',...
        ' must be a numeric array of the same size than ''model.if.arg''.']); return;
    end
    if ~isfield(model.if,'ub') || ~isnumeric(model.if.ub) ...
        || any(size(model.if.ub)~=size(model.if.args))
      warning('ID:invalid_input',['The upper bounds for the input function',...
        ' must be a numeric array of the same size than ''model.if.arg''.']); return;
    end
    if any(model.if.lb > model.if.ub) || any(model.if.lb > model.if.args) ...
        || any(model.if.args > model.if.ub)
      warning('ID:invalid_input',['Input function''s parameters are inconsistent.',...
        ' They must respect: model.if.lb <= model.if.arg <= model.if.ub.']); return;
    end
  end
  model.if.args = model.if.args(:).';
  model.if.lb = model.if.lb(:).';
  model.if.ub = model.if.ub(:).';

  % Checking baseline
  if ~isfield(model,'baseline')
    model.baseline = 0;
  elseif ~isnumeric(model.baseline)
    warning('ID:invalid_input','''model.baseline'' has to be a numeric.'); return;
  elseif model.baseline > model.window || model.baseline < 0
    warning('ID:invalid_input',['''model.baseline'' has to be positive ',...
      'and smaller than ''model.window''.']); return;
  end

  % Checking standard experimental condition
  std_cond_war_msg = ['The standard experimental condition must be',...
    ' either a valid experimental condition or an',...
    ' index corresponding to it.'];
  if ~isfield(model,'std_exp_cond')
    model.std_exp_cond = 'none';
  elseif ~ischar(model.std_exp_cond) && ~isnumeric(model.std_exp_cond)
    warning('ID:invalid_input',std_cond_war_msg); return;
  elseif ischar(model.std_exp_cond)
    tmp_ind = cellfun(@(x) strcmpi(model.std_exp_cond,x), model.timing{1}.names);
    if ~any(tmp_ind)
      warning('ID:invalid_input',std_cond_war_msg); return;
    end
    std_exp_cond.name = model.std_exp_cond;
    std_exp_cond.ind = find(tmp_ind);
  elseif isnumeric(model.std_exp_cond)
    if model.std_exp_cond < 1 || ...
        model.std_exp_cond > numel(model.timing{1}.names)
      warning('ID:invalid_input',std_cond_war_msg); return;
    end
    std_exp_cond.name = model.timing{1}.names(model.std_exp_cond);
    std_exp_cond.ind = model.std_exp_cond;
  end
  clear std_cond_war_msg tmp_ind

  % Checking norm_max
  if ~isfield(model, 'norm_max')
    model.norm_max = 0;
  elseif ~ismember(model.norm_max, [0, 1])
    warning('ID:invalid_input', '''model.norm_max'' has to be 0 or 1.'); return;
  end
end

 %% 9. GLM- and TAM-specific checks
% -------------------------------------------------------------------------
if strcmpi(modeltype, 'glm') || strcmpi(modeltype, 'tam')
    % check the basis function
    if ~isfield(model, 'bf')
        if strcmpi(modeltype, 'glm')
            model.bf = settings.glm(modno).cbf;
        elseif strcmpi(modeltype, 'tam')
            model.bf = settings.tam(modno).cbf;
        end
    elseif ~isfield(model.bf, 'fhandle')
        warning('No basis function given.'); return
    elseif ~(ischar(model.bf.fhandle) || isa(model.bf.fhandle, 'function_handle'))
        warning('Basis function must be a string or function handle.'); return
    elseif ischar(model.bf.fhandle) && ~exist(model.bf.fhandle, 'file')
        warning('ID:invalid_fhandle', 'Specified basis function %s doesn''t exist or is faulty', model.bf.fhandle); return;
    elseif ~isfield(model.bf, 'args')
        model.bf.args = [];
    elseif ~isnumeric(model.bf.args)
        warning('Basis function arguments must be numeric.'); return
    end

    % check the channel definition
    if ~isfield(model, 'channel')
        if strcmp(model.modality, 'psr')
            model.channel = 'pupil';
        else
            model.channel = model.modality;
        end
    elseif ~isnumeric(model.channel) && ~ismember(model.channel, {settings.channeltypes.type})
        warning('ID:invalid_input', 'Channel number must be numeric or a modality short name.'); return;
    end

end

%% 10. General checks that require preceding GLM/TAM-specific checks in
%      case of GLM/TAM
% -------------------------------------------------------------------------
if ~isfield(model, 'filter')
    switch modeltype
        case 'glm'
            model.filter = settings.glm(modno).filter;
        case 'dcm'
            model.filter = settings.dcm{1}.filter;
        case 'sf'
            model.filter = settings.dcm{2}.filter;
        case 'tam'
            model.filter = settings.tam(modno).filter;
    end
end

if ~isfield(model.filter, 'down') || ~isnumeric(model.filter.down)
    warning('ID:invalid_input', 'Filter structure needs a numeric ''down'' field.'); return;
end


% validate
% -------------------------------------------------------------------------
model.invalid = 0;
