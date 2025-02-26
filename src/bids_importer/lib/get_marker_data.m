function marker_data = get_marker_data(events_json_filepath, events_tsv_filepath)

    has_headings = true;
    headings = [];
    col_types = {'double', 'double', 'char', 'char'};

    maker_tsv_data_table = read_data_from_tsv(events_tsv_filepath, has_headings, headings.', col_types );

    % marker_data = maker_tsv_data_table;

    marker_data = struct();

    % --------- onsets ---------
    time_delta = 0.0;  % TODO: Get correct time_delta
    onsets = zeros(size(maker_tsv_data_table.onset));

    % Iterate through each element in the onsets cell array
    for i = 1:numel(maker_tsv_data_table.onset)
        % Add the predefined offset to each element and store it in marker_data
        onsets(i) = maker_tsv_data_table.onset(i) + time_delta;
    end
    marker_data.data = onsets;

    % --------- marker info ---------
    marker_data.markerinfo = struct();
    marker_data.markerinfo.duration = maker_tsv_data_table.duration;
    marker_data.markerinfo.value = maker_tsv_data_table.trial_type;
    marker_data.markerinfo.name = maker_tsv_data_table.stimulus_name;
    
    % --------- marker header ---------
    marker_data.header = struct();
    marker_data.header.chantype = 'marker';
    marker_data.header.sr = 1;
    marker_data.header.units = 'events';
end