function eyes = get_eyes_list(beh_folder_path)
    % Get list of all files in the directory
    files = dir(beh_folder_path);

    % Initialize an empty cell array to store eye types
    eyes = {};

    % Loop through each file in the directory
    for i = 1:length(files)
        % Get the filename
        filename = files(i).name;

        % Check if the filename matches the expected pattern
        % We assume that the file name contains '_recording-eye' followed by a number and '_physio.tsv'
        expression = 'recording-eye(\d)_physio.tsv';
        match = regexp(filename, expression, 'tokens');

        % If there is a match, extract the eye type
        if ~isempty(match)
            eyeType = ['eye' match{1}{1}]; % Extract '1' from 'eye1' and form 'eye1'
            eyes{end+1} = eyeType; % Add to the list of eyes
        end
    end

    % Get unique list of eyes
    eyes = unique(eyes);
end