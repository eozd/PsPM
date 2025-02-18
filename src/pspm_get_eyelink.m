function [sts, import, sourceinfo] = pspm_get_eyelink(datafile, import)
% ● Description
%   pspm_get_eyelink imports asc-exported SR Research Eyelink 1000 files.
%   Original eyelink output files (with extension *.edf) must first be 
%   converted to ASCII format (extension *.asc). This is done with the 
%   utility edf2asc.exe (normally included in the Eyelink software in 
%   <Path to Program Files>\SR Research\EyeLink\EDF_Access_API\). Otherwise 
%   there is a Data viewer, available at http://www.sr-research.com/dv.html 
%   (registration needed), which installs a utility called 
%   'Visual EDF2ASC'. This also supports the conversion and does not 
%   require a license.  
%   The sequence of channels depends on the acquisition settings, please check
%   in the ASCII file using text editor. Available channels are Pupil L, 
%   Pupil R, x L, y L, x R, y R, Blink L, Blink R, Saccade L, Saccade R. The 
%   channels will be imported according to a known data structure, therefore 
%   channel ids passed to the import function will be ignored. In the PsPM 
%   file, channels that were not available in the data file, will be filled 
%   with NaN values. Additionally, periods of blinks and saccades will be 
%   set to NaN during the import.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_eyelink(datafile, import);
% ● Arguments
%   ┌────────────import
%   ├───────────────.sr :  sampling rate
%   ├─────────────.data :  except for custom channels, the field .channel
%   │                      will be ignored. The id will be determined
%   │                      according to the channel type.
%   ├.eyelink_trackdist :  [optional] A numeric value representing the
%   │                      distance between camera and recorded eye.
%   │                      Disabled if 0 or negative.
%   │                      If it is a positive numeric value, causes the
%   │                      conversion from arbitrary units to distance unit
%   │                      according to the set distance.
%   └────.distance_unit :  [optional] The unit to which the data should be
%                          converted and in which eyelink_trackdist is given.
% ● Developer
%   In this function, channels related to eyes will not produce an error, if
%   they do not exist. Instead they will produce an empty channel (a channel
%   with NaN values only).
% ● History
%   Introduced in PsPM 3.0 and updated in PsPM 5.1.2
%   Written in 2008-2017 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
% add specific import path for specific import function
addpath(pspm_path('Import','eyelink'));

%% transfer options
reference_distance = 700;
reference_unit = 'mm';
diameter_multiplicator = 0.00087743;
area_multiplicator = 0.119;

%% load data with specific function
data = import_eyelink(datafile);

% expand blink/saccade channels with offset
% set data channels with blinks/saccades to NaN
% -------------------------------------------------------------------------
for i = 1:numel(data)-1
  if strcmpi(data{i}.eyesObserved, settings.eye.char.l)
    mask_chans = {'blink_l', 'saccade_l'};
  elseif strcmpi(data{i}.eyesObserved, settings.eye.char.r)
    mask_chans = {'blink_r', 'saccade_r'};
  elseif strcmpi(data{i}.eyesObserved, settings.eye.char.b)
    mask_chans = {'blink_l', 'blink_r', 'saccade_l', 'saccade_r'};
  else
    warning('ID:invalid_input', ['No valid eye marker is detected, please check input channels.']);
  end

  data{i}.channels = set_blinks_saccades_to_nan(...
    data{i}.channels, ...
    data{i}.channel_header, ...
    mask_chans ...
    );
end

% iterate through data and fill up channel list as long as there is no
% marker channel. if there is any marker channel, the settings accordingly
% markerinfo, markers and marker type.
% -------------------------------------------------------------------------

% ensure sessions have the same samplerate
% separate marker_data from real data
all_markers = data{end};
data = data(1:numel(data)-1);
sr = cell2mat(cellfun(@(d) d.sampleRate, data, 'UniformOutput', false));
eyesObs = cellfun(@(d) d.eyesObserved, data, 'UniformOutput', false);
if numel(data) > 1 && (any(diff(sr)) || any(~strcmp(eyesObs,eyesObs{1})))
  warning('ID:invalid_data_structure', ...
    ['Cannot concatenate multiple sessions with different ', ...
    'sample rate or different eye observation.']);
  % channels
  channels = data{1}.channels;
  % samplerate
  sampleRate = data{1}.sampleRate;
  % markers
  markers = (data{1}.markers-data{1}.raw(1,1))/sampleRate;
  % markerinfo
  markerinfo = data{1}.markerinfo;
  % units
  units = data{1}.units;
