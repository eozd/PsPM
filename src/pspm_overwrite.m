function overwrite_final = pspm_overwrite(varargin)
% ● Description
%   pspm_overwrite generalises the overwriting operation
%   pspm_overwrite considers the following situations
%   - whether options.overwrite is defined
%   - whether PsPM is in develop mode
%   - whether the file exist
%   - whether GUI can be used
%   PsPM will always try to overwrite files wherever possible except:
%   1. if overwrite is defined as not to overwrite
%   2. if overwrite is not defined
%      a. the file has existed
%      b. users use the GUI to stop overwriting
% ● Arguments
%   *        fn : the name of the file to possibly overwrite can be a link if necessary.
%   * overwrite : a numerical value or a struct option of overwrite if this option is
%                 presented can be a value or a struct.
%                 If a value, can be 0 (not to overwrite) or 1 (to overwrite) or 2 (ask user).
%                 If a struct, check if the field `overwrite` exist.
% ● Examples
%   overwrite_final = pspm_overwrite(fn, overwrite)
% ● Outputs
%   * overwrite_final:  option of overwriting determined by pspm_overwrite
%                       0: not to overwrite
%                       1: to overwrite
% ● History
%   Introduced in PsPM 6.0
%   Written in 2022 by Teddy
%   Maintained in 2024 by Teddy

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end

overwrite_final = 0;   


%% 2 Check inputs
switch numel(varargin)
  case 0
    warning('ID:invalid_input', 'at least one argument is required');
    return;
  case 1 % overwrite is not defined
    fn = varargin{1};
    if iscell(fn)
      fn = fn{1};
    end
    overwrite_final = 2;     
    % the default value of overwrite is initialised here and will be checked later
  case 2
    fn = varargin{1};
    if iscell(fn)
      fn = fn{1};
    end
    switch class(varargin{2})
      case 'double'
        overwrite_final = varargin{2};
      case 'struct'
        options_struct = varargin{2};
        if isfield(options_struct, 'overwrite')
          overwrite_final = options_struct.overwrite;
        else
          overwrite_final = 2;  
        end
      otherwise
        warning('ID:invalid_input', ...
          'the second input argument should be either a double or a struct.');
        return
    end
end

%% 3 Define overwrite

if ~exist(fn, 'file')
    % if file does not exist, always set status to write
    overwrite_final = 1;
elseif overwrite_final == 2 
  if settings.developmode
      error('Overwrite not correctly defined for testing.')
  else
   msg = ['This file already exists. Overwrite?', ...
     newline, 'Existing file: ', fn];
   overwrite = questdlg(msg, ...
     'File already exists', 'Yes', 'No', 'Yes');
  % default as Yes (to overwrite)
   overwrite_final = strcmp(overwrite, 'Yes');
  end
end

if overwrite_final == 0
  warning('ID:data_loss', ['Results are not saved, ',...
    'because there is an existing file with the same name, ',...
    'and ''options.overwrite'' is set to ''0''.\n']);
end

%% 4 Validate overwrite_final
if overwrite_final ~= 0 && overwrite_final ~= 1
  warning('ID:invalid_input', 'overwrite can be only 0 or 1');
  overwrite_final = 0;
  return
end

