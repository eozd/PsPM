function [data] = import_eyelink(filepath)
% import_eyelink is the function for importing Eyelink 1000 .asc files to usual
% PsPM structure.
%
% FORMAT: [data] = import_eyelink(filepath)
%             filepath: Path to the file which contains the recorded Eyelink
%                       data in ASCII format (.asc).
%
%             data: Output cell array of structures. Each entry in the cell array
%                   corresponds to one recording session in the datafile.
%                   Each of these structures have the following entries:
%
%                       raw: Matrix containing raw data columns.
%                       channels: Matrix (timestep x n_cols) of relevant PsPM columns.
%                                 Currently, time, pupil, gaze, blink and saccade channels
%                                 are imported.
%                       channel_header: Column headers of each channels column.
%                       units: Units of each channels column.
%                       eyesObserved: Either A or AB, denoting observed eyes in datafile.
%                       gaze_coords: Structure with fields
%                           - xmin: x coordinate of top left corner of screen in pixels.
%                           - ymin: y coordinate of top left corner of screen in pixels.
%                           - xmax: x coordinate of bottom right corner of screen in pixels.
%                           - ymax: y coordinate of bottom right corner of screen in pixels.
%                       markers: Sample number of any detected marker
%                       markerinfo: Structure with the following fields:
%                           - name: Cell array of marker name.
%                           - value: Index of the marker name to an array containing
%                                    unique marker names.
%                       elcl_proc: Pupil tracking algorithm. (ellipse or centroid)
%                       record_date: Recording date
%                       record_time: Recording time
%__________________________________________________________________________
%
% (C) 2019 Eshref Yozdemir

if ~exist(filepath,'file')
  error('ID:invalid_input', sprintf('Passed file %s does not exist.', filepath));
end

% parse datafile
% --------------
bsearch_path = pspm_path('ext', 'bsearch');
addpath(bsearch_path);
[dataraw, messages, chan_info, file_info] = parse_eyelink_file(filepath);
markers_sess = {};
for i = 1:numel(messages)
  [dataraw{i}, markers_sess{i}, chan_info{i}] = parse_messages(messages{i}, dataraw{i}, chan_info{i});
end
rmpath(bsearch_path);

% write outputs
% -------------
markers_sess = create_marker_val_fields(markers_sess); % create marker values from unique names
for sn = 1:numel(dataraw)
  data{sn}.raw = dataraw{sn};
  data{sn}.channels = data{sn}.raw(:, chan_info{sn}.col_idx);
  data{sn}.channel_header = chan_info{sn}.channel_header;
  data{sn}.units = chan_info{sn}.channel_units;

  data{sn}.sampleRate = chan_info{sn}.sr;
  data{sn}.eyesObserved = chan_info{sn}.eyesObserved;

  data{sn}.record_date = file_info.record_date;
  data{sn}.record_time = file_info.record_time;

  data{sn}.gaze_coords.xmin = chan_info{sn}.xmin;
  data{sn}.gaze_coords.ymin = chan_info{sn}.ymin;
  data{sn}.gaze_coords.xmax = chan_info{sn}.xmax;
  data{sn}.gaze_coords.ymax = chan_info{sn}.ymax;
  data{sn}.elcl_proc = chan_info{sn}.elcl_proc;

  data{sn}.markers = markers_sess{sn}.times;
  data{sn}.markerinfo.name = markers_sess{sn}.names;
  data{sn}.markerinfo.value = markers_sess{sn}.vals;
end
data{end + 1} = combine_markers(markers_sess);

session_end_times = calc_session_end_times(messages);
for i = 1:numel(data) - 1
  [data{i}.markers, data{i}.markerinfo] = remove_markers_beyond_end(...
    data{i}.markers, data{i}.markerinfo, session_end_times{i}, data{1}.raw(1,1));
end
[data{end}.markers, data{end}.markerinfo] = remove_markers_beyond_end(...
    data{end}.markers, data{end}.markerinfo, session_end_times{end}, data{1}.raw(1,1));
end