else
  % try to concatenate sessions according to timing
  sr = data{1}.sampleRate;
  last_time = data{1}.raw(1,1);

  channels = [];

  n_cols = size(data{1}.channels, 2);
  counter = 1;

  for c = 1:numel(data)
    if sr ~= data{c}.sampleRate
      warning('ID:invalid_input', ['File consists of multiple ', ...
        'sessions with different sample rates: Unable to concatenate sessions.']);
      return;
    end

    start_time = data{c}.raw(1,1);
    end_time = data{c}.raw(end,1);

    % time stamps are in miliseconds. if sampling rate different
    % then we have to correct for that otherwise break is too small/large
    n_diff = round((start_time - last_time)*sr/1000);
    if n_diff > 0

      % channels
      channels(counter:(counter+n_diff-1),1:n_cols) = NaN(n_diff, n_cols);
      counter = counter + n_diff;
    end

    n_data = size(data{c}.channels, 1);

    % channels and markers
    channels(counter:(counter+n_data-1),1:n_cols) = data{c}.channels;

    counter = counter + n_data;
    last_time = end_time;
  end

  % units (they should be the same for all sessions)
  units = data{1}.units;

  % samplerate
  sampleRate = sr;

  % markers (time stamps are in ms; convert to seconds)
  markers = (all_markers.markers-data{1}.raw(1,1))/1000;

  % markerinfo
  markerinfo = all_markers.markerinfo;

end


% create invalid data stats
n_data = size(channels,1);

% count blink and saccades (combined in blink channel at the moment)
blink_idx = find(strcmpi(units, 'blink'));
saccade_idx = find(strcmpi(units, 'saccade'));

%assumption that whenever blink_idx has more than one entry saccade will
%... have also more than one entry

bns_chans = [blink_idx saccade_idx];
for i_bns = 1:numel(bns_chans)
  channels(isnan(channels(:, bns_chans(i_bns))), bns_chans(i_bns)) = 0;
end

n_blink = sum (channels(:,blink_idx));
n_saccade= sum (channels(:,saccade_idx));

for k = 1:numel(import)

  if ~any(strcmpi(import{k}.type, ...
      settings.import.datatypes(strcmpi('eyelink', ...
      {settings.import.datatypes.short})).channeltypes))
    warning('ID:channel_not_contained_in_file', ...
      'Channel type ''%s'' is not supported.\n', ...
      import{k}.type);
    return;
  end

  if strcmpi(import{k}.type, 'marker')
    import{k}.marker = 'timestamps';
    import{k}.sr     = 1;
    import{k}.data   = markers;
    import{k}.markerinfo = markerinfo;
  else
    % determine channel id from channeltype - eyelink specific
    % thats why channel ids will be ignored!
    if strcmpi(pspm_eye(data{1}.eyesObserved, 'lr2c'), settings.lateral.char.c)
      chan_struct = {'pupil_l', 'pupil_r', 'gaze_x_l', 'gaze_y_l', ...
        'gaze_x_r', 'gaze_y_r','blink_l','blink_r','saccade_l','saccade_r'};
    else
      eye_obs = lower(data{1}.eyesObserved);
      chan_struct = {['pupil_' eye_obs], ['gaze_x_' eye_obs], ...
        ['gaze_y_' eye_obs], ['blink_' eye_obs],['saccade_' eye_obs]};
    end

    if strcmpi(import{k}.type, 'custom')
      channel = import{k}.channel;
    else
      channel = find(strcmpi(chan_struct, import{k}.type), 1, 'first');
    end

    if ~isempty(regexpi(import{k}.type, '_[lr]', 'once')) && ...
        isempty(regexpi(import{k}.type, ['_([' data{1}.eyesObserved '])'], 'once'))
      warning('ID:channel_not_contained_in_file', ...
        ['Cannot import channel type %s, as data for this eye', ...
        ' does not seem to be present in the datafile. ', ...
        'Will create artificial channel with NaN values.'], import{k}.type);

      % create NaN values for this channel
      import{k}.data = NaN(size(channels, 1),1);
      channel = -1;
      import{k}.units = '';
    else
      if channel > size(channels, 2)
        warning('ID:channel_not_contained_in_file', ...
          'Column %02.0f (%s) not contained in file %s.\n', ...
          channel, import{k}.type, datafile);
        return;
      end
      import{k}.data = channels(:, channel);
      import{k}.units = units{channel};
    end


    import{k}.sr = sampleRate;
    sourceinfo.channel{k, 1} = sprintf('Column %02.0f', channel);

    % channel specific stats
    sourceinfo.chan_stats{k,1} = struct();
    n_inv = sum(isnan(import{k}.data));
    sourceinfo.chan_stats{k}.nan_ratio = n_inv/n_data;

    % check for transfer if import type is a pupil
    if ~isempty(regexpi(import{k}.type, 'pupil', 'once'))
      if isfield(import{k}, 'eyelink_trackdist') && ...
          isnumeric(import{k}.eyelink_trackdist) && ...
          import{k}.eyelink_trackdist > 0 && ...
          ~isempty(import{k}.units)
        parts = split(import{k}.units);
        record_method = lower(parts{2});
        % transfer pupil data according to transfer settings
        if strcmpi(record_method, 'diameter')
          [~, import{k}.data] = pspm_convert_au2unit(...
            import{k}.data, import{k}.distance_unit, ...
            import{k}.eyelink_trackdist, record_method, ...
            diameter_multiplicator, ...
            reference_distance, ...
            reference_unit);
        elseif strcmpi(record_method, 'area')
          [~, import{k}.data] = pspm_convert_au2unit(...
            import{k}.data, import{k}.distance_unit, ...
            import{k}.eyelink_trackdist, record_method, ...
            area_multiplicator, ...
            reference_distance, ...
            reference_unit);
        else
          warning('ID:invalid_data_structure', ...
            'Calculated record method must be ''area'' or ''diameter''');
          return;
        end
        % set new unit to mm
        import{k}.units = import{k}.distance_unit;
      else
        warning('ID:invalid_input', ['Importing pupil in arbitrary units.'...
          ' You must pass a positive ''eyelink_trackdist'' so that pupil' ...
          ' in arbitrary units is converted to milimeters or ''distance_unit''']);
      end
      % store data range in header for gaze channels
    elseif ~isempty(regexpi(import{k}.type, 'gaze_x_', 'once'))
      import{k}.range = [data{1}.gaze_coords.xmin ...
        data{1}.gaze_coords.xmax];
    elseif ~isempty(regexpi(import{k}.type, 'gaze_y_', 'once'))
      import{k}.range = [data{1}.gaze_coords.ymin ...
        data{1}.gaze_coords.ymax];
    end

    % create statistics for eye specific channels
    if ~isempty(regexpi(import{k}.type, ['_[', settings.lateral.char.c, ']'], 'once'))
      if size(n_blink, 2) > 1
        eye_t = regexp(import{k}.type, ['.*_([', settings.lateral.char.c, '])'], 'tokens');
        n_eye_blink = n_blink(strcmpi(eye_t{1}, {settings.eye.char.l, settings.eye.char.r}));
      else
        n_eye_blink = n_blink;
      end
      sourceinfo.chan_stats{k}.blink_ratio = n_eye_blink / n_data;

      if size(n_saccade, 2) > 1
        eye_t = regexp(import{k}.type, ['.*_([',settings.lateral.char.c,'])'], 'tokens');
        n_eye_saccade = n_saccade(strcmpi(eye_t{1}, {settings.eye.char.l, settings.eye.char.r}));
      else
        n_eye_saccade = n_saccade;
      end
      sourceinfo.chan_stats{k}.saccade_ratio = n_eye_saccade / n_data;
    end
  end
