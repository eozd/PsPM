function [sts, data_struct, infos, pos_of_channel, chantype_sts] = ...
    pspm_load_channel(fn, channel, channeltype)
% ● Definition
%   pspm_load_channel loads a single data channel and provides integrated
%   channel checking logic
% ● Format
%   [sts, data_struct, infos, pos_of_channel, chantype_correct] = pspm_load_channel(fn, channel, channeltype)
% ● Arguments
%   *      fn : the filename, can be either a string or a struct (as below).
%   ┌──────fn
%   ├──.infos : The information of the channel.
%   └───.data : The data of the channel.
%   * channel : [numeric] / [char] / [struct]
%               ▶ numeric: returns this channel (or the first of a vector)
%               ▶ char
%                 'marker'  returns the first marker channel
%                           (see settings for permissible channel types)
%                 any other channel type (e.g. 'scr')
%                           returns the last channel of the respective type
%                           (see settings for permissible channel types)
%                 'pupil', 'sps', 'gaze_x', 'gaze_y', 'blink', 'saccade',
%                 'pupil_missing' (eyetracker channels)
%                           goes through the following precedence order,
%                           selects the first category that is found in the
%                           data, and returns the last channel of this
%                           category
%                           1.  Combined channels (e.g., 'pupil_c')
%                           2.  Non-lateralised channels (e.g., 'pupil')
%                           3.  Best eye pupil channels
%                           4.  Any pupil channels
%               ▶ struct: with two fields as following
%                 (1) .channel: as defined for the 'char' option above;
%                 (2) .units: units of the channel.
%   * channeltype: [char] optional; any channel type as permitted per pspm_init,
%                 'wave', or 'events': checks whether retrieved data channel
%                is of the specified type and gives a warning if not
% ● Outputs
%   *            sts : [logical] 1 as default, -1 if unsuccessful.
%   *    data_struct : a struct with fields .data and .header, corresponding to a single
%                      cell of a data cell array returned by pspm_load_data.
%   *          infos : file infos as returned from pspm_load_data.
%   * pos_of_channel : index of the returned channel.
% ● History
%   Written in 2019 by Eshref Yozdemir (University of Zurich)
%   Updated in 2024 by Dominik Bach (University of Bonn)
%   Introduced in PsPM 6.1.2
% ● Developer's notes
%   No checking of file and channel type here as this is done downstream in
%   pspm_load_data

% initialise
global settings;
if isempty(settings)
  pspm_init;
end
sts = -1; data_struct = struct(); pos_of_channel = -1; chantype_sts = NaN;

% expand channel if defined as struct
if isstruct(channel)
    units = channel.units;
    channel = channel.channel;
else
    units = [];
end

% expand channel if zero
if isnumeric(channel) && channel == 0
    if nargin > 2
        channel = channeltype;
    else
        warning('ID:invalid_input', 'Channel not specified.')
        return
    end
end

if isempty(units)
    [sts, infos, data, filestruct] = pspm_load_data(fn, channel);
    if sts < 1, return; end
    channel_index = filestruct.posofchannels;
else
    [sts, infos, data] = pspm_load_data(fn);
    if sts < 1, return; end
    [sts, data, channel_index] = pspm_select_channels(data, channel, units);
    if sts < 1, return; end
end

% precedence order for eyetracker channels
if ~isnumeric(channel) && ismember(channel, settings.eyetracker_channels)
    channeltype_list = cellfun(@(x) x.header.chantype, data, 'uni', false);
    combined_channels = find(contains(channeltype_list, ['_' settings.lateral.char.c]));
    global_channels = find(strcmp(channeltype_list, channel));
    if isfield(infos.source, 'best_eye')
        best_channels = find(contains(channeltype_list, ['_' infos.source.best_eye]));
    else
        best_channels = [];
    end
    if ~isempty(combined_channels)
        data = data(combined_channels);
        fprintf('L-R-combined channel(s) of type ''%s'' identified and will be used.\n', channel)
        channel = sprintf('combined %s', channel);
        channel_index = channel_index(combined_channels);
    elseif ~isempty(global_channels)
        data = data(global_channels);
        fprintf('Non-lateralised channel(s) of type ''%s'' identified and will be used.\n', channel)
        channel = sprintf('non-lateralised %s', channel);
        channel_index = channel_index(global_channels);
    elseif ~isempty(best_channels)
        data = data(best_channels);
        fprintf('Best eye channel(s) of type ''%s'' identified and will be used.\n', channel)
        channel = sprintf('best eye %s', channel);
        channel_index = channel_index(best_channels);
        % else data is left unchanged
    else
        fprintf('Lateralised channel(s) of type ''%s'' identified and will be used.\n', channel)
        channel = sprintf('lateralised %s', channel);
    end
end

% if more than one channel exists, select first/last channel and give message
if numel(data) == 0
    warning('ID:invalid_input', 'No data of type %s contained in file %s.', ...
        channel, fn);
elseif numel(data) == 1
    data_struct = data{1};
    pos_of_channel = channel_index(1);
elseif ischar(channel)
    if strcmp(channel, 'marker')
        data_struct = data{1};
        pos_of_channel = channel_index(1);
        keyword = 'first';
    else
        data_struct = data{end};
        pos_of_channel = channel_index(end);
        keyword = 'last';
    end
    fprintf('More than one channel of type ''%s'' exists. The %s one will be used.\n', ...
        channel, keyword)
else
    data_struct = data{1};
    pos_of_channel = channel_index(1);
    fprintf('More than one channel provided. The first one will be used.\n')
end

% if channeltype is given, check if channel is of correct type
if nargin > 2
    warning('off', 'all');
    chantype_sts = pspm_select_channels({data_struct}, channeltype);
    warning('on', 'all');
    if chantype_sts < 1
        warning('ID:unexpected_channeltype', ...
            'Channel type ''%s'' was expected. The retrieved channel is of type ''%s''.', ...
            channeltype, data_struct.header.chantype);
    end
end