function [markers_out, markerinfos_out] = remove_markers_beyond_end(markers, markerinfo, sess_end_time, first_sess_start)
mask = (markers <= sess_end_time) & (markers > first_sess_start);
markers_out = markers(mask);
markerinfos_out = markerinfo;
markerinfos_out.name = markerinfos_out.name(mask);
markerinfos_out.value = markerinfos_out.value(mask);
end

function session_end_times = calc_session_end_times(session_messages)
out = {};
for i = 1:numel(session_messages)
  for j = 1:numel(session_messages{i})
    msg = session_messages{i}{j};
    if strcmp(msg(1:3), 'END')
      parts = strsplit(msg);
      out{end + 1} = str2num(parts{2});
      break
    end
  end
end
session_end_times = out;
end

function [dataraw, messages, chan_info, file_info] = parse_eyelink_file(filepath)
% Parse an eyelink file and return all the relevant information in four variables:
% dataraw: Cell array of matrices containing raw data columns for each session.
% messages: All the messages in the file, including blinks/saccades.
% chan_info: Cell array of struct holding info about each session.
% file_info: Struct holding info about the whole file.

str = fileread(filepath);
has_backr = ~isempty(find(str == sprintf('\r'), 1, 'first'));
linefeeds = [0, strfind(str, sprintf('\n'))];

line_ctr = 1;
[file_info, line_ctr] = parse_metadata(str, line_ctr, linefeeds, has_backr);

while isempty(str(linefeeds(line_ctr) + 1 : linefeeds(line_ctr + 1) - 1 - has_backr))
  line_ctr = line_ctr + 1;
end

linefeeds = linefeeds(line_ctr : end);
str = str(linefeeds(1) + 1 : end);
linefeeds = linefeeds - linefeeds(1);
line_ctr = 1;

[msg_linenums, messages] = get_msg_lines(str, linefeeds, has_backr);
[msg_linenums, messages] = split_messages_to_sessions(msg_linenums, messages);
chan_info = parse_session_headers(messages);
% TODO: assert that session configs are the same
chan_info = pspm_chans_in_file(chan_info);

for i = 1:numel(msg_linenums)
  for msg_line = msg_linenums{i}
    begidx = linefeeds(msg_line) + 1;
    str(begidx : begidx + 1) = '/';
  end
end

session_data_beg_end_indices = [];
for i = 1:numel(chan_info)
  linenums_i = msg_linenums{i};
  msg_line_diff = diff(linenums_i);
  msg_indices_jump_idx = find(msg_line_diff > 1, 1, 'first');
  first_dataline_idx = linenums_i(msg_indices_jump_idx) + 1;
  line_content = str(linefeeds(first_dataline_idx) + 1 : linefeeds(first_dataline_idx + 1) - 1 - has_backr);
  step = 0;
  while isempty(line_content)
    step = step + 1;
    msg_indices_jump_idx_full = find(msg_line_diff > 1);
    msg_indices_jump_idx = msg_indices_jump_idx_full(step+1);
    first_dataline_idx = linenums_i(msg_indices_jump_idx) + 1;
    line_content = str(linefeeds(first_dataline_idx) + 1 : linefeeds(first_dataline_idx + 1) - 1 - has_backr);
  end
  session_data_beg_end_indices(end + 1) = first_dataline_idx;
end
session_data_beg_end_indices = [session_data_beg_end_indices numel(linefeeds)];

for i = 1:numel(chan_info)
  first_dataline_idx = session_data_beg_end_indices(i);
  first_dataline = str(linefeeds(first_dataline_idx) + 1 : linefeeds(first_dataline_idx + 1) - 1 - has_backr);
  fmt_str = infer_format_from_eyelink_dataline(first_dataline, chan_info{i}.track_mode);

  strbeg = linefeeds(session_data_beg_end_indices(i)) + 1;
  strend = linefeeds(session_data_beg_end_indices(i + 1)) - 1 - has_backr;

  C = textscan(str(strbeg : strend), fmt_str, ...
    'Delimiter', '\t', ...
    'CollectOutput', 1, ...
    'CommentStyle', '//', ...
    'TreatAsEmpty', '.');
  dataraw{i} = C{1};
end
end

