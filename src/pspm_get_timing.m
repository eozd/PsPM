function [sts, outtiming] = pspm_get_timing(varargin)
% ● Description
%   pspm_get_timing is a shared function to read timing information from
%   different formats and align with a number of files. Time units (seconds,
%   samples, markers) are not changed.
% ● Format
%   → Standard
%     [sts, multi]  = pspm_get_timing('onsets', intiming, timeunits)
%     [sts, epochs] = pspm_get_timing('epochs', epochs, timeunits)
%     [sts, events] = pspm_get_timing('events', events)
%     [sts, epochs] = pspm_get_timing('missing', epochs, timeunits)
%   → For recursive calls also:
%     [sts, epochs] = pspm_get_timing('file', filename)
% ● Arguments
%   onsets and timeunits are 'seconds', 'samples' or 'markers':
%      for defining event onsets for multiple conditions (e. g. GLM)
%      intiming is - a multiple condition file name (single session) OR
%                  - a cell array of multiple condition file names OR
%                  - a struct (single session) with fields .names, .onsets,
%                       and (optional) .durations and .pmod
%                  - a cell array of struct
%                  - a struct with fields 'markerinfos', 'markervalues,
%                   'names' OR
%                  - a cell array of struct
%
%      if timeunits are 'samples' or 'markers', all onsets must be integer
%
%   onsets and timeunits are 'markervalues':
%      for defining onsets for multiple conditions (e.g. GLM) from
%      entries in markerinfos:
%      intiming:  - a struct with fields 'markerinfo', 'markervalues',
%                   'names' OR
%                 - a cell array of struct
%                 - in both cases:
%                    - markerinfo as loaded from a marker channel
%                    - if markervalues is a vector of numeric, this creates
%                      conditions from the corresponding entries in markerinfos.value
%                    - if markervalues is a cell array of char, it creates
%                      conditions from the corresponding entries in markerinfos.name
%                    - names: cell array of condition names for the values
%                      indicated in markervalues
%
%     epochs: for defining data epochs (e. g. analysis of SF, missing epochs in
%             GLM). epochs can be one of the following
%             - an SPM style onset file with two event types: onset & offset
%               (names are ignored)
%             - a two-column text file with on/offsets
%             - a .mat file with a variable 'epochs' (see below)
%             - e x 2 matrix of epoch on- and offsets (e: number of epochs)
%     events: for defining events and event windows (e. g. in DCM), events can
%             be either a variable that is, or a file name that contains a
%             variable. 'events' that is
%             - a .mat file with a variable 'events' (see below)
%             - a cell array with multiple one and two column vectors for fully
%               flexible DCMs that must all have the same number of rows.
% ● Developer's Notes
%   Differences in GLM multiple condition definitions between SPM and PsPM
%   (1) 'durations' is optional - default is 0
%   (2) 'durations' must be 0 if onsets are specified by markers
%   (3) 'poly' is an optional field in pmods - default is 1. Polynomial
%       values larger than 1 are expanded here and returned as additional cells
%       for 'param'
% ● History
%   Introduced in PsPM 3.0
%   Written    in 2009-2015 by Dominik R Bach (WTCN, UZH)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outtiming = [];
filewarning = 0;


% check input
% ------------------------------------------------------------------------
if nargin < 2
  warning('ID:invalid_input', 'No input. I don''t know what to do.');
  return;
else
  model = varargin{1};
  intiming = varargin{2};
end

if ~ismember(model, {'onsets', 'epochs', 'missing', 'events', 'file'})
  warning('ID:invalid_input', 'Invalid input. I don''t know what to do.');
  return;
end

switch model
  case {'onsets', 'epochs', 'missing'}
    if nargin < 3
      warning('ID:invalid_input', 'Time units unspecified');  return;
    else
      timeunits = varargin{3};
    end
end


