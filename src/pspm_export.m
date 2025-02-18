function sts = pspm_export(modelfile, options)
% ● Description
%   pspm_export exports first level statistics from one or several first-level
%   models for further statistical analysis on the group level. 
%   The output is organised as a matrix with rows for observations
%   (first-level models) and columns for statistics (must be the same for all
%   models). The output can be written to screen or to a text file. 
% ● Format
%   pspm_exp(modelfile, options)
% ● Arguments
%   *       modelfile:  [string/cell_array] a filename, or cell array of filenames.
%   ┌─────────options
%   ├─────────.target:  [optional, string, default as 'screen']
%   │                   'screen' (default), or a name of an output text file.
%   ├──────.statstype:  [optional, string, accepts 'param'/'cond'/'recon']
%   │                    By default, all parameter estimates are exported.
%   │                    The following options are available: 
%   │                    1. 'param': export all parameter estimates (default)
%   │                    2. 'cond':  For GLMs: automatically detects number of
%   │                             basis functions and exports only the first one
%   │                             (e.g.  without derivatives). 
%   │                             For non-linear models: average estimate, based 
%   │                             on unique trial names.
%   │                   3. 'recon':  For GLMs only: reconstructs estimated response 
%   │                             from all basis functions and exports the 
%   │                             peak amplitude of the estimated response.
%   ├──────────.delim:  [optional, default is tab('\t')]
%   │                   delimiter for output file.
%   └.exclude_missing:  [optional, default as 0]
%                       Exclude parameters from conditions with too many NaN
%                       values. This option can only be used for GLM files when
%                       exclude_missing was set during model setup. Otherwise 
%                       this argument is ignored.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2009-2015 by Dominik R Bach (WTCN, UZH)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

% check input arguments
% ------------------------------------------------------------------------
if nargin < 1
  errmsg=sprintf('No model file(s) specified');
  warning('ID:invalid_input',errmsg);
  return;
elseif nargin < 2
  %if no options are given, built options struct with default values
  options = struct();
end;

options = pspm_options(options, 'exp');
if options.invalid
  return
end
target = options.target;
statstype = options.statstype;
delim = options.delim;
exclude_missing = options.exclude_missing;

% check model file argument (actual files are checked below) --
if ischar(modelfile)
  modelfile = {modelfile};
elseif ~iscell(modelfile)
  warning('ID:invalid_input', 'Model file must be a cell array of char, or char.');
  return;
end;

% check target --
if ~ischar(target)
    warning('ID:invalid_input', 'Target must be a char');
    return;
elseif strcmp(target, 'screen')
    fid = 1;
else
    % check file extension
    [pth, filename, ext]=fileparts(target);
    if isempty(ext)
        target=fullfile(pth, [filename, '.tsv']);
    end
    options.overwrite = pspm_overwrite(target, options);
    if ~options.overwrite
        warning('ID:invalid_input', 'Output file exists, and overwriting not allowed by user.');
        return
    end

    % open or create file for reading and writing, discard contents
    fid = fopen(target, 'w+');
    if fid == -1, warning('Output file (%s) could not be opened.', target); return; end;
end;

% check statstype --
if ~ischar(statstype)
  warning('Stats type must be a char');
  return;
elseif strcmpi(statstype, 'param')
  statstype = 'stats';
elseif ~strcmpi(statstype, {'cond', 'recon'})
  warning('ID:invalid_input', 'Unknown Stats type (%s)', statstype);
  return;
end;

% check delimiter --
if ~ischar(delim)
  warning('ID:invalid_input', 'Delimiter must be a char'); return;
end;

% check exclude_missing --
if exclude_missing~=0 && exclude_missing~=1
  warning('ID:invalid_input', ['The value of options.exclude_missing ',...
    'must be either 0 or 1']); return;
end;