function [file_info, line_ctr] = parse_metadata(str, line_ctr, linefeeds, has_backr)
file_info.record_date = '00.00.0000';
file_info.record_time = '00:00:00';
curr_line = str(linefeeds(line_ctr) + 1 : linefeeds(line_ctr + 1) - 1 - has_backr);
tab = sprintf('\t');
while strncmp(curr_line, '**', numel('**'))
  if contains(curr_line, 'DATE')
    colon_idx = strfind(curr_line, ':');
    date_part = curr_line(colon_idx(1) + 1 : end);
    date_fmt = 'eee MMM d HH:mm:ss yyyy';
    date = datetime(date_part, 'InputFormat', date_fmt);
    file_info.record_date = sprintf('%.2d.%.2d.%.2d', date.Day, date.Month, date.Year);
    file_info.record_time = sprintf('%.2d:%.2d:%.2d', date.Hour, date.Minute, date.Second);
  end
  line_ctr = line_ctr + 1;
  curr_line = str(linefeeds(line_ctr) + 1 : linefeeds(line_ctr + 1) - 1 - has_backr);
end
end

function chan_info = pspm_chans_in_file(chan_info)
global settings;
if isempty(settings), pspm_init; end
for i = 1:numel(chan_info)
  pupil_mode = chan_info{i}.diam_vals;
  eyesObserved = chan_info{i}.eyesObserved;
  pupil_unit = ['arbitrary ' lower(pupil_mode) ' units'];
  switch eyesObserved
    case {settings.lateral.char.l, settings.lateral.cap.l}
      chan_info{i}.channel_header = {'pupil_l', 'gaze_x_l', 'gaze_y_l'};
      chan_info{i}.channel_units = {pupil_unit, 'pixel', 'pixel'};
      chan_info{i}.col_idx = [4, 2, 3];
    case {settings.lateral.char.r, settings.lateral.cap.r}
      chan_info{i}.channel_header = {'pupil_r', 'gaze_x_r', 'gaze_y_r'};
      chan_info{i}.channel_units = {pupil_unit, 'pixel', 'pixel'};
      chan_info{i}.col_idx = [4, 2, 3];
    case {'lr','rl','LR','RL'}
      chan_info{i}.channel_header = {'pupil_l', 'pupil_r', 'gaze_x_l', 'gaze_y_l', 'gaze_x_r', 'gaze_y_r'};
      chan_info{i}.channel_units = {pupil_unit, pupil_unit, 'pixel', 'pixel', 'pixel', 'pixel'};
      chan_info{i}.col_idx = [4, 7, 2, 3, 5, 6];
    otherwise
      error('ID:pspm_error', 'This branch should not have been taken. Please contact PsPM dev team');
  end
end
end

function [msg_linenums, messages] = get_msg_lines(str, linefeeds, has_backr)
% Extract messages from a string holding all the content of the file
linebeg_indices = linefeeds(1 : end - 1) + 1;
linebegs = int32(str(linebeg_indices));
ord_A = int32('A');
ord_Z = int32('Z');
msg_linenums = find(linebegs >= ord_A & linebegs <= ord_Z);

messages = {};
for msg_line = msg_linenums
  begidx = linefeeds(msg_line) + 1;
  endidx = linefeeds(msg_line + 1) - 1 - has_backr;
  messages{end + 1} = str(begidx : endidx);
end
end

function [dataraw, markers, chan_info] = parse_messages(messages, dataraw, chan_info)
% Find blinks/saccades and non-Eyelink messages in the file.
markers = struct();
if isempty(messages)
  return;
end
eyes = lower(chan_info.eyesObserved);
tab = sprintf('\t');
if contains(eyes, 'l')
  blinks_L = false(size(dataraw, 1), 1);
  saccades_L = false(size(dataraw, 1), 1);
end
if contains(eyes, 'r')
  blinks_R = false(size(dataraw, 1), 1);
  saccades_R = false(size(dataraw, 1), 1);
end

sblink_indices = find(strncmp(messages, 'SBLINK', numel('SBLINK')));
eblink_indices = find(strncmp(messages, 'EBLINK', numel('EBLINK')));
ssacc_indices = find(strncmp(messages, 'SSACC', numel('SSACC')));
esacc_indices = find(strncmp(messages, 'ESACC', numel('ESACC')));
% MSG refers to ethernet input using python eyelink library, and INPUT to 
% parallel/serial port input
msg_indices = strncmp(messages, 'MSG', numel('MSG')) | ...
    strncmp(messages, 'INPUT', numel('INPUT'));
for name = {'RECCFG', 'ELCLCFG', 'GAZE_COORDS', 'THRESHOLDS', 'ELCL_', 'PUPIL_DATA_TYPE', '!MODE'}
  msg_indices = msg_indices & ~contains(messages, name);
end
msg_indices = find(msg_indices);

timecol = dataraw(:, 1);
session_end_time = timecol(end);

[messages, eblink_indices] = balance_starts_and_ends(sblink_indices, eblink_indices, messages, 'EBLINK', session_end_time);
[messages, esacc_indices] = balance_starts_and_ends(ssacc_indices, esacc_indices, messages, 'ESACC', session_end_time);

% set blink and saccade events
for idx = [eblink_indices esacc_indices]
  msgline = messages{idx};
  parts = split(msgline);

  msgtype = parts{1};
  which_eye = lower(parts{2});
  start_time = str2num(parts{3});
  end_time = str2num(parts{4});

  index_of_beg = bsearch(timecol, start_time);
  index_of_end = bsearch(timecol, end_time);
  if strcmp(msgtype, 'ESACC') && which_eye == 'l'
    saccades_L(index_of_beg : index_of_end) = true;
  elseif strcmp(msgtype, 'ESACC') && which_eye == 'r'
    saccades_R(index_of_beg : index_of_end) = true;
  elseif strcmp(msgtype, 'EBLINK') && which_eye == 'l'
    blinks_L(index_of_beg : index_of_end) = true;
  elseif strcmp(msgtype, 'EBLINK') && which_eye == 'r'
    blinks_R(index_of_beg : index_of_end) = true;
  end
end

% construct markers
markers.times = [];
markers.names = {};
for idx = msg_indices
  msgline = messages{idx};
  parts = split(msgline);
  time = str2num(parts{2});
  markers.times(end + 1, 1) = time;
  markers.names{end + 1, 1} = cell2mat(join(parts(3:end), ' '));
end

% set data columns
if contains(eyes, 'l')
  chan_info.col_idx(end + 1) = size(dataraw, 2) + 1;
  chan_info.channel_header{end + 1} = 'blink_l';
  chan_info.channel_units{end + 1} = 'blink';
  dataraw(:, end + 1) = blinks_L;
end
if contains(eyes, 'r')
  chan_info.col_idx(end + 1) = size(dataraw, 2) + 1;
  chan_info.channel_header{end + 1} = 'blink_r';
  chan_info.channel_units{end + 1} = 'blink';
  dataraw(:, end + 1) = blinks_R;
end
if contains(eyes, 'l')
  chan_info.col_idx(end + 1) = size(dataraw, 2) + 1;
  chan_info.channel_header{end + 1} = 'saccade_l';
  chan_info.channel_units{end + 1} = 'saccade';
  dataraw(:, end + 1) = saccades_L;
end
if contains(eyes, 'r')
  chan_info.col_idx(end + 1) = size(dataraw, 2) + 1;
  chan_info.channel_header{end + 1} = 'saccade_r';
  chan_info.channel_units{end + 1} = 'saccade';
  dataraw(:, end + 1) = saccades_R;
end
end

function [msg_linenums_split, messages_split] = split_messages_to_sessions(msg_linenums, messages)
start_indices = [0 find(strncmp(messages, 'START', numel('START')))];
reccfg_indices = find(contains(messages, 'RECCFG'));

split_indices = [];
if numel(reccfg_indices) > numel(start_indices)
  for i = 1:numel(start_indices) - 1
    candidates = find(reccfg_indices > start_indices(i) & reccfg_indices < start_indices(i + 1));
    split_indices(end + 1) = reccfg_indices(candidates(1));
  end
else
  split_indices = reccfg_indices;
end
split_indices = [split_indices numel(messages) + 1];

for i = 1:numel(split_indices) - 1
  begidx = split_indices(i);
  endidx = split_indices(i + 1) - 1;
  messages_split{i} = messages(begidx : endidx);
  msg_linenums_split{i} = msg_linenums(begidx : endidx);
