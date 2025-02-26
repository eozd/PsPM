function eyetrack_info = get_eyetrack_info(eyes_list, eye_filename_prefix, data_channels, ses_path, beh_json_filepath, recording_duration)
    beh_json = extract_json_as_struct(beh_json_filepath);

    eyesObserved = 'l';
    if length(eyes_list)==2
        eyesObserved = 'lr';
    elseif endsWith(eyes_list{1}, '2')
        eyesObserved = 'r';   
    end

    eyetrack_json_filename = [eye_filename_prefix, eyes_list{1}, '_physio.json'];
    eyetrack_json_filepath = fullfile(ses_path, eyetrack_json_filename);

    eyetrack_info = extract_json_as_struct(eyetrack_json_filepath);
    eyetrack_info.Columns = vertcat({'marker'}, data_channels);
    eyetrack_info.SOA = beh_json.SOA;
    eyetrack_info.duration = recording_duration;

    if strcmp(eyesObserved,'lr')
        eyetrack_info.RecordedEye = 'both';
    elseif strcmp(eyesObserved,'l')
        eyetrack_info.RecordedEye = 'left';
    else
        eyetrack_info.RecordedEye = 'right';
    end

    % redundant info for pspm functions
    eyetrack_info.source = struct();
    eyetrack_info.source.eyesObserved = eyesObserved;

end