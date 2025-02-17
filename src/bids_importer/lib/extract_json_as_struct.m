function json_struct = extract_json_as_struct(json_file_path)
    jsondata = fileread(json_file_path);
    json_struct = jsondecode(jsondata);
end