end
end

function chan_info = parse_session_headers(messages)
prev_n_messages = 0;
pupil_str = sprintf('PUPIL\t');
global  settings;
for sess_idx = 1:numel(messages)
  i = 1;
  while true
    msg = messages{sess_idx}{i};
    parts = split(msg);

    if strncmp(msg, 'START',numel('START'))
      chan_info{sess_idx}.start_time = str2num(parts{2});
      chan_info{sess_idx}.start_msg_idx = prev_n_messages + i;
    elseif contains(msg, 'GAZE_COORDS')
      parts = split(msg);
      coords = cellfun(@str2num, parts(4:end));
      chan_info{sess_idx}.xmin = coords(1);
      chan_info{sess_idx}.ymin = coords(2);
      chan_info{sess_idx}.xmax = coords(3);
      chan_info{sess_idx}.ymax = coords(4);
    elseif contains(msg, 'ELCL_PROC')
      parts = split(msg);
      chan_info{sess_idx}.elcl_proc = lower(parts{4});
    elseif contains(msg, 'RECCFG')
      parts = split(msg);
      chan_info{sess_idx}.track_mode = parts{4};
      chan_info{sess_idx}.sr = str2num(parts{5});
      chan_info{sess_idx}.eyesObserved = parts{end};
      if ~any(structfun( @(x) strcmpi(chan_info{sess_idx}.eyesObserved  , x), settings.eye.cap ) )
         warning(['Parsing Error: The value for "eyesObserved"' ...
             ' must be ''R'', ''L'', ''RL'', or ''LR''.']);
      end

    elseif contains(msg, pupil_str)
      parts = split(msg);
      chan_info{sess_idx}.diam_vals = lower(parts{2});
      break;
    end
    i = i + 1;
    prev_n_messages = prev_n_messages + numel(messages{sess_idx});
  end
end
end

function fmt = infer_format_from_eyelink_dataline(first_dataline, track_mode)
% Infer the textscan format to use for a session from a sample dataline in
% that session.
tab = sprintf('\t');
parts = split(first_dataline);
fmt = '%f';
for i = 2:numel(parts)
  if numel(parts{i}) == 1
    partfmt = '%f';
  elseif all(parts{i} == '.') || any(parts{i} >= 'A' & parts{i} <= 'Z') || any(parts{i} >= 'a' & parts{i} <= 'z')
    partfmt = '%*s';
  else
    partfmt = '%f';
  end
  fmt = [fmt tab partfmt];
end
end

function [messages, end_indices] = balance_starts_and_ends(beg_indices, end_indices, messages, event_name, session_end_time)
% If for some reason there are more event beginnings than ends, insert
% pseudo event ends that correspond to session end times.
if numel(beg_indices) > numel(end_indices)
  extra = setdiff(beg_indices, end_indices);
  for idx = extra
    parts = split(messages{idx});
    which_eye = parts{2};
    beg_time = str2num(parts{3});
    end_time = session_end_time;

    messages{end + 1} = sprintf('%s %c %d (ADDED BY PSPM)', event_name, which_eye, end_time);
    end_indices(end + 1) = numel(messages);
  end
end
end

function markers_sess = create_marker_val_fields(markers_sess)
all_marker_names = {};
for i = 1:numel(markers_sess)
  all_marker_names = [all_marker_names; markers_sess{i}.names];
end
unique_names = unique(all_marker_names);
for i = 1:numel(markers_sess)
  markers_sess{i}.vals = [];
  [~, markers_sess{i}.vals] = ismember(markers_sess{i}.names, unique_names);
end
end

function all_markers_struct = combine_markers(markers_sess)
all_markers_struct = struct();
all_marker_names = {};
for i = 1:numel(markers_sess)
  all_marker_names = [all_marker_names; markers_sess{i}.names];
end
all_markers_struct.markers = [];
all_markers_struct.markerinfo.value = [];
all_markers_struct.markerinfo.name = all_marker_names;
for i = 1:numel(markers_sess)
  all_markers_struct.markers = [all_markers_struct.markers; markers_sess{i}.times];
  all_markers_struct.markerinfo.value = [all_markers_struct.markerinfo.value; markers_sess{i}.vals];
end
end
