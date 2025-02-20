function [sts, channel_index] = pspm_gaze_pp(fn, options)
% ● Description
%   pspm_gaze_pp combines left/right gaze x and gaze y channels at
%   the same time and will add two combined gaze channels, for the x and y
%   coordinate.
% ● Format
%   [sts, channel_index] = pspm_gaze_pp(fn)
%   [sts, channel_index] = pspm_gaze_pp(fn, options)
% ● Arguments
%   *             fn: [string] Path to the PsPM file which contains the gaze data.
%   ┌────────options
%   ├───────.channel: gaze_x_r/gaze_x_l/gaze_y_r/gaze_y_l channels to work on.
%   │                 This can be a 4-element vector of channel numbers, or 'gaze',
%   │                 which will use the last channel of the types
%   │                 specified above. Default is 'gaze'.
%   └.channel_action: 'replace' existing gaze_x_c and gaze_y_c channels, or
%                     'add' new ones (default)
% ● Outputs
%   *            sts: Status determining whether the execution was
%                     successfull (sts == 1) or not (sts == -1)
%   *  channel_index: Index of the generated combined gaze channels.
%                     This can be in the end if channel action is specified to be 'add',
%                     or around the old left/right channels if channel_action is specified
%                     to be 'replace'.
% ● History
%   Written in 2021 by Teddy
%   Updated in 2024 by Dominik R Bach (Uni Bonn)

%% 1 Initialise
global settings;
if isempty(settings)
  pspm_init;
end
sts = -1;
channel_index = 0;

%% 2 Create default arguments and initialise data to be added
if nargin == 1
  options = struct();
end
options = pspm_options(options, 'gaze_pp');
if options.invalid
  return
end
gaze_x_c = struct();
gaze_y_c = struct();

%% 3 Load data
% 3.1 load all data
[sts, alldata.infos, alldata.data] = pspm_load_data(fn);
if sts ~= 1; return; end
% 3.2 check single channels
stsc = 0;
if isnumeric(options.channel) && numel(options.channel) == 4
    [stsc(1), gaze_x_r] = pspm_load_channel(alldata, options.channel(1), 'gaze_x_r');
    [stsc(2), gaze_x_l] = pspm_load_channel(alldata, options.channel(2), 'gaze_x_l');
    [stsc(3), gaze_y_r] = pspm_load_channel(alldata, options.channel(3), 'gaze_y_r');
    [stsc(4), gaze_y_l] = pspm_load_channel(alldata, options.channel(4), 'gaze_y_l');
    if sum(stsc) < 4, return, end
elseif (isnumeric(options.channel) && numel(options.channel) == 1 && options.channel == 0) || ...
        (ischar(options.channel) && strcmp(options.channel, 'gaze'))
    [stsc(1), gaze_x_r, gaze_y_r] = pspm_load_gaze (fn, 'r');
    [stsc(2), gaze_x_l, gaze_y_l] = pspm_load_gaze (fn, 'l');
    if sum(stsc) < 2, return, end
else
    warning('ID:invalid_input', 'Channel definition is invalid.');
    return
end

%% 4 Process data
% 4.1 process gaze_x data
if numel(gaze_x_r.data) == numel(gaze_x_l.data)
    gaze_x_c.data = mean([gaze_x_r.data(:), gaze_x_l.data(:)], 2, 'omitnan');
    gaze_x_c.header = gaze_x_r.header;
    gaze_x_c.header.chantype = 'gaze_x_c';
else
    warning('ID:invalid_input', 'Gaze x data dimensions do not match.');
    return
end
% 4.2 process gaze_y data
if numel(gaze_y_r.data) == numel(gaze_y_l.data)
    gaze_y_c.data = mean([gaze_y_r.data(:), gaze_y_l.data(:)], 2, 'omitnan');
    gaze_y_c.header = gaze_y_r.header;
    gaze_y_c.header.chantype = 'gaze_y_c';
else
    warning('ID:invalid_input', 'Gaze y data dimensions do not match.');
    return
end

%% 5 save
out.msg.prefix = sprintf('Gaze preprocessing');
[lsts, out_id] = pspm_write_channel(fn, {gaze_x_c, gaze_y_c}, options.channel_action, out);
if lsts < 1, return, end

%% 6 Return values
channel_index = out_id.channel;
sts = 1;
