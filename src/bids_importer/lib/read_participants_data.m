function [participants_data, column_headings] = read_participants_data(dataset_path)
    % Construct the full path to the participants.tsv file
    participants_tsv_filepath = fullfile(dataset_path, 'phenotype', 'participants.tsv');
    
    % Check if the file exists
    if ~isfile(participants_tsv_filepath)
        error('The participants.tsv file does not exist at the specified path: %s', participants_tsv_filepath);
    end

    % Open the file for reading
    fileID = fopen(participants_tsv_filepath, 'r');
    
    % Check if the file was successfully opened
    if fileID == -1
        error('Could not open participants.tsv file at path: %s', participants_tsv_filepath);
    end

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
