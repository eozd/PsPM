function save_combined_dataset(combined_dataset, save_path)
disp('Saving combined dataset');

subjects = fieldnames(combined_dataset);

for i = 1:length(subjects)
    sub_key = subjects{i};
    sub_id = sub_key(end-2:end);

    % Create subject folder within the save_path
    subject_folder = fullfile(save_path, sub_key);
    if ~exist(subject_folder, 'dir')
        mkdir(subject_folder);
    end

    save_filename = sprintf('CALINET_sub-%s.mat', sub_id);
    save_filepath = fullfile(subject_folder, save_filename);

    subject_data = combined_dataset.(sub_key);

    % Prepare data to save
    data_to_save = struct();
    data_to_save.demographic = subject_data.demographic;

    % Collect sessions
    sessions = fieldnames(subject_data);
    sessions = sessions(startsWith(sessions, 'ses_'));

    for j = 1:length(sessions)
        ses_key = sessions{j};

        % Initialize session struct if not already present
        if ~isfield(data_to_save, ses_key)
            data_to_save.(ses_key) = struct();
        end

        % Add pupil data
        if isfield(subject_data.(ses_key), 'pupil')
            data_to_save.(ses_key).pupil = subject_data.(ses_key).pupil;
        end

        % Add physio data
        if isfield(subject_data.(ses_key), 'physio')
            data_to_save.(ses_key).physio = subject_data.(ses_key).physio;
        end
    end

    % Save the data
    save(save_filepath, '-struct', 'data_to_save');
    fprintf('Saved combined data for subject %s at %s\n', sub_id, save_filepath);
end

disp('Combined dataset saved successfully.');
end
