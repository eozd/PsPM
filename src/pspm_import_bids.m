function [sts, outfile] = pspm_import_bids(dataset_path, save_path)
% ● Description
%   pspm_import_bids reads a BIDS-PP formatted dataset for a set of 
%   participants from a given data path and stores data as PsPM file(s).
% ● Format
%   [sts, outfile] = pspm_import_bids(dataset_path, save_path)
% ● Arguments
%    dataset_path:  path to the data set
%       save_path:  path to save the PsPM files
% ● Output
%         outfile:  cell array of generated PsPM file names
% ● History
%   Introduced in PsPM 7.0
%   Written in 2024 by Sourav Koulkarni & Dominik R Bach (Uni Bonn)

%% 1 Initialise -----------------------------------------------------------
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outfile = [];

if ~exist(save_path, 'dir')
    mkdir(save_path);
end

%% 2 Read meta information ------------------------------------------------
dataset_description = read_dataset_description(dataset_path);

[participants_data, participant_data_headings] = ...
    read_participants_data(dataset_path);

dataset_description.ParticipantInformation = participant_data_headings;

dataset_dir = dir(fullfile(dataset_path, 'sub-*'));
dataset_dir = dataset_dir(cellfun(@(x) x == 1, {dataset_dir.isdir}));

%% 3 loop over subjects ---------------------------------------------------
for i = 1:length(dataset_dir)
    
    subject_id = dataset_dir(i).name(5:end);
   
    fprintf('Importing %s ... \n', dataset_dir(i).name);

    sub_path = fullfile(dataset_path, dataset_dir(i).name);

    subject_dir = dir(sub_path);

    % Create cogent file - subject
    participant = struct();
    for p_info_ind = 1:numel(dataset_description.ParticipantInformation)
        field_name = dataset_description.ParticipantInformation{p_info_ind};
        participant.(field_name) = participants_data{p_info_ind}{str2double(subject_id)};
    end

    for j = 1:length(subject_dir)
        if startsWith(subject_dir(j).name, 'ses-') && subject_dir(j).isdir
            % For each session
            session_id = subject_dir(j).name(5:end);
            % disp(subject_dir(j).name);

            ses_path = fullfile(sub_path, subject_dir(j).name, 'beh');

            task_name = 'DelayFearConditioning';

            filenames = cell(1, 5);

            % ------------ Build file names ------------
            eyetrack_tsv_filename = sprintf('sub-%s_ses-%s_task-%s_eyetrack.tsv', subject_id, session_id, task_name);
            eyetrack_json_filename = sprintf('sub-%s_ses-%s_task-%s_eyetrack.json', subject_id, session_id, task_name);
            filenames{1} = eyetrack_tsv_filename;
            filenames{2} = eyetrack_json_filename;

            events_tsv_filename = sprintf('sub-%s_ses-%s_task-%s_events.tsv', subject_id, session_id, task_name);
            events_json_filename = sprintf('sub-%s_ses-%s_task-%s_events.json', subject_id, session_id, task_name);
            filenames{3} = events_tsv_filename;
            filenames{4} = events_json_filename;

            beh_json_filename = sprintf('sub-%s_ses-%s_task-%s_beh.json', subject_id, session_id, task_name);
            filenames{5} = beh_json_filename;

            % Check if any file is missing
            files_missing = checkFileMiss(ses_path, filenames);
            if files_missing
                warning('ID:invalid_input', 'Files missing');
                return
            end

            % ------------ Handle Data ------------
            % events
            events_tsv_filepath = fullfile(ses_path, events_tsv_filename);
            [event_data, event_data_headings] = read_event_data(events_tsv_filepath);
            event_data_struct = struct();
            for event_heading_ind = 1:numel(event_data_headings)
                event_data_heading = event_data_headings{event_heading_ind};
                event_data_struct.(event_data_heading) = event_data{event_heading_ind};
            end

            % eyetrack
            eyetrack_json_filepath = fullfile(ses_path, eyetrack_json_filename);
            eyetrack_json_jsondata = fileread(eyetrack_json_filepath);
            eyetrack_json = jsondecode(eyetrack_json_jsondata);
            dataset_description.EyeTrack = eyetrack_json;
            clear jsonData;

            eyetrack_tsv_filepath = fullfile(ses_path, eyetrack_tsv_filename);
            eyetrack_data = read_eyetrack_data(eyetrack_tsv_filepath);

            pupil_file_name = sprintf('%s_pupil_%s_sn%s.mat', dataset_description.Name, subject_id, session_id);
            pupil_filepath = fullfile(save_path, pupil_file_name);

            % TODO: Marker Data in PSPM format?
            pdata_sts = save_eyetrack_data(eyetrack_data, eyetrack_json, event_data_struct, pupil_filepath);
        end
        % cogent
        cogent_file_name = sprintf('%s_cogent_%s.mat', dataset_description.Name, subject_id);
        cogent_filepath = fullfile(save_path, cogent_file_name);

        saveCogent(participant, cogent_filepath)
    end
end
sts = 1;
end

%% 4 subfunctions ---------------------------------------------------------
function fileFound = isFileInDirectory(folderPath, fileName)
% List all items in the folder
items = dir(folderPath);

