function save_data_file(filepath, data, infos, subject_info)
% Save data and infos into a .mat file
if nargin == 4
    % Add subject information to the infos struct
    infos.subject = subject_info;
end
save(filepath, 'data', 'infos');
end
