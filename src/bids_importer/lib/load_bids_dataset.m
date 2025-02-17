function combined_dataset = load_bids_dataset(dataset_source)
% LOAD_BIDS_DATASET loads both pupil and physio data from BIDS-formatted data.

combined_dataset = struct();

% Read participant data
[participants_data, participants_data_headings] = read_participants_data(dataset_source);

% Extract subject key from the dataset source path
[~, sub_key] = fileparts(dataset_source);  % Extract the folder name
sub_key = strrep(sub_key, '-', '_');

combined_dataset.(sub_key) = struct();

subject_id = sub_key(end-2:end);
sub_path = dataset_source;
subject_dir = dir(sub_path);

% Get subject info
combined_dataset.(sub_key).demographic = get_subject_data(participants_data, participants_data_headings, subject_id);

% Process each session
for j = 1:length(subject_dir)
    if startsWith(subject_dir(j).name, 'ses-') && subject_dir(j).isdir
        ses_dir_name = subject_dir(j).name;
        ses_key = strrep(ses_dir_name,'-','_');
        combined_dataset.(sub_key).(ses_key) = struct();
        session_id = subject_dir(j).name(5:end);
        ses_path = fullfile(sub_path, subject_dir(j).name, 'beh');
        task_name = 'DelayFearConditioning';

        % ------------ Load Pupil Data ------------
        eyes_list = get_eyes_list(ses_path);
        eye_filename_prefix = sprintf('sub-%s_ses-%s_task-%s_recording-', subject_id, session_id, task_name);
        events_json_filename = sprintf('sub-%s_ses-%s_task-%s_events.json', subject_id, session_id, task_name);
        events_json_filepath = fullfile(ses_path, events_json_filename);
        events_tsv_filename = sprintf('sub-%s_ses-%s_task-%s_events.tsv', subject_id, session_id, task_name);
        events_tsv_filepath = fullfile(ses_path, events_tsv_filename);
        beh_json_filename = sprintf('sub-%s_ses-%s_task-%s_beh.json', subject_id, session_id, task_name);
        beh_json_filepath = fullfile(ses_path, beh_json_filename);

        % Get eyetrack data
        [eyetrack_data, data_channels, recording_duration] = get_eyetrack_data( ...
            eyes_list, eye_filename_prefix, ses_path, events_json_filepath, events_tsv_filepath);
        eyetrack_info = get_eyetrack_info(eyes_list, eye_filename_prefix, data_channels, ses_path, beh_json_filepath, recording_duration);

        % Store pupil data
        combined_dataset.(sub_key).(ses_key).pupil.data = eyetrack_data;
        combined_dataset.(sub_key).(ses_key).pupil.infos = eyetrack_info;

        % ------------ Load Physio Data ------------
        % Get physio data and info data
        [physio_data_cell, recording_duration, physio_info_data] = get_physio_data(subject_id, session_id, task_name, ses_path);
        physio_infos = struct();
        physio_infos.importdate = datestr(now, 'dd-mmm-yyyy');
        physio_infos.duration = physio_info_data.duration;
        physio_infos.durationinfo = 'seconds';
        physio_infos.source = struct();
        physio_infos.source.chan = physio_info_data.chan_names;
        physio_infos.source.type = 'acq';
        physio_infos.source.file = physio_info_data.file_paths;

        % Store physio data
        combined_dataset.(sub_key).(ses_key).physio.data = physio_data_cell;
        combined_dataset.(sub_key).(ses_key).physio.infos = physio_infos;
    end
end
end
