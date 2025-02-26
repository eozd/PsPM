function job_id = pspm_jobman(varargin)
% ● Description
%   Main interface for PsPM Batch System
%   Initialise jobs configuration and set MATLAB path accordingly.
% ● Format
%   → Standard
%     pspm_jobman('initcfg')
%     pspm_jobman('run',job)
%     output_list = pspm_jobman('run',job)
%   → Run specified job
%     job_id = pspm_jobman
%     job_id = pspm_jobman('interactive')
%     job_id = pspm_jobman('interactive',job)
%     job_id = pspm_jobman('interactive',job,node)
%     job_id = pspm_jobman('interactive','',node)
% ● Arguments
%   // Run specified job
%   *         job:  filename of a job (.m or .mat), or cell
%                   array of filenames, or 'jobs'/'matlabbatch'
%                   variable, or cell array of 'jobs'/'matlabbatch'
%                   variables.
%   * output_list:  cell array containing the output arguments from
%                   each module in the job. The format and contents
%                   of these outputs is defined in the configuration
%                   of each module (.prog and .vout callbacks).
%   // Run the user interface in interactive mode.
%   *        node:  indicate which part of the configuration is to be used.
%   *      job_id:  can be used to manipulate this job in cfg_util. Note that
%                   changes to the job in cfg_util will not show up in cfg_ui
%                   unless 'Update View' is called.
% ● Developer
%   This code is based on SPM8 and earlier versions by John Ashburner,
%   Philippe Ciuciu and Guillaume Flandin.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008 by Wellcome Trust Centre for Neuroimaging and Freiburg Brain Imaging
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

persistent isInitCfg;
if isempty(isInitCfg) &&  ~(nargin == 1 && strcmpi(varargin{1},'initcfg'))
  warning('spm:pspm_jobman:NotInitialised',...
    'Run pspm_jobman(''initcfg''); beforehand');
  pspm_jobman('initcfg');
end
isInitCfg = true;

if ~nargin
  h = cfg_ui;
  if nargout > 0, job_id = {h}; end
  return;
end

cmd = lower(varargin{1});

if any(strcmp(cmd, {'interactive','run'}))
  if nargin > 1
    % sort out job/node arguments for interactive, run cmds
    if nargin>=2 && ~isempty(varargin{2})
      % do not consider node if job is given
      if ischar(varargin{2}) || iscellstr(varargin{2})
        jobs = load_jobs(varargin{2});
      elseif iscell(varargin{2})
        if iscell(varargin{2}{1})
          % assume varargin{2} is a cell of jobs
          jobs = varargin{2};
        else
          % assume varargin{2} is a single job
          jobs{1} = varargin{2};
        end
      end
      mljob = canonicalise_job(jobs);
    elseif strcmp(cmd, 'interactive') && nargin>=3 && isempty(varargin{2})
      % Node spec only allowed for 'interactive', 'serial'
      arg3       = regexprep(varargin{3},'^spmjobs\.','spm.');
      mod_cfg_id = cfg_util('tag2mod_cfg_id',arg3);
    else
      error('ID:pspm_jobman:WrongUI', ...
        'Don''t know how to handle this ''%s'' call.', lower(varargin{1}));
    end
  end
end

switch cmd
  case {'initcfg'}
    pspm_init;
    cfg_util('initcfg'); % This must be the first call to cfg_util
    cfg_ui('Visible','off'); % Create invisible batch ui

  case {'interactive'}
    if exist('mljob', 'var')
      cjob = cfg_util('initjob', mljob);
    elseif exist('mod_cfg_id', 'var')
      if isempty(mod_cfg_id)
        arg3 = regexprep(varargin{3},'^spmjobs\.','spm.');
        warning('spm:pspm_jobman:NodeNotFound', ...
          ['Can not find executable node ''%s'' - running '...
          'matlabbatch without default node.'], arg3);
        cjob = cfg_util('initjob');
      else
        cjob = cfg_util('initjob');
        mod_job_id = cfg_util('addtojob', cjob, mod_cfg_id);
        cfg_util('harvest', cjob, mod_job_id);
      end
    else
      cjob = cfg_util('initjob');
    end
    cfg_ui('local_showjob', findobj(0,'tag','cfg_ui'), cjob);
    if nargout > 0
      job_id = cjob;
    end

  case {'run'}
    cjob = cfg_util('initjob', mljob);
    cfg_util('run', cjob);
    if nargout > 0
      job_id = cfg_util('getalloutputs', cjob);
    end
    cfg_util('deljob', cjob);

  otherwise
    error([job_id ': unknown option']);
