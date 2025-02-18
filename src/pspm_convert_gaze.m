function [sts, outchannel] = pspm_convert_gaze(fn, conversion, options)
% ● Description
%   pspm_convert_gaze converts between any gaze units or scanpath speed.
%   Display width and height are required for conversion from pixels to relate
%   the screen pixel definition to metric units; and for conversion to
%   degrees, to translate the coordinate system to the centre of
%   the display.
% ● Format
%   [sts, channel_index] = pspm_convert_gaze(fn, conversion, options)
% ● Arguments
%   *             fn: A data file name
%   ┌─────conversion
%   ├──────────.from: Original units of the source channel pair to convert 
%   │                 from: 'pixel', a metric distance unit, or 'degree'. 
%   │                 If in doubt, use the function 'pspm_display' to 
%   │                 inspect the channels.
%   ├────────.target: Target unit of conversion: a metric distance unit,
%   │                 'degree' or 'sps'.
%   ├──.screen_width: Width of the display in mm (not required if 'from' is
%   │                 'degree', or if both source and target are metric).
%   ├─.screen_height: Height of the display in mm (not required if 'from' is
%   │                 'degree', or if both source and target are metric).
%   └.screen_distance: Eye distance from the screen in mm (not required
%                     if 'from' is 'degree', or if 'target' is metric).
%   ┌────────options
%   ├───────.channel: gaze x and y channels to work on. This can be a pair
%   │                 of channel numbers, any pair of channel types, 'gaze',
%   │                 which will search gaze_x and gaze_y channel according
%   │                 to the precedence order specified in pspm_load_channel.
%   │                 Default is 'gaze'.
%   └.channel_action: Channel action for sps data, add / replace existing sps
%                     data (default: add)
% ● Output
%   *  channel_index: index of channel containing the processed data
% ● History
%   Introduced in PsPM 4.3.1
%   Written in 2020 by Sam Maxwell (University College London)
%   Refactored 2024 by Dominik Bach (Uni Bonn)


%% Initialise
global settings
if isempty(settings)
    pspm_init;
end
sts = -1;
outchannel = 0;

% Number of arguments validation
if nargin < 2
    warning('ID:invalid_input','Not enough input arguments.'); return;
elseif nargin < 3
    options = struct();
end
options = pspm_options(options, 'convert_gaze');
if options.invalid
    return
end

% Input argument validation
if ~isfield(conversion, 'from') || ~ismember(conversion.from, {'pixel', 'mm', 'cm', 'm', 'inches', 'degree'})
    warning('ID:invalid_input:from', 'Conversion field ''from'' must be pixel, metric units, or degree.');
    return
elseif ~isfield(conversion, 'target') || ~ismember(conversion.target, { 'mm', 'cm', 'm', 'inches', 'degree', 'sps' })
    warning('ID:invalid_input:target', 'target conversion must be sps or degree');
    return
end
distance_required = (~strcmpi(conversion.from, 'degree') && ismember(conversion.target, {'degree', 'sps'}));
screen_length_required = strcmpi(conversion.from, 'pixel') || distance_required;
if screen_length_required && (~isfield(conversion, 'screen_height') || ~isnumeric(conversion.screen_height))
    warning('ID:invalid_input:height', 'screen_height must be numeric');
    return
elseif screen_length_required && (~isfield(conversion, 'screen_width') || ~isnumeric(conversion.screen_width))
    warning('ID:invalid_input:width', 'screen_width must be numeric');
    return
elseif distance_required && (~isfield(conversion, 'screen_distance') || ~isnumeric(conversion.screen_distance))
    warning('ID:invalid_input:distance', 'distance must be numeric');
    return
end

% bring conversion field names to workspace
names = fieldnames(conversion);
for i=1:length(names)
    eval([names{i}, '=conversion.', names{i}, ';' ]);
end

if strcmpi(from, 'pixel')
    screen_length = {screen_width, screen_height};
end

% Parse channel specification
channel = options.channel;
if isnumeric(channel) && numel(channel) == 1 && channel == 0
    channel = 'gaze';
end
if (iscell(channel) || isnumeric(channel)) && numel(channel) ~= 2
    warning('ID:invalid_input', 'This function operates on pairs of channels; two input channels required.');
    return
elseif isnumeric(channel)
    channel = num2cell(channel);
