function [sts, hist_str] = pspm_format_history(history_cell_array)
% ● Description
%   pspm_format_history returns a table-like formatted string using the
%   contents of the history cell array. This is the structure that exists
%   in infos.history field in PsPM files.
%   pspm_format_history expects a certain structure in the history fields.
%   In particular, the history entry should start with the operation performed
%   followed by '::'. Afterwards, all the remaining fields should be separated
%   by '--' delimiter. This structure is used in all PsPM preprocessing
%   functions starting in version 4.2.0. For earlier versions, this function
%   may not produce decent looking tables.
% ● Format
%   [sts, hist_str] = pspm_format_history(history_cell_array)
% ● Arguments
%   * history_cell_array: [cell array of strings] infos.history field in
%                         a PsPM file
% ● Outputs
%   * hist_str          : Formatted table string.
% ● History
%   Written in 2019 by Eshref Yozdemir (UZH)

%% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
header_indices = cell2mat(cellfun(@(x) strfind(x, '::'), history_cell_array, 'uni', false));
headers = {};
columns = {};
for i = 1:numel(history_cell_array)
  headers{end + 1} = history_cell_array{i}(1 : header_indices(i) - 1);
  columns{end + 1} = history_cell_array{i}(header_indices(i) + 2 : end);
end
table_mat = construct_cell_matrix_from_col_parts(headers, columns);
table_mat = make_each_cell_in_a_column_same_length(table_mat);
hist_str = format_as_table(table_mat, '-', '|');
%% Return status
sts = 1;
return
%% Function: construct_cell_matrix_from_col_parts
function table_mat = construct_cell_matrix_from_col_parts(headers, columns)
table_mat = {};
col_parts = cellfun(@(x) strsplit(x, '--'), columns, 'uni', false);
max_num_cols = max(cell2mat(cellfun(@(x) numel(x), col_parts, 'uni', false)));
for i = 1:numel(headers)
  table_mat{i, 1} = headers{i};
  for j = 1:max_num_cols
    if j <= numel(col_parts{i})
      cell_str = col_parts{i}{j};
    else
      cell_str = '';
    end
    table_mat{i, j + 1} = cell_str;
  end
end
end
%% Function: Make_each_cell_in_a_column_same_length
function table_mat = make_each_cell_in_a_column_same_length(table_mat)
max_strlen_in_col = [];
for j = 1:size(table_mat, 2)
  max_j = 0;
  for i = 1:size(table_mat, 1)
    max_j = max(max_j, numel(table_mat{i, j}));
  end
  max_strlen_in_col(end + 1) = max_j;
end
for i = 1:size(table_mat, 1)
  for j = 1:size(table_mat, 2)
    currlen = numel(table_mat{i, j});
    desiredlen = max_strlen_in_col(j);
    extra_whitespace = desiredlen - currlen;
    extra_left = floor(extra_whitespace / 2);
    extra_right = extra_whitespace - extra_left;
    table_mat{i, j} = [repmat(' ', 1, extra_left) table_mat{i, j} repmat(' ', 1, extra_right)];
  end
end
end
%% Function: Format as table
function table_str = format_as_table(cellmat, horzsep, vertsep)
[n_rows, n_cols] = size(cellmat);
lensum_of_cells_in_one_row = sum(cell2mat(cellfun(@(x) numel(x), cellmat(1, :), 'uni', false)));
horzlen = lensum_of_cells_in_one_row + n_cols + 1;
table_row_list = {};
table_row_list{end + 1} = repmat(horzsep, 1, horzlen);
for i = 1:size(cellmat, 1)
  curr_row = vertsep;
  empty_row = vertsep;
  for j = 1:size(cellmat, 2)
    empty_row = [empty_row repmat(' ', 1, numel(cellmat{i, j})) vertsep];
    curr_row = [curr_row cellmat{i, j} vertsep];
  end
  table_row_list{end + 1} = empty_row;
  table_row_list{end + 1} = curr_row;
  table_row_list{end + 1} = empty_row;

  table_row_list{end + 1} = repmat(horzsep, 1, horzlen);
end
table_str = join(table_row_list, '\n');
table_str = sprintf(table_str{1});
end