% recursive option to retrieve file contents
% -------------------------------------------------------------------------
switch model
  case 'file'
    if ~ischar(intiming)
      warning('ID:invalid_input','Specify file name as char with ''file'' option.');  return;
    elseif ~exist(intiming, 'file')
      warning('ID:nonexistent_file', 'File (%s) doesn''t exist', intiming);  return;
    else
      [pth, fn, ext] = fileparts(intiming);
      switch ext
        case {'.mat'} % matlab file
          outtiming = load(intiming);
        otherwise
          outtiming.epochs = dlmread(intiming);
          if isempty(outtiming)
            warning('Could not read text file %s', intiming);
            return;
          end
      end
    end

  case 'onsets'
    if ~strcmpi(timeunits,'markervalues')
      % timing information for GLM (SPM style files with some slight variations)
      % -------------------------------------------------------------------------

      multi = [];
      errmsg = 'Multiple condition information invalid:';
      if ~iscell(intiming)
        tmp = intiming;
        clear intiming;
        intiming{1} = tmp;
      end

      nFiles = numel(intiming);
      allnames = {};
      for iFile = 1:nFiles
        % load regressor information from file if necessary --
        if ischar(intiming{iFile})
          [lsts, in] = pspm_get_timing('file', intiming{iFile});
          if lsts < 1, return; end
        elseif isstruct(intiming{iFile})
          in = intiming{iFile};
        else
          warning('ID:invalid_input','The elements of intiming must be structs or filenames');
          return;
        end

        % check regressor information --
        % check whether all fields are present and in correct format:

        if ~isfield(in, 'names') || ~isfield(in, 'onsets')
          warning('ID:invalid_input','%sNo names or onsets.', errmsg);
          return;
        end

        if ~isfield(in, 'durations')
          in.durations = num2cell(zeros(numel(in.names), 1));
        end

        if ~iscell(in.names)||~iscell(in.onsets)
          warning('ID:invalid_input','%sNames and onsets need to be cell arrays', errmsg);

          return;
        end
        % check number of conditions:
        if numel(in.names)~=numel(in.onsets)
          warning('ID:number_of_elements_dont_match',['%sNumber of event names (%d) does ', ...
            'not match the number of onsets (%d).'],...
            errmsg, numel(in.names), numel(in.onsets));

          return;
        elseif numel(in.names)~=numel(in.durations)
          warning('ID:number_of_elements_dont_match',['%sNumber of event names (%d) does not match ', ...
            'the number of durations (%d).'], ...
            errmsg, numel(in.onsets),numel(in.durations));

          return;
        end

        % check number of events and non-allowed values per condition:
        for iCond = 1:numel(in.names)
            if ~((isvector(in.onsets{iCond}) && ...
                    isnumeric(in.onsets{iCond})) || ...
                    (isempty(in.onsets{iCond}) && ...
                    ~strcmp('', in.onsets{iCond})))
                warning('ID:no_numeric_vector', ...
                    ['%sCondition `%s` - onsets{%i} must be a ', ...
                    'numeric vector or empty.'], errmsg, ...
                    in.names{iCond}, iCond); return;
            end

            if numel(in.durations{iCond}) == 1
                in.durations{iCond} = repmat(in.durations{iCond}, ...
                    numel(in.onsets{iCond}), 1);
            elseif (numel(in.onsets{iCond}) ~= numel(in.durations{iCond}))
                warning('ID:number_of_elements_dont_match',['%sCondition `%s` - Number of event onsets ', ...
                    '(%d) does not match the number of durations (%d).'],...
                    errmsg, in.names{iCond}, numel(in.onsets{iCond}),...
                    numel(in.durations{iCond}));
                return;
            end
            if any(in.onsets{iCond}<0)
                warning('ID:invalid_input',['%sCondition `%s` contains onset values ', ...
                    'smaller than zero'], errmsg, in.names{iCond});
                return;
            end
            if any(strcmpi(timeunits, {'samples', 'markers'})) && ...
                    any(in.onsets{iCond} ~= ceil(in.onsets{iCond}))
                warning('ID:invalid_input',['%sCondition `%s` contains non-integer ', ...
                    'onset values but is defined in %s'], ...
                    errmsg, in.names{iCond}, timeunits);
                return;
            end
            if strcmpi(timeunits, 'markers') && any(in.durations{iCond} ~= 0)
                warning('ID:invalid_input',['%sCondition `%s` contains non-zero ', ...
                    'durations - this is not allowed for marker time ', ...
                    'units. Please use ''samples'' or ', ...
                    '''seconds'' instead.'], errmsg, in.names{iCond});
                return;
            end
            if any(in.durations{iCond} < 0)
                warning('ID:invalid_input',['%sConditions `%s% contains ', ...
                    'negative durations.'], errmsg, in.names{iCond});
                return;
            end
            % collect all names from all sessions for later re-sorting
            name_idx = find(strcmpi(allnames, in.names{iCond}));
            if numel(name_idx) == 0
                if isempty(allnames)
                    allnames = in.names(iCond);
                else
                    allnames = [allnames, in.names(iCond)];
                end
            end
        end
        % check pmods:
        if isfield(in, 'pmod')
          % check consistency and add field
          if ~isstruct(in.pmod)
            warning('%sPmod must be a struct variable.', errmsg);
            return;
          elseif numel(in.pmod) > numel(in.names)
            warning(['%sNumber of parametric modulators (%d) ', ...
              'does not match the number of onsets (%d).'],...
              errmsg, numel(in.pmod),numel(in.onsets));  return;
          elseif ~isfield(in.pmod, 'param') || ~isfield(in.pmod, 'name')
            warning('%sFields are missing in pmod structure', errmsg);
            return;
          elseif ~isfield(in.pmod, 'poly')
            in.pmod(1).poly{1} = [];
          end
          % define new pmod struct with expanded polynomials
          in.pmodnew = struct('name', {}, 'param', {});
          % check individual pmods and expand polynomials
          for iPmod = 1:numel(in.pmod)
            iParamNew = 1;
            for iParam = 1:numel(in.pmod(iPmod).param)
              if numel(in.onsets{iPmod}) ~= ...
                  numel(in.pmod(iPmod).param{iParam})
                warning(['%s`%s` & `%s`: Number of event ', ...
                  'onsets (%d) does not equal the number of ', ...
                  'parameters (%d).'],...
                  errmsg, in.names{iPmod}, ...
                  in.pmod(iPmod).name{iParam}, ...
                  numel(in.onsets{iPmod}), ...
                  numel(in.pmod(iPmod).param{iParam}));

                return;
              end
              % set polynomial order if not specified
              if ~iscell(in.pmod(iPmod).poly) || ...
                  numel(in.pmod(iPmod).poly) < iParam || ...
                  isempty(in.pmod(iPmod).poly{iParam})
                in.pmod(iPmod).poly{iParam} = 1;
              end
              % expand
              for iPoly = 1:in.pmod(iPmod).poly{iParam}
                in.pmodnew(iPmod).param{iParamNew} = ...
                  (in.pmod(iPmod).param{iParam}).^iPoly;
                in.pmodnew(iPmod).name{iParamNew}  = ...
                  sprintf('%s^%d', ...
                  in.pmod(iPmod).name{iParam}, iPoly);
                iParamNew = iParamNew + 1;
              end
            end
          end
        end
        temptiming(iFile).names     = in.names;
        temptiming(iFile).onsets    = in.onsets;
        temptiming(iFile).durations = in.durations;
        if isfield(in, 'pmod')
          temptiming(iFile).pmod  = in.pmodnew;
        end
      end
      % ensure same names exist for all sessions and re-sort if
      % necesssary; collect number and names of all pmods
      outtiming = struct('names', {}, 'onsets', {}, 'durations', {});
      pmodname = {};
      try
          for iFile = 1:nFiles
              for iCond = 1:numel(allnames)
                  name_idx = find(strcmpi(temptiming(iFile).names, allnames{iCond}));
                  if numel(name_idx) > 1
                      warning('Names must be unique within each session.');
                      return;
                  elseif numel(name_idx) == 1
                      outtiming(iFile).onsets{iCond}    = temptiming(iFile).onsets{name_idx};
                      outtiming(iFile).durations{iCond}  = temptiming(iFile).durations{name_idx};
                      % assign pmods
                      if isfield(temptiming, 'pmod') && ...
                          ~isempty(temptiming(iFile).pmod) && ...
                           numel(temptiming(iFile).pmod) >= name_idx
                              outtiming(iFile).pmod(iCond)  = temptiming(iFile).pmod(name_idx);
                              % store pmod number and name for later use
                              pmodno(iFile, iCond) = numel(temptiming(iFile).pmod(name_idx).param);
                              % get pmodname from first session
                              if isempty(pmodname) || ...
                                      numel(pmodname) < iCond || ...
                                      isempty(pmodname{iCond})
                                    pmodname{iCond} = temptiming(iFile).pmod(name_idx).name;
                              end
                      else
                          pmodno(iFile, iCond) = 0;
                      end
                  elseif numel(name_idx) == 0
                      outtiming(iFile).onsets{iCond}    = [];
                      outtiming(iFile).durations{iCond}  = [];
                      pmodno(iFile, iCond) = 0;
                  end
                  outtiming(iFile).names{iCond}  = allnames{iCond};
              end
          end
          if nFiles > 1
              pmodno = max(pmodno);
          end
          % initialise pmods
          for iFile = 1:nFiles
              for iCond = 1:numel(allnames)
                  % insert pmods if they exist in other sessions
                  if pmodno(iCond) > 0 && ...
                          (numel(outtiming(iFile).pmod) < iCond || ...
                          isempty(outtiming(iFile).pmod(iCond).param))
                      for i_pmod = 1:pmodno(iCond)
                          outtiming(iFile).pmod(iCond).param{i_pmod} = [];
                          outtiming(iFile).pmod(iCond).name{i_pmod} = pmodname{iCond}{i_pmod};
                      end
                  end
              end
          end
      catch
          keyboard
      end

      % clear local variables
      clear iParam iParamNew iCond iFile iPmod
    else
      % create GLM file from markerinfo
      % ------------------------------------------------------------------------

      if ~iscell(intiming)
        tmp = intiming;
        clear intiming;
        intiming{1} = tmp;
      end

      nMarkers = numel(intiming);
      for iMarker = 1:nMarkers
        % check whether all fields are present and in correct format:
        if isstruct(intiming{iMarker})
          in = intiming{iMarker};
        else
          warning('ID:invalid_input','The elements of intiming must be structs or filenames');
          return;
        end

        if ~isfield(in, 'markerinfo')
          warning('ID:invalid_input', 'markerinfo must be a field in the struct');  return;
        elseif ~isfield(in, 'markervalues')
          warning('ID:invalid_input', 'markervalues must be a field in the struct'); return;
        elseif ~isfield(in, 'names')
          warning('ID:invalid_input', 'names must be a field in the struct'); return;
        end

        markerinfo = in.markerinfo;
        markervalue = in.markervalues;
        names =in.names;

        if ~isstruct(markerinfo)
          warning('ID:invalid_input', 'markerinfo must be a struct'); return;
        elseif ~isnumeric(markervalue) && ~iscell(markervalue)
          warning('ID:invalid_input', 'markervalue must be of type numeric or cell array '); return;
        elseif numel(names)~= numel(markervalue)
          warning('ID:invalid_input', 'markervalue and names must have the same amount of elements.'); return;
        end

        nCond = numel(markervalue);

        intiming{iMarker} = struct('names', {names}, 'onsets', {cell(nCond, 1)});

        for iCond = 1:nCond
          if isnumeric(markervalue)
            intiming{iMarker}.onsets{iCond} = find(markerinfo.value == markervalue(iCond));
            marker_value = markervalue(iCond);
            marker_value = int2str(marker_value);
          elseif iscell(markervalue)
            intiming{iMarker}.onsets{iCond} = find(strcmpi(markervalue{iCond}, markerinfo.name) == 1);
            marker_value = markervalue{iCond};
          end
          % give screen output: `n marker with value xx for condition xx found`
          n_marker = numel (intiming{iMarker}.onsets{iCond});
          fprintf('  %i markers with value %s for condition %s found. \n',n_marker, marker_value,names{iCond});
        end
      end
      [sts1, outtiming]  = pspm_get_timing('onsets', intiming, 'markers');
    end


    % Epoch information for SF and recursive call from option "missing"
    % ------------------------------------------------------------------------
  case 'epochs'
    % get epoch information from file or from input --
    if ischar(intiming)
      [lsts, in] = pspm_get_timing('file', intiming);
      if lsts < 1, return; end
      if isfield(in, 'epochs')
        outtiming = in.epochs;
      elseif isfield(in, 'onsets')
        onsets = in.onsets;
        if numel(onsets) == 2
          if numel(onsets{1}) == numel(onsets{2})
            outtiming(:, 1) = onsets{1};
            outtiming(:, 2) = onsets{2};
          else
            filewarning = 1;
          end
        else
          filewarning = 1;
        end
      else
        filewarning = 1;
      end
      if filewarning
        warning('File %s is not a valid epochs or onsets file', ...
          intiming);
        return;
      end
    else
      outtiming = intiming;
    end

    % check epoch information --
    if ~isempty(outtiming)
      if isnumeric(outtiming) && ismatrix(outtiming)
        if size(outtiming, 2) ~= 2
          warning(['Epochs must be specified by a e x 2 vector', ...
            'of onset/offsets.']);  return;
        else
            if any(diff(outtiming, [], 2) < 0)
                warning('Offsets must be larger than onsets.');  return;
            end
        end
      else
        warning('Unknown epoch definition format.');  return;
      end
    end

    % remove negative values
    if any(outtiming(:) < 0)
        indx = outtiming(:,2) < 0;
        outtiming(indx,:) = [];
        indx = outtiming(:,1) < 0;
        outtiming(indx,1) = 0;
    end

    % check time units --
    if any(strcmpi(timeunits, {'samples', 'markers'})) && ...
        ~all(outtiming(:) == ceil(outtiming(:)))
      warning('ID:no_integers', ['Non-integer epoch definition when ', ...
        'time units are ''%s'''], timeunits);  return;
    end

    % Missing epoch information for GLM and DCM
    % ------------------------------------------------------------------------
  case 'missing'
    [lsts, missepochs] = pspm_get_timing('epochs', intiming, timeunits);
     if lsts < 1, return; end
     % sort & merge missing epochs
    if size(missepochs, 1) > 0
      [~, sortindx] = sort(missepochs(:, 1));
      missepochs = missepochs(sortindx,:);
      % check for overlap and merge
      overlapindx = zeros(size(missepochs, 1), 1);
      for k = 2:size(missepochs, 1)
        if missepochs(k, 1) <= missepochs(k - 1, 2)
          missepochs(k, 1) =  missepochs(k - 1, 1);
          overlapindx(k - 1) = 1;
        end
      end
      missepochs(logical(overlapindx), :) = [];
    end
    outtiming = missepochs;

    % Event information for DCM
    % ------------------------------------------------------------------------
  case('events')
    if ischar(intiming)
      % recursive call to retrieve file
      [lsts, in] = pspm_get_timing('file', intiming);
      if lsts == -1, return; end
      if isfield(in, 'events')
        intiming = in.events;
      else
        warning('File must contain a variable called ''events''.');
        return;
      end
    end
    r = [];
    if isempty(intiming)
      warning('ID:invalid_input', 'No event data given.');
      return;
    elseif ~iscell(intiming)
         warning('ID:invalid_input', 'Timing information must be a cell array.');
      return;
    end
    for k = 1:numel(intiming)
      [r(k), c] = size(intiming{k});
      if c > 2
        warning('ID:invalid_vector_size', ...
          'Only one- and two-column vectors are allowed.');
        return;
      end
    end
    if any(r ~= r(1))
      warning('ID:invalid_vector_size', ...
        'All vectors must have the same number of rows.');

      return;
    end
    outtiming = intiming;
end

sts = 1;
return
