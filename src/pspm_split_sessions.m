function [sts, newdatafile, newepochfile] = pspm_split_sessions(datafile, options)
% ● Description
%   pspm_split_sessions splits a continuous recording into experimental 
%   sessions/blocks. This can be useful to suppress noise or artefacts that
%   occur in breaks (e.g. caused by participant movement or disconnection
%   from the recording system) which can have an impact on pre-processing 
%   (e.g. filtering) and modelling. 
%   Splitting can be automated, based on regularly incoming markers (e.g. trial 
%   markers or volume/slice markers from an MRI scanner), or based on 
%   a vector of split points that is defined in terms of markers. In all 
%   cases, the first and the last markers will define the start of the 
%   first session and the end of the last session.
%   In addition, the function can split a (missing) epochs file associated
%   with the original PsPM file to the same limits.
%   The individual session dat will be written to new files with a suffix 
%   '_sn' and the session number.
% ● Format
%   [sts, newdatafile, newepochfile] = pspm_split_sessions(datafile, options)
% ● Arguments
%   *        datafile :  a file name
%   ┌─────────options
%   ├.marker_chan_num : [integer] number of the channel holding the markers.
%   │                    By default first 'marker' channel.
%   ├──────.overwrite :  [logical] (0 or 1)
%   │                    Define whether to overwrite existing output files or not.
%   │                    Default value: determined by pspm_overwrite.
%   ├─────────.max_sn :  Define the maximum of sessions to look for.
%   │                    Default is 10 (defined by settings.split.max_sn)
%   ├.min_break_ratio :  Minimum for ratio
%   │                    [(session distance)/(maximum marker distance)]
%   │                    Default is 3 (defined by settings.split.min_break_ratio)
%   ├────.splitpoints :  [Vector of integer] Explicitly specify start of  
%   │                    each session in terms of markers, excluding the 
%   │                    first session which is assumed to start with the first marker.
%   ├─────────.prefix :  [numeric, unit:second, default: 0]
%   │                    Defines how many seconds of data before start trim point should
%   │                    also be included. Negative values required. 
%   │                    First marker will be at t = - prefix for all
%   │                    sessions. Markers within the prefix period will be dropped. 
%   ├─────────.suffix :  [positive numeric, unit:second, default: mean marker distance
%   │                    in the file] Defines how many seconds of data after the end trim point
%   │                    should be included. Last marker will be at t = duration (of
%   │                    session) - suffix for all sessions. If set to 0, suffix will be
%   │                    set to the mean marker distance across the entire
%   │                    file. Markers within the suffix period will be dropped.
%   ├───────.randomITI : [default:0]
%   │                    Tell the function to use all the markers to evaluate the mean
%   │                    distance between them. Usefull for random ITI since it reduces
%   │                    the variance.
%   ├─────────.verbose : [default:1] printing processing messages.
%   └─────────.missing : Optional name of an epoch file, e.g. containing a missing epochs
%                        definition in s. This is then split accordingly.
% ● Outputs
%   *      newdatafile : cell array of filenames for the individual sessions
%   *     newepochfile : cell array of missing epoch filenames for the individual
%                        sessions (empty if options.missing not specified).
% ● Developer
%   epochs have a fixed sampling rate of 10000
%   REMARK for suffix and prefix:
%   Markers in the prefix and suffix intervals are ignored. Only markers
%   between the splitpoints are considered for each session, to avoid
%   duplication of markers.
% ● History
%   Introduced in PsPM 5.1.1
%   Written in 2021 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Updated and maintained in 2022 by Teddy

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
newdatafile = [];
newepochfile = [];

% 1.1 Check input arguments
if nargin<1
  warning('ID:invalid_input', 'No data.\n');
  return;
elseif nargin < 2
  options = struct();
end

% 1.2 Set options
options = pspm_options(options, 'split_sessions');
if options.invalid
  return
end
% 1.3 Handle data files
% 1.3.1 check data file argument
if ~ischar(datafile)
  warning('ID:invalid_input', 'Data file must be a char.');
  return;
end

% 1.4 Check if prefix is positiv and suffix is negative
if options.prefix > 0
  warning('ID:invalid_input', 'Prefix must be negative.');
  return;
elseif options.suffix < 0
  warning('ID:invalid_input', 'Suffix must be positive.');
  return;
end

%% 2 Work on data file

% 2.1 Obtain data
if options.verbose
  fprintf('Splitting %s ... \n', datafile);
end
[sts_load_data, ininfos, indata, filestruct] = pspm_load_data(datafile); % check and get datafile ---
if sts_load_data < 1
  warning('ID:invalid_input', 'Could not load data.');
  return;
end


% 2.3 Handle markers

% 2.3.1 Define marker channel
[sts, mrkdata] = pspm_load_channel(struct('data', {indata}, 'infos', ininfos), options.marker_chan_num);
if sts < 1, return; end
mrk = mrkdata.data;

newdatafile = cell(0);
newepochfile = cell(0);

% 2.3.2 Find split points
if isempty(options.splitpoints)
  imi = sort(diff(mrk), 'descend');
  if min(imi)*options.min_break_ratio > max(imi)
    fprintf('  The file won''t be split. No possible split points found in marker channel %i.\n', options.marker_chan_num);
  elseif numel(mrk) <=  options.max_sn
    fprintf('  The file won''t be split. Not enough markers in marker channel %i.\n', options.marker_chan_num);
  end
  imi(1:(options.max_sn-1)) = [];
  cutoff = options.min_break_ratio * max(imi);
  splitpoint = find(diff(mrk) > cutoff)+1;
else
  splitpoint = options.splitpoints;
  if numel(mrk) < max(splitpoint)
    warning('ID:invalid_input', 'Splitpoint definition assumes more markers than there are in the file.');
    return
  end
end

% 2.3.3 Define trim points and adjust suffix
if isempty(splitpoint)
  return;
else
  % initialise
  prefix = num2cell(zeros(1,(numel(splitpoint)+1)));
  suffix = num2cell(zeros(1,(numel(splitpoint)+1)));
  for sn = 1:(numel(splitpoint)+1)
    if sn == 1
      trimpoint(sn, :) = [1, max(splitpoint(sn) - 1, 1)];
    elseif sn > numel(splitpoint)
      trimpoint(sn, :) = [max(splitpoint(sn - 1), 1), numel(mrk)];
    else
      trimpoint(sn, :) = [splitpoint(sn - 1), max(splitpoint(sn) - 1, 1)];
    end

    if options.suffix == 0
      if trimpoint(sn, 1) == trimpoint(sn, 2) || options.randomITI
        suffix{sn} = mean(diff(mrk));
      else
        suffix{sn}  = mean(diff(mrk(trimpoint(sn, 1):trimpoint(sn, 2))));
      end
    else
      suffix{sn} = options.suffix;
    end
    prefix{sn} = options.prefix;
  end

  % 2.4 Split files
  for sn = 1:size(trimpoint,1)
      % 2.4.1 Determine options & filenames
      trimoptions = struct('drop_offset_markers', 1, 'marker_chan_num', options.marker_chan_num);
      [p, f, ex] = fileparts(datafile);
      newdatafile{sn} = fullfile(p, sprintf('%s_sn%02.0f%s', f, sn, ex));
      if ~isempty(options.missing)
        [p_epochs, f_epochs, ex_epochs] = fileparts(options.missing);
        newepochfile{sn} = fullfile(p_epochs, sprintf('%s_sn%02.0f%s', f_epochs, sn, ex_epochs));
        trimoptions.missing = options.missing;
     end
    % 2.4.2 Split data
    [tsts, newdata, newmissingfile] = pspm_trim(struct('data', {indata}, 'infos', ininfos), ...
      prefix{sn}, suffix{sn}, trimpoint(sn, 1:2), trimoptions);
    if tsts < 1, return; end
    options.overwrite = pspm_overwrite(newdatafile{sn}, options);
    newdata.options = options;
    pspm_load_data(newdatafile{sn}, newdata);
    % 2.4.3 deal with missing epoch file
    if ~isempty(options.missing)
      [sts, epochs] = pspm_get_timing('epochs', newmissingfile, 'seconds');
      save(newepochfile{sn}, 'epochs');
      delete(newmissingfile);
    end
  end
end

sts = 1;
