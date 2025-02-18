function [sts, data, mdltype] = pspm_load1(fn, action, savedata, options)
% ● Format
%   [sts, data, mdltype] = pspm_load1(fn, action, savedata, options)
% ● Arguments
%   *     fn : filename, or model structure
%   * action : (default 'none'):
%              'none' : check whether file is valid at all
%              'stats': retrieve stats struct with fields .stats and .names
%              'cond' : for GLM - retrieve stats struct using only
%                       first regressor/basis function for each condition
%                       for models with 2D stats structure - retrieve
%                       mean parameter values per condition, based on
%                       unique trial names
%              'recon' :  (for GLM) retrieve stats struct using
%                       reconstructed responses (which are at the same
%                       time written into the glm struct as glm.recon)
%              'con':  retrieve full con structure
%              'all':  retrieve the full first level structure
%              'savecon':  add contrasts to file, use an additional
%                       input argument data that contains the contrasts
%              'save':  check and save first levle model, use an additional
%                       input argument data that contains the model struct
%  * savedata : for 'save' option - a struct containing the model as only field
%               for 'savecon' option - contains the con structure
%   ┌─options
%   ├.zscored : zscore data - substract the mean and divide by the standard deviation.
%   └.overwrite : [for 'save'] [logical] (0 or 1) Define whether to overwrite existing
%                 output files or not. Default value: determined by pspm_overwrite.
% ● Output
%  *     data : depending on option
%             - none (for 'none', 'savecon', 'save')
%             - data.stats, data.names, (and data.trlnames if existing) (for
%                        'stats', 'recon', 'cond')
%                        - con structure (for 'con')
%                        - full first level structure (for 'all')
%  *  mdltype : model type e.g. 'glm', 'sf', 'dcm', 'tam'
% ● Developer's Notes
%   General structure of PsPM 1st level model files
%   Each file contains one struct variable with the model
%   allowed model names are specified in pspm_init
%   each model must contain the following fields:
%     .stats: a n x 1 vector (glm, for n regressors) or n x k matrix (dcm,
%           sf; for k measures, n trials/epochs)
%     .names: a cell array corresponding to regressor names (glm) or measure
%           names across trials/epochs (sf, dcm)
%     .trlnames for models with 2D stats structure (dcm, sf)
%   optional fields:
%     .recon for reconstructed glm responses
%     .con for contrasts
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (WTCN, UZH)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
data = struct;
mdltype = 'no valid model';
mdltypes = settings.first;

%% check input arguments & set defaults
% check missing input --
if nargin < 1
  warning('ID:invalid_input', 'No datafile specified'); return;
elseif nargin < 2
  action = 'none';
elseif any(strcmpi(action, {'save', 'savecon'})) && nargin < 3
  warning('ID:missing_data', 'Save failed, no data provided'); return;
end


% canonicalise file name
if ischar(fn)
    [pth, filename, ext] = fileparts(fn);
    if isempty(ext)
      ext = '.mat';
    end
    fn = fullfile(pth, [filename, ext]);
    errmsg = sprintf('Data file %s is not a valid PsPM file:\n', fn);
else
    errmsg = sprintf('Input must be a valid PsPM file:\n');
end

%  set default zscored
if nargin <= 3
  options = struct();
end
options = pspm_options(options, 'load1');
if options.invalid
  return
end
writefile = 1;
% check whether file exists --
if ischar(fn) && exist(fn, 'file')
  if strcmpi(action, 'save')
    writefile = pspm_overwrite(fn, options);
    if ~writefile
      warning('ID:not_saving_data', 'Not saving data.\n');
    end
  end
elseif ~isstruct(fn) && ~strcmpi(action, 'save')
  warning('ID:invalid_input', '1st level file (%s) doesn''t exist', fn);
end



% check whether file is a matlab file --
if ~strcmpi(action, 'save')
    if ischar(fn)
        try
            indata = load(fn);
        catch
            errmsg = [errmsg, 'Not a matlab data file.']; warning('ID:invalid_input', errmsg); return;
        end
    else
        indata.(fn.modeltype) = fn;
    end
else
    indata = savedata;
end