% Initialize a flag to indicate if the file is found
fileFound = false;

% Iterate through each item
for i = 1:length(items)
    % Get the name of the item
    itemName = items(i).name;
    
    % Check if the item name matches the specified file name
    if strcmp(itemName, fileName)
        % If it matches, set the flag to true and break the loop
        fileFound = true;
        break;
    end
end
end

function dataset_description = read_dataset_description(dataset_path)
dataset_description_filepath = fullfile(dataset_path, 'dataset_description.json');
data_desc_jsondata = fileread(dataset_description_filepath);
dataset_description = jsondecode(data_desc_jsondata);
end

function files_missing = checkFileMiss(folderPath, filenames)
files_missing = false;

for i = 1:numel(filenames)
    filename = filenames{i};
    
    if ~isFileInDirectory(folderPath, filename)
        fprintf('%s not found', filename);
        files_missing = true;
    end
    
end

if ~files_missing
    disp('All files found')
end
end

function [participants_data, column_headings] = read_participants_data(dataset_path)
participants_tsv_filepath = fullfile(dataset_path, 'participants.tsv');
% Open the file for reading
fileID = fopen(participants_tsv_filepath, 'r');

% Read the header line to determine the number of columns
header_line = fgetl(fileID);
num_columns = numel(strfind(header_line, char(9))) + 1; % Count tab characters + 1

column_headings = strsplit(header_line, '\t');

% Define the format specifier for each column
format_spec = repmat('%s', 1, num_columns);

% Read the data skipping the header line
participants_data = textscan(fileID, format_spec, 'Delimiter', '\t', 'HeaderLines', 0);

% Close the file
fclose(fileID);
end

function eyetrack_data = read_eyetrack_data(eyetrack_tsv_filepath)
% Read the TSV file into a table
eyetrack_data = readmatrix(eyetrack_tsv_filepath, 'FileType', 'text', 'Delimiter', '\t');

% Display the first few rows of the table
% disp(head(eyetrack_data));

end

function sts = save_eyetrack_data(eyetrack_data, eyetrack_json, event_data_struct, pupil_filepath)
sts = 0;
data_columns = eyetrack_json.data.Columns;

num_channels = length(data_columns) + 1;
pdata = cell(num_channels, 1);

for i=1:length(data_columns)
    % disp(data_columns(i));
    
    chan = struct();
    chan.header = struct();
    chan.header.chan_type = data_columns{i};
    chan.header.sr = eyetrack_json.data.(data_columns{i}).SamplingRate;
    chan.header.units = eyetrack_json.data.(data_columns{i}).Units;
    chan.data = eyetrack_data(:, i);
    
    % TODO: Get range for Gaze channels
    pdata{i+1} = chan;
end

pdata{1} = build_marker_channel(event_data_struct);

data = pdata;
infos = struct();
infos.duration = 800;                           % TODO: get correct duration
infos.durationInfo = 'Duration in seconds';
infos.source = struct();
infos.source.elcl_proc = eyetrack_json.ElclProc;
infos.source.best_eye = eyetrack_json.BestEye;
infos.source.eyesObservered = eyetrack_json.RecordedEye;
infos.eyetrackingGeometry = struct();
infos.eyetrackingGeometry.measurements = eyetrack_json.EyetrackingGeometry.distances;
infos.eyetrackingGeometry.units = eyetrack_json.EyetrackingGeometry.distanceUnits;
save(pupil_filepath, 'data', 'infos')
% disp('Saved Pupil')

sts = 1;
end

function [event_data, event_data_headings] = read_event_data(event_tsv_filepath)
% Open the file for reading
fileID = fopen(event_tsv_filepath, 'r');

% Read the header line to determine the number of columns
header_line = fgetl(fileID);
num_columns = numel(strfind(header_line, char(9))) + 1; % Count tab characters + 1
event_data_headings = strsplit(header_line, '\t');

% Define the format specifier for each column
format_spec = repmat('%s', 1, num_columns);

% Read the data skipping the header line
event_data = textscan(fileID, format_spec, 'Delimiter', '\t', 'HeaderLines', 0);

% Close the file
fclose(fileID);
end

function marker_channel = build_marker_channel(event_data_struct)
marker_channel = struct();
% --------- marker data ---------
time_delta = 3.0;  % TODO: Get correct time_delta
marker_data = cell(size(event_data_struct.onset));

% Iterate through each element in the onsets cell array
for i = 1:numel(event_data_struct.onset)
    % Add the predefined offset to each element and store it in marker_data
    marker_data{i} = str2double(event_data_struct.onset{i}) + time_delta;
end
marker_channel.data = marker_data;

% --------- marker info ---------
marker_channel.markerinfo = struct();
marker_channel.markerinfo.duration = event_data_struct.duration;
marker_channel.markerinfo.value = event_data_struct.event_type;
marker_channel.markerinfo.name = event_data_struct.identifier;

% --------- marker header ---------
marker_channel.header = struct();
marker_channel.header.chantype = 'marker';
marker_channel.header.sr = 1;
marker_channel.header.units = 'events';

end

function saveCogent(participantData, cogent_filepath)
subject = participantData;
save(cogent_filepath, 'subject')
% disp('Saved Cogent')
end



