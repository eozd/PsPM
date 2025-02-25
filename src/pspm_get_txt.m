function [sts, import, sourceinfo] = pspm_get_txt(datafile, import)
% ● Description
%   pspm_get_txt imports text files with the following specifications: The
%   file can only contain numbers (i.e. no header lines, such as channel 
%   names) and one data column per channel. Data must use the decimal
%   point. Any delimiter can be used; the delimiter is set in the import 
%   structure (default: whitespace). At the moment, import of event 
%   markers is not supported.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_txt(datafile, import);
% ● Arguments
%   * datafile : a .txt-file containing numerical data (with any delimiter) and optionally
%                the channel names in the first line.
%   ┌───import
%   ├────.type : A char array corresponding to a valid PsPM data type, see `pspm_init.m`
%   │            for more details.
%   ├─.channel : A numeric value representing the column number of the corresponding
%   │            numerical data.
%   ├.delimiter :
%   │            [optional] A char array corresponding to the delimiter used in the
%   │            datafile to delimit data columns. To be used it should be specified on
%   │            the first import cell, e.g.: import{1}.delimiter == ','. Default:
%   │            white-space (see textscan function).
%   ├─.header_lines :
%   │            [optional] A numeric value corresponding to the number of header lines.
%   │            Which means the data start on line number: "header_lines + 1". To be
%   │            used it should be specified on the first import cell,
%   │            e.g.: import{1}.header_lines == 3. Default: 1.
%   ├─.channel_names_line :
%   │            [optional] A numeric value corresponding to the line number where the
%   │            channel names are specified. To be used it should be specified
%   │            on the first import cell, e.g. import{1}.channel_names_line == 2
%   │            Default: 1.
%   └─.exclude_columns :
%                [optional] A numeric value corresponding to the number of columns to
%                exclude starting from the left. To be used it should be specified on
%                the first import cell, e.g. import{1}.exclude_columns == 2. Default: 0.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%              2020 Ivan Rojkov (UZH) - added dsv support
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];

% check import structure options
% -------------------------------------------------------------------------
if ~isfield(import{1}, 'delimiter') || isempty(import{1}.delimiter)
   delim = 0;
elseif ~ischar(import{1}.delimiter)
   warning('ID:invalid_input','The ''delimiter'' option should be a char array.')
   return;
else
   delim = import{1}.delimiter;
end

if ~isfield(import{1}, 'header_lines')
   header_lines = 1;
elseif ~isnumeric(import{1}.header_lines)
   warning('ID:invalid_input','The ''header_lines'' option should be a numeric value.')
   return;
else
   header_lines = import{1}.header_lines;
end

if ~isfield(import{1}, 'channel_names_line')
   channel_names_line = 1;
   if header_lines < channel_names_line, channel_names_line=0; end
elseif ~isnumeric(import{1}.channel_names_line)
   warning('ID:invalid_input','The ''channel_names_line'' option should be a numeric value.')
   return;
else
   channel_names_line = import{1}.channel_names_line;
end

if ~isfield(import{1}, 'exclude_columns')
   exclude_columns = 0;
elseif ~isnumeric(import{1}.exclude_columns)
   warning('ID:invalid_input','The ''exclude_columns'' option should be a numeric value.')
   return;
else
   exclude_columns = import{1}.exclude_columns;
end

% read channel names
% -------------------------------------------------------------------------
fid = fopen(datafile);

% go to the specific line to read the channel names
if channel_names_line ~= 0
    for k=1:channel_names_line-1
      fgetl(fid); % read and dump
    end
end

if ischar(delim)
    channel_names = textscan(fgetl(fid), '%s',  'Delimiter', delim);
else
    channel_names = textscan(fgetl(fid), '%s');
end
channel_names = channel_names{1};

fclose(fid);

% load & check data
% -------------------------------------------------------------------------
fid = fopen(datafile);

formatSpec = repmat('%f', 1, numel(channel_names));
if exclude_columns
    formatSpec = repmat('%*s', 1, exclude_columns);
    formatSpec = [formatSpec,repmat('%f', 1,numel(channel_names)-exclude_columns)];
end

if ischar(delim)
    data = textscan(fid, formatSpec, 'HeaderLines', header_lines, 'Delimiter', delim);
else
    data = textscan(fid, formatSpec, 'HeaderLines', header_lines);
end

fclose(fid);

try
    data = cell2mat(data);
    if isempty(data), error('The imported data are empty.'); end
catch
    warning('ID:textscan_error','An error occured while reading a textfile.\n');
    return;
end

%  warning('An error occured while reading a textfile.\n'); return; end

% select desired channels
% -------------------------------------------------------------------------
for k = 1:numel(import)
    % define channel number
    if import{k}.channel > 0
        channel = import{k}.channel;
    elseif channel_names_line ~= 0
        channel = pspm_find_channel(channel_names, import{k}.type);
        if channel < 1, return; end
    else
        warning('ID:invalid_input', ...
                ['Neiter ''channel'' nor ''channel_names_line'' options were specified.', ...
                 ' Not able to import the data.'])
        return;
    end

    if channel > size(data, 2), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end

    import{k}.data = data(:, channel);

    if isfield(import{k},'typeno') && strcmpi(settings.channeltypes(import{k}.typeno).data, 'events')
        import{k}.marker = 'continuous';
    end

    sourceinfo.channel{k} = sprintf('Data column %02.0', channel);
end

sts = 1;
return