% check for SCRalyze 1.x files --
if isfield('indata', 'dsm'), warning('ID:SCRalyze_1_file', 'SCRalyze 1.x compatibility is discontinued'); return; end

% check file contents
% ------------------------------------------------------------------------
% check model type --
mdltype = find(ismember(mdltypes, fieldnames(indata)));
if isempty(mdltype)
  warning('ID:invalid_data_structure', '%sNo known model type in this file', errmsg); return;
elseif numel(mdltype) > 1
  warning('ID:invalid_data_structure', '%sMore than one model type in this file', errmsg); return;
else
  mdltype = mdltypes{mdltype};
end

% check model content --
if ~isfield(indata.(mdltype), 'modelfile')
  warning('ID:invalid_data_structure', '%sNo file name contained in model structure.', errmsg); return;
elseif ~isfield(indata.(mdltype), 'modeltype')
  warning('ID:invalid_data_structure', '%sNo modeltype contained in model structure. Modeltype is automatically added to the model structure.', errmsg);
  % do not return, since this is not yet fully implemented; just give a
  % warning message and instead set it as it should be
  % --------------------------------------------
  % return
  indata.(mdltype).modeltype = mdltype;
elseif ~isfield(indata.(mdltype), 'modality')
  warning('ID:invalid_data_structure', '%sNo modality contained in model structure. Modality is autmoatically added to the model structure.', errmsg);
  % do not return, since this is not yet fully implemented; just give a
  % warning message and instead set it as it should be
  % --------------------------------------------
  % return
  indata.(mdltype).modality = settings.modalities.(mdltype);
elseif strcmpi(mdltype, 'tam')
  % nothing to do
elseif ~isfield(indata.(mdltype), 'stats')
  warning('ID:invalid_data_structure', '%sNo stats contained in file.', errmsg); return;
elseif ~isfield(indata.(mdltype), 'names')
  warning('ID:invalid_data_structure', '%sNo names contained in file.', errmsg); return;
elseif strcmpi(mdltype, 'glm')
  if size(indata.(mdltype).stats, 1) ~= numel(indata.(mdltype).stats)
    warning('ID:invalid_data_structure', '%sGLM stats should be a n x 1 vector.', errmsg); return;
  elseif strcmpi(mdltype, 'glm') && numel(indata.(mdltype).names) ~= numel(indata.(mdltype).stats)
    warning('ID:invalid_data_structure', '%sNumbers of names and parameters do not match.', errmsg); return;
  end
elseif ~isfield(indata.(mdltype), 'trlnames')
  warning('ID:invalid_data_structure', '%sNo trial names contained in file.', errmsg); return;
elseif numel(indata.(mdltype).names) ~= size(indata.(mdltype).stats, 2)
  warning('ID:invalid_data_strucutre', '%sNumbers of names and parameters do not match.', errmsg); return;
elseif numel(indata.(mdltype).trlnames) ~= size(indata.(mdltype).stats,1)
  warning('ID:invalid_data_structure', '%sNumbers of trial names and parameters do not match.', errmsg); return;
end

% Backwards compatibility for SF-Models
% Transform old sf-structure into new structure
if strcmpi(mdltype, 'sf') && ~isfield(indata.(mdltype), 'model')
  % methods are newly stored within .model
  % move methods to .model{k}

  % issue warning
  warning('ID:obsolete_function', ['Old structure of sf model detect. ', ...
    'Trying to transform into new structure. ', ...
    'This functionality will be removed within future PsPM versions.']);

  methods = {'auc','dcm','scl','mp'};
  i = 1;
  for k = 1:numel(methods)
    if isfield(indata.sf, methods{k})
      indata.sf.model{i} = indata.sf.(methods{k});
      for j = 1:numel(indata.sf.model{i})
        indata.sf.model{i}(j).modeltype = methods{k};
      end
      indata.sf = rmfield(indata.sf, methods{k});
      i = i + 1;
    end
  end
end

% check optional fields --
if ~isfield(indata.(mdltype), 'con')
  conflag = 0;
else
  conflag = 1;
end
if ~isfield(indata.(mdltype), 'recon')
  reconflag = 0;
