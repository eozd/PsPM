function [sts, epochfile] = pspm_find_data_epochs(datafile, chan_id, options)
% pspm_find_data_epochs tries to find epochs of non-zero values in the data
% of a channel. It then writes it to a file depending on the input and
% returns the location of that file.
%
% FORMAT:
%   [sts, epochfile] = pspm_find_data_epochs(datafile, chan_id, options)
%
% ARGUMENTS:
%   datafile:           File which contains the corresponding channel to
%                       look for epochs.
%   chan_id:            Number or chantype of the the channel. If
%                       multiple channels match the specified chantype
%                       only the first found channel will be used.
%   options:
%       output_file:    Name and path to the output file. Default is the
%                       same as datafile but prepended with an 'e'.
%       overwrite:      Overwrite output file if it already exists. Default
%                       is 0.
%
% OUTPUT:
%   sts:                Return status of the function. If equals 1 no
%                       error or warnings were produced.
%   epochfile:          File where the epochs have been saved to.
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)

% $Id$
% $Rev$

% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;
sts = -1;

% check input
if ~exist('options', 'var')
    options = struct();
end

if ~isfield(options, 'output_file')
    [path, name, ext] = fileparts(datafile);
    options.output_file = [path, filesep, 'e', name, ext];
end

if ~isfield(options, 'overwrite')
    options.overwrite = 0;
end

if ~isfield(options, 'dont_ask_overwrite')
    options.dont_ask_overwrite = 0;
end

if isempty(datafile) || ~ischar(datafile)
    warning('ID:invalid_input', 'Datafile is empty or not a valid string.'); return;
elseif ~exist(datafile, 'file')
    warning('ID:invalid_input', 'Datafile (%s) does not exist.', datafile); return;
elseif ~isnumeric(chan_id) && ~ischar(chan_id)
    warning('ID:invalid_input', 'Chan_id is neither numeric nor a valid string.'); return;
elseif ~ischar(options.output_file)
    warning('ID:invalid_input', 'Options.output_file is not a valid string.'); return;
elseif ~islogical(options.overwrite) && ~isnumeric(options.overwrite)
    warning('ID:invalid_input', 'Options.overwrite is neither logical nor numeric.');
    return;
elseif ~islogical(options.dont_ask_overwrite) && ...
        ~isnumeric(options.dont_ask_overwrite)
    warning('ID:invalid_input', 'Options.overwrite is neither logical nor numeric.');
    return;
end

% load data
[~, ~, data] = pspm_load_data(datafile);

if chan_id > numel(data)
    warning('ID:invalid_input', 'Channel id exceeds channel count.'); return;
end

% create logical array in order to distinguish between non-zero and zero
logi = data{chan_id}.data ~= 0;
changes = diff(logi);

% find starts and stops
start = find(changes == 1) + 1;
stop = find(changes == -1);

% correct if data at the edges is non-zero
if ~isempty(start) || ~isempty(stop)
    if (isempty(stop) && ~isempty(start)) || (start(end) > stop(end))
        stop = [stop; numel(logi)];
    end

    if (isempty(start) && ~isempty(stop)) || (start(1) > stop(1))
        start = [1; start];
    end
end

% create epochs and divide by samplerate
epochs = ([start, stop]).*data{chan_id}.header.sr^-1;

file_exist = exist(options.output_file, 'file');
write_ok = false;
if file_exist
    if options.overwrite
        write_ok = true;
    elseif ~options.dont_ask_overwrite
        if feature('ShowFigureWindows')
            msg = ['File already exists. Overwrite?', newline, 'Existing file: ',options.output_file];
    	    ov = questdlg(msg, 'File already exists', 'Yes', 'No', 'Yes'); % default to overwrite by users
        else
            ov = 'Yes'; % default to overwrite on Jenkins
        end
        write_ok = strcmp(ov,'Yes');
    end
else
    write_ok = true;
end

if write_ok
    save(options.output_file, 'epochs');
end

epochfile = options.output_file;

sts = 1;
