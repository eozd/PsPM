function [physio_data_cell, recording_duration, physio_info_data] = get_physio_data(subject_id, session_id, task_name, ses_path)
% Returns a 4x1 cell array where each cell contains a struct with fields header and data (and markerinfo for events)
% Also returns physio_info_data needed to create 'info' struct

% Initialize the physio data cell array
physio_signals = {'scr', 'ecg', 'resp', 'events'};
num_signals = length(physio_signals);
physio_data_cell = cell(num_signals, 1);  % Preallocate cell array

% Initialize variables for info
chan_names = cell(num_signals, 1);
file_paths = cell(num_signals, 1);

% Index to keep track of the cell array
cell_index = 1;

% Process each physio signal
for i = 1:num_signals - 1  % Exclude 'events' for now
    signal = physio_signals{i};

    % Construct filenames
    physio_json_filename = sprintf('sub-%s_ses-%s_task-%s_recording-%s_physio.json', subject_id, session_id, task_name, signal);
    physio_tsv_filename = sprintf('sub-%s_ses-%s_task-%s_recording-%s_physio.tsv', subject_id, session_id, task_name, signal);

    physio_json_filepath = fullfile(ses_path, physio_json_filename);
    physio_tsv_filepath = fullfile(ses_path, physio_tsv_filename);

    % Collect file paths for info
    file_paths{cell_index} = physio_tsv_filepath;

    % Check if files exist
    if ~isfile(physio_json_filepath)
        error('File not found: %s', physio_json_filepath);
    end
    if ~isfile(physio_tsv_filepath)
        error('File not found: %s', physio_tsv_filepath);
    end

    % Read JSON metadata
    physio_json = extract_json_as_struct(physio_json_filepath);

    % Read TSV data
    headings = physio_json.Columns;
    col_types = repmat({'double'}, 1, length(headings));
    physio_data_table = read_data_from_tsv(physio_tsv_filepath, false, headings.', col_types);

    % Create channel struct
    chan = struct();
    chan.header = struct();
    chan.header.chantype = signal;
    chan.header.sr = physio_json.SamplingFrequency;

    % Access Units field inside the signal-specific structure
    if isfield(physio_json, signal) && isfield(physio_json.(signal), 'Units')
        chan.header.units = physio_json.(signal).Units;
    else
        chan.header.units = 'unknown';
        warning('Units not specified in JSON file for %s. Setting units to "unknown".', signal);
    end

    % Assign data
    chan.data = physio_data_table.(headings{1});

    % Add to physio data cell array
    physio_data_cell{cell_index} = chan;

    % Collect channel names for info
    chan_names{cell_index} = signal;

    cell_index = cell_index + 1;
end

% Process event data
events_json_filename = sprintf('sub-%s_ses-%s_task-%s_events.json', subject_id, session_id, task_name);
events_tsv_filename = sprintf('sub-%s_ses-%s_task-%s_events.tsv', subject_id, session_id, task_name);

events_json_filepath = fullfile(ses_path, events_json_filename);
events_tsv_filepath = fullfile(ses_path, events_tsv_filename);

% Collect file path for events
file_paths{cell_index} = events_tsv_filepath;

% Check if event files exist
if ~isfile(events_tsv_filepath)
    error('Event TSV file not found: %s', events_tsv_filepath);
end

% Read events TSV
has_headings = true;
col_types = {'double', 'double', 'char', 'char'};
events_table = read_data_from_tsv(events_tsv_filepath, has_headings, [], col_types);

% Create marker data struct
marker_data = struct();
marker_data.data = events_table.onset;

% Create markerinfo struct
marker_data.markerinfo = struct();
marker_data.markerinfo.value = 1;
marker_data.markerinfo.name = 1;

% Create header
marker_data.header = struct();
marker_data.header.chantype = 'marker';
marker_data.header.units = 'events';
marker_data.header.sr = 1;

% Add to physio data cell array
physio_data_cell{cell_index} = marker_data;

% Collect channel name for events
chan_names{cell_index} = 'events';

% Get duration: last value of event time info
duration = events_table.onset(end);

% Prepare physio_info_data
physio_info_data = struct();
physio_info_data.chan_names = chan_names;
physio_info_data.file_paths = file_paths;
physio_info_data.duration = duration;

% Assume recording duration is the length of the SCR data divided by its sampling rate
recording_duration = length(physio_data_cell{1}.data) / physio_data_cell{1}.header.sr;
end