% get data
% -------------------------------------------------------------------------
% load & check data --
usenames = 1;
excl_stats_contained = false(numel(modelfile),1);
for iFile = 1:numel(modelfile)
  [lsts, data(iFile), modeltype{iFile}] = pspm_load1(modelfile{iFile}, statstype);
  if lsts < 1, return; end;
  % set flag to indicate if exclude statistics are contained
  if isfield(data(iFile),'stats_exclude') && isfield(data(iFile),'stats_missing')
    excl_stats_contained(iFile) = true;
  end
  if iFile > 1
    if ~strcmpi(modeltype{iFile}, modeltype{1})
      warning('First level files must use the same model (File 1: %s, File %2.0f: %s)', ...
        modeltype{1}, iFile, modeltype{iFile}); return;
    elseif ~(ndims(data(iFile).stats) == ndims(data(1).stats)) || ...
        ~all(size(data(iFile).stats) == size(data(1).stats))
      warning('First level files must have the same structure (File 1 vs. File %2.0f)', iFile);
      return;
    elseif ~(numel(data(iFile).names) == numel(data(1).names)) || ...
        ~all(strcmpi(data(iFile).names, data(1).names));
      usenames = 0;
    end;
  end;
end;

% create output names --
if ~usenames
  outnames = {'Model files have different parameter names - name output suppressed.'};
elseif strcmpi(modeltype{1}, 'GLM')
  outnames = data(1).names;
else
  if strcmpi(statstype, 'stats')
    trlnames = data(1).trlnames;
  elseif strcmpi(statstype, 'cond')
    trlnames = data(1).condnames;
  end;
  % combine with measure names
  cName = 1;
  for iMsr = 1:size(data(1).stats, 2)
    for iTrl = 1:size(data(1).stats, 1)
      outnames{cName} = sprintf('%s - %s', trlnames{iTrl}, data(1).names{iMsr});
      cName = cName + 1;
    end;
  end;
end;

% create output data --
% if exclude_missing & any exclude stats available: set condition stats to NaN
% according to the exclude stat
for iFile = 1:numel(data)
  outdata(iFile, :) = data(iFile).stats(:);
  length_out = numel(outdata(iFile, :));
  if excl_stats_contained(iFile)&& exclude_missing
    corr_cond_idx = find(data(iFile).stats_exclude);
    if any(strcmpi(statstype, {'stats','recon'})) && ~isempty(data(iFile).stats_exclude_names)
      idx_stats=cellfun(@(x) find(not(cellfun('isempty',strfind(outnames,x)))),data(iFile).stats_exclude_names,'UniformOutput',0);
      idx_stats_name=cell2mat(idx_stats);
      idx_stats_name = reshape(idx_stats_name,numel(idx_stats_name),1);
      corr_cond_idx =zeros(length_out,1);
      corr_cond_idx(idx_stats_name) = 1;
      corr_cond_idx=logical(corr_cond_idx');
    end
    if~isempty(corr_cond_idx)
      outdata(iFile, corr_cond_idx) = nan;
    end
  end
end



% create stats description --
if strcmpi(statstype, 'stats')
  statstypechar = 'All parameter estimates';
elseif strcmpi(statstype, 'cond') && strcmpi(modeltype{1}, 'GLM')
  statstypechar = 'Canonical parameter estimate per condition';
elseif strcmpi(statstype, 'cond') && strcmpi(modeltype{1}, 'DCM')
  statstypechar = 'Average parameter estimate per condition';
elseif strcmpi(statstype, 'recon')
  statstypechar = 'Reconstructed response amplitude per condition';
else
  warning('No valid data type'); return;
end;


% output --
% header -
fprintf(fid, 'Statistics for models of type ''%s'' (statistics type: %s) \n', modeltype{1}, statstypechar);
% variable names -
for iName = 1:numel(outnames)
  fprintf(fid, sprintf('%s%s', outnames{iName}, delim));
end;
fprintf(fid, '\n');
% data -
for iRow = 1:size(outdata, 1)
  for iCol = 1:size(outdata, 2)
    fprintf(fid, sprintf('%8.8f%s', outdata(iRow, iCol), delim));
  end;
  fprintf(fid, '\n');
end;
fprintf(fid, '\n');
% close file -
if fid ~= 1
  fclose(fid);
end;

%% Return values
sts = 1;
return