else
  reconflag = 1;
end

% if not glm, nor tam
% create condition names --
if ~strcmpi(mdltype, 'glm') && ~strcmpi(mdltype, 'tam')
  indata.(mdltype).condnames = ...
    unique(indata.(mdltype).trlnames(cellfun(@ischar,indata.(mdltype).trlnames)));
end

%% retrieve file contents

if options.zscored
  if strcmpi(mdltype, 'dcm') && ...
      (strcmpi(action, 'cond') || strcmpi(action, 'stats'))
    %ignore all stats with NaN values
    if sum(isnan(indata.(mdltype).stats))~=0
      temp = indata.(mdltype).stats(~isnan(isnan(indata.(mdltype).stats)));
      indata.(mdltype).stats = zscore(temp);
    else
      indata.(mdltype).stats = zscore(indata.(mdltype).stats);
    end
    data.zscored = 1;
  else
    data.zscored = 0;
    warning('ID:invalid_input', ...
      ['Z-scoring only available for non-linear models and action ',...
      '''stats'' or ''cond''. Not z-scoring data!']);
  end
end

switch action
  case 'none'
    data = [];
  case 'stats'
    data.stats = indata.(mdltype).stats;
    data.names = indata.(mdltype).names;
    if isfield(indata.(mdltype),'stats_missing')&& isfield(indata.(mdltype),'stats_exclude')
      data.stats_missing = indata.(mdltype).stats_missing;
      data.stats_exclude = indata.(mdltype).stats_exclude;
      data.stats_exclude_names = indata.(mdltype).stats_exclude_names;
    end
    if ~strcmpi(mdltype, 'glm')
      data.trlnames = indata.(mdltype).trlnames;
      data.condnames = indata.(mdltype).condnames;
    end
  case 'cond'
    if strcmpi(mdltype, 'glm')
      condindx = 1:(indata.glm.bf.bfno):(numel(indata.glm.stats)-indata.glm.interceptno);
      data.stats = indata.glm.stats(condindx);
      data.names = indata.glm.names(condindx);
      if isfield(indata.glm,'stats_missing')&& isfield(indata.glm,'stats_exclude')
        data.stats_missing = indata.glm.stats_missing;
        data.stats_exclude = indata.glm.stats_exclude;
        data.stats_exclude_names = indata.glm.stats_exclude_names;
      end
      clear condindx
    else
      for iCond = 1:numel(indata.(mdltype).condnames)
        condindx = strcmpi(indata.(mdltype).condnames{iCond}, indata.(mdltype).trlnames);
        data.stats(iCond, :) = nanmean(indata.(mdltype).stats(condindx, :), 1);
      end
      data.names = indata.(mdltype).names;
      data.trlnames = indata.(mdltype).trlnames;
      data.condnames = indata.(mdltype).condnames;
    end
  case 'recon'
    if strcmpi(mdltype, 'glm')
      if ~reconflag
        [sts_glm_recon, indata.glm] = pspm_glm_recon(fn);
        if sts_glm_recon ~= 1, warning('GLM reconstruction not successful.'); return; end
      end
      data.stats = indata.glm.recon;
      data.names = indata.glm.reconnames;
      if isfield(indata.glm,'stats_missing')&& isfield(indata.glm,'stats_exclude')
        data.stats_missing = indata.glm.stats_missing;
        data.stats_exclude = indata.glm.stats_exclude;
        data.stats_exclude_names = indata.glm.stats_exclude_names;
      end
    else
      warning('ID:invalid_input', '%s. ''recon'' option only defined for GLM files', errmsg);
      return;
    end
  case 'con'
    if conflag
      data = indata.(mdltype).con;
    else
      data = [];
    end
  case 'all'
    data = indata.(mdltype);
  case 'savecon'
    indata.(mdltype).con = savedata;
    if writefile
      save(fn, '-struct', 'indata', mdltype);
    end
  case 'save'
    if writefile
      save(fn, '-struct', 'indata', mdltype);
    end
  otherwise
    warning('ID:unknown_action', 'Unknown action. Just checking file. File is valid.'); return;
end
sts = 1;
return