end
sts = 1;
return

%==========================================================================
% function [mljob, comp] = canonicalise_job(job)
%==========================================================================
function [mljob, comp] = canonicalise_job(job)
% job: a cell list of job data structures.
% Check whether job is a SPM5 or matlabbatch job. In the first case, all
% items in job{:} should have a fieldname of either 'temporal', 'spatial',
% 'stats', 'tools' or 'util'. If this is the case, then job will be
% assigned to mljob{1}.spm, which is the tag of the SPM root
% configuration item.

comp = true(size(job));
mljob = cell(size(job));
for cj = 1:numel(job)
  for k = 1:numel(job{cj})
    comp(cj) = comp(cj) && any(strcmp(fieldnames(job{cj}{k}), ...
      {'temporal', 'spatial', 'stats', 'tools', 'util'}));
    if ~comp(cj)
      break;
    end
  end
  if comp(cj)
    tmp = convert_jobs(job{cj});
    for i=1:numel(tmp),
      mljob{cj}{i}.spm = tmp{i};
    end
  else
    mljob{cj} = job{cj};
  end
end

%==========================================================================
% function newjobs = load_jobs(job)
%==========================================================================
function newjobs = load_jobs(job)
% Load a list of possible job files, return a cell list of jobs. Jobs can
% be either SPM5 (i.e. containing a 'jobs' variable) or SPM8/matlabbatch
% jobs. If a job file failed to load, an empty cell is returned in the
% list.
if ischar(job)
  filenames = cellstr(job);
else
  filenames = job;
end
newjobs = {};
for cf = 1:numel(filenames)
  [p,nam,ext] = fileparts(filenames{cf});
  switch ext
    case '.mat'
      try
        S=load(filenames{cf});
        if isfield(S,'matlabbatch')
          matlabbatch = S.matlabbatch;
        elseif isfield(S,'jobs')
          jobs = S.jobs;
        else
          warning('ID:pspm_jobman:JobNotFound','No job found in ''%s''', filenames{cf});
        end
      catch
        warning('ID:pspm_jobman:LoadFailed','Load failed: ''%s''',filenames{cf});
      end
    case '.m'
      try
        fid = fopen(filenames{cf},'rt');
        str = fread(fid,'*char');
        fclose(fid);
        eval(str);
      catch
        warning('ID:pspm_jobman:LoadFailed','Load failed: ''%s''',filenames{cf});
      end
      if ~(exist('jobs','var') || exist('matlabbatch','var'))
        warning('ID:pspm_jobman:JobNotFound','No job found in ''%s''', filenames{cf});
      end
    otherwise
      warning('Unknown extension: ''%s''', filenames{cf});
  end
  if exist('jobs','var')
    newjobs = [newjobs(:); {jobs}];
    clear jobs;
  elseif exist('matlabbatch','var')
    newjobs = [newjobs(:); {matlabbatch}];
    clear matlabbatch;
  end
end

%==========================================================================
% function njobs = convert_jobs(jobs)
%==========================================================================
function njobs = convert_jobs(jobs)
decel    = struct('spatial',struct('realign',[],'coreg',[],'normalise',[]),...
  'temporal',[],...
  'stats',[],...
  'meeg',[],...
  'util',[],...
  'tools',struct('dartel',[]));
njobs  = {};
for i0 = 1:numel(jobs)
  tmp0  = fieldnames(jobs{i0});
  tmp0  = tmp0{1};
  if any(strcmp(tmp0,fieldnames(decel)))
    for i1=1:numel(jobs{i0}.(tmp0))
      tmp1  = fieldnames(jobs{i0}.(tmp0){i1});
      tmp1  = tmp1{1};
      if ~isempty(decel.(tmp0))
        if any(strcmp(tmp1,fieldnames(decel.(tmp0)))),
          for i2=1:numel(jobs{i0}.(tmp0){i1}.(tmp1)),
            njobs{end+1} = struct(tmp0,struct(tmp1,jobs{i0}.(tmp0){i1}.(tmp1){i2}));
          end
        else
          njobs{end+1} = struct(tmp0,jobs{i0}.(tmp0){i1});
        end
      else
        njobs{end+1} = struct(tmp0,jobs{i0}.(tmp0){i1});
      end
    end
  else
    njobs{end+1} = jobs{i0};
  end
end
