function [eyetrack_data_cell_array, data_channels, recording_duration] = get_eyetrack_data(eye_list, eye_filename_prefix, ses_path, events_json_filepath, events_tsv_filepath)
    eyetrack_data_cell_array = {};

    % Get data channels list
    data_channels = {};
    for i=1:length(eye_list)
        eye_name = eye_list{i};
        eye_suffix = '_l';
        
        if strcmp(eye_name, 'eye2')
            eye_suffix = '_r';
        end

        eyetrack_json_filename = [eye_filename_prefix, eye_name, '_physio.json'];
        eyetrack_json_filepath = fullfile(ses_path, eyetrack_json_filename);

        eyetrack_json = extract_json_as_struct(eyetrack_json_filepath);

        headings = eyetrack_json.Columns;

        if length(headings) == 0
            eye_list{i} = NaN;
            continue;
        end

        % Replace 'pupil_size' by 'pupil'
        pupil_col_index = find(strcmp(headings, 'pupil_size'));
        if ~isempty(pupil_col_index)
            headings{pupil_col_index} = 'pupil';
        end

        % Replace 'x_coordinate' by 'gaze_x'
        pupil_col_index = find(strcmp(headings, 'x_coordinate'));
        if ~isempty(pupil_col_index)
            headings{pupil_col_index} = 'gaze_x';
        end

        % Replace 'y_coordinate' by 'gaze_y'
        pupil_col_index = find(strcmp(headings, 'y_coordinate'));
        if ~isempty(pupil_col_index)
            headings{pupil_col_index} = 'gaze_y';
        end

        % add suffix to column names
        headings = cellfun(@(x) [x eye_suffix], headings, 'UniformOutput', false);

        data_channels = vertcat(data_channels, headings);
    end

    eye_list = eye_list(cellfun('isclass', eye_list, 'char'));

    % Extract eyetrack data for each eye and combine
    num_channels = length(data_channels) + 1;
    eyetrack_data_cell_array = cell(num_channels, 1);

    col_types = repmat({'double'}, 1, width(data_channels.'));

    channel_index = 1;
    for i=1:length(eye_list)
        eye_name = eye_list{i};
        eye_suffix = '_l';
        
        if strcmp(eye_name, 'eye2')
            eye_suffix = '_r';
        end

        eyetrack_tsv_filename = [eye_filename_prefix, eye_name, '_physio.tsv'];
        eyetrack_tsv_filepath = fullfile(ses_path, eyetrack_tsv_filename);

        eyetrack_json_filename = [eye_filename_prefix, eye_name, '_physio.json'];
        eyetrack_json_filepath = fullfile(ses_path, eyetrack_json_filename);

        eyetrack_json = extract_json_as_struct(eyetrack_json_filepath);
        headings = eyetrack_json.Columns;

        has_headings = false;

        col_types = repmat({'double'}, 1, width(headings.')); 

        eyetrack_tsv_data_table = read_data_from_tsv(eyetrack_tsv_filepath, has_headings, headings.', col_types);
    
        % ---- construct channels and add them to eyetrack data cell array ----
        for i=1:length(headings)
            chan = struct();
            chan.header = struct();
            chan.header.chantype = data_channels{channel_index};
            chan.header.sr = eyetrack_json.SamplingFrequency;
            if startsWith(headings{i}, 'pupil')
                chan.header.units = 'mm';
            else
                chan.header.units = 'pixel';
            end
            chan.data = eyetrack_tsv_data_table.(headings{i});
    
            if startsWith(data_channels{channel_index}, 'gaze_x')
                chan.header.range = [eyetrack_json.GazeRange.xmin, eyetrack_json.GazeRange.xmax];
            end
    
            if startsWith(data_channels{channel_index}, 'gaze_y')
                chan.header.range = [eyetrack_json.GazeRange.ymin, eyetrack_json.GazeRange.ymax];
            end
            
            eyetrack_data_cell_array{channel_index+1} = chan;
            
            channel_index = channel_index + 1;
        end
    end

    if ~check_channel_lengths(eyetrack_data_cell_array)
        warning('Channel lengths not equal');
    end
    recording_duration = length(eyetrack_data_cell_array{2}.data)/eyetrack_data_cell_array{2}.header.sr;
    % ---- marker channels ----
    eyetrack_data_cell_array{1} = get_marker_data(events_json_filepath, events_tsv_filepath);
end

function chan_size_equal = check_channel_lengths(eyetrack_data_cell_array)
    
    channel_lengths = zeros(1, numel(eyetrack_data_cell_array)-1);

    for channel_index = 2:length(eyetrack_data_cell_array)
        current_chan = eyetrack_data_cell_array{channel_index};
        chan_size = size(current_chan.data);
        channel_lengths(channel_index-1) = chan_size(1);
    end

    % function to check if all channels have equal lengths
    if isempty(channel_lengths) || numel(channel_lengths) == 1
        chan_size_equal = true;
        return;
    end
    
    % Check if all elements are equal
    chan_size_equal = all(channel_lengths == channel_lengths(1));
end