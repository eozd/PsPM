function data = read_data_from_tsv(tsv_filepath, has_headings, headings, col_types)
opts = detectImportOptions(tsv_filepath, 'FileType', 'text', 'Delimiter', '\t');

if ~has_headings
    opts.VariableNamingRule = 'preserve';
    opts.VariableNames = headings;
    opts.DataLines = [1 inf]; % Read all data lines
    opts.EmptyLineRule = 'read';
end

opts.VariableTypes = col_types;

data = readtable(tsv_filepath, opts);

end