elseif ischar(channel)
    if strcmpi(channel, 'gaze')
        channel = {'gaze_x', 'gaze_y'};
    else
        warning('ID:invalid_input', 'This function operates on pairs of channels; two input channels required.');
        return
    end
elseif ~iscell(channel)
    warning('ID:invalid_input', 'Channel specification not recognised');
    return
end

% load data & check units
[lsts, alldata.infos, alldata.data] = pspm_load_data(fn);
if lsts < 1, return, end
channelunits_list = cellfun(@(x) x.header.units, alldata.data, 'uni', false);
channels_correct_units = find(contains(channelunits_list, from));
channeltypes = {'gaze_x', 'gaze_y'};
data = {};
for i = 1:numel(channel)
    % for numeric channel specification, check if it has the right units
    if isnumeric(channel{i})
        if ismember(channel{i}, channels_correct_units)
            [lsts, data{i}, infos, pos_of_channel(i)] = pspm_load_channel(alldata, channel{i}, 'gaze');
             if lsts < 1, return, end
        else
            warning('ID:invalid_input', 'Channel %i is in units "%s", expected was "%s".', ...
                channel{i}, alldata.data{channel{i}}.header.units, from);
            return
        end
    else
        % for channeltype specification, just consider channels in the correct units
        gazedata = struct('infos', alldata.infos, 'data', {alldata.data(channels_correct_units)});
        warning off
        [lsts, data{i}, infos, pos_of_channel(i)] = pspm_load_channel(gazedata, channel{i}, channeltypes{i});
        warning on
        if lsts < 1
            warning('ID:invalid_input', 'Either there is no gaze channel in the file, or all gaze channels are in the incorrect units.')
            return;
        end
        % map channel index from list of channels with correct units to list of all channels
        pos_of_channel(i) = channels_correct_units(pos_of_channel(i)); 
    end
end

% find eye of channels to use
eye = {};
for i = 1:2
    [sts, eye{i}] = pspm_find_eye(data{i}.header.chantype);
end

if ~strcmpi(eye{1}, eye{2})
    warning('ID:invalid_input', 'The specified pair of channels seems to come from different eyes. Please check if this is intended.')
    eye = '';
elseif strcmpi(eye{1}, '')
    eye = '';
else
    eye = ['_', eye{1}];
end

% convert data to metric units unless already in degree
for i = 1:numel(channel)
    if strcmpi(conversion.from, 'pixel')
        [data{i}.data, data{i}.header.range] = pspm_convert_pixel2unit_core(data{i}.data, data{i}.header.range, screen_length{i});
    elseif ~strcmpi(conversion.from, 'degree')
        [lsts, data{i}.data] = pspm_convert_unit(data{i}.data, data{i}.header.units, 'mm');
        if lsts < 1, return, end
    end
    if ~ismember(target, {'degree', 'sps'})
        [lsts, data{i}.data] = pspm_convert_unit(data{i}.data, 'mm', target);
        if lsts < 1, return, end
        data{i}.header.units = target;
    else
        data{i}.header.units = 'mm';
    end
end

% convert data to non-metric target units if requested
if ismember(target, {'degree', 'sps'})
    data_x = data{1}.data;
    data_y = data{2}.data;
    if ~strcmpi(from, 'degree')
        [data_x, data_y, data_x_range, data_y_range] = pspm_convert_visual_angle_core(data_x, data_y, screen_width, screen_height, screen_distance);
        if numel(data_x) == 1 && data_x == 0, return; end
    else
        data_x_range = data{1}.header.range;
        data_y_range = data{1}.header.range;
    end
end
if strcmp(target, 'degree')
    outdata = data;
    outdata{1}.data = data_x;
    outdata{1}.header.units = 'degree';
    outdata{1}.header.range = data_x_range;
    outdata{2}.data = data_y;
    outdata{2}.header.units = 'degree';
    outdata{2}.header.range = data_y_range;
elseif strcmp(target, 'sps')
    sr = data{1}.header.sr;
    arclen = pspm_convert_visangle2sps_core(data_x, data_y);
    outdata = {};
    outdata{1}.data = rad2deg(arclen) .* sr;
    outdata{1}.header.chantype = strcat('sps', eye);
    outdata{1}.header.sr = sr;
    outdata{1}.header.units = 'degree';
else
    outdata = data;
end

[sts, out] = pspm_write_channel(fn, outdata, options.channel_action, struct('channel', pos_of_channel));
outchannel = out.channel;
