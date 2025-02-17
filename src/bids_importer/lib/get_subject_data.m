function subject_info = get_subject_data(data, keys, sub_id)
    subject_info = struct();
    for ind = 1:numel(keys)
        key = keys{ind};
        val = data{ind};
        subject_info.(key) = val; 
    end
end