end

% extract record time and date / should be in all sessions the same
sourceinfo.date = data{1}.record_date;
sourceinfo.time = data{1}.record_time;
% other record settings
sourceinfo.gaze_coords = data{1}.gaze_coords;
sourceinfo.elcl_proc = data{1}.elcl_proc;

% only imported eyes should be stated in eyesObserved
left_occurance = any(cell2mat(cellfun(@(x) ~isempty(regexpi(x.type, '_l', 'once')), import,'UniformOutput',0)));
right_occurance = any(cell2mat(cellfun(@(x) ~isempty(regexpi(x.type, '_r', 'once')), import,'UniformOutput',0)));
if left_occurance && right_occurance
  sourceinfo.eyesObserved = settings.eye.char.b;
elseif left_occurance && ~right_occurance
  sourceinfo.eyesObserved = settings.eye.char.l;
else
  sourceinfo.eyesObserved = settings.eye.char.r;
end

% determine best eye
switch sourceinfo.eyesObserved
  case settings.eye.char.l
    sourceinfo.best_eye = sourceinfo.eyesObserved;
  case settings.eye.char.r
    sourceinfo.best_eye = sourceinfo.eyesObserved;
  case settings.eye.char.b
    eye_stat = Inf(1,2);
    eye_choice = pspm_eye(sourceinfo.eyesObserved, 'char2cell');
    for i = 1:2
      e = eye_choice{i};
      e_stat = vertcat(sourceinfo.chan_stats{...
        cellfun(@(x) ~isempty(regexpi(x.type, ['_' e], 'once')), import)});
      if ~isempty(e_stat)
        eye_stat(i) = max([e_stat.nan_ratio]);
      end
    end
    [~, min_idx] = min(eye_stat);
    sourceinfo.best_eye = lower(eye_choice{min_idx});
end

% remove specific import path
rmpath(pspm_path('Import','eyelink'));
sts = 1;
return
