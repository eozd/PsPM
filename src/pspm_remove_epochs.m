function [sts, outchannel] = pspm_remove_epochs(datafile, channel, epochfile, options)
% ● Description
%   pspm_remove_epochs sets epochs of data, as defined by an epoch file, 
%   to NaN. 
% ● Format
%   [sts, channel_index] = pspm_remove_epochs(datafile, channel, epochfile, options)
% ● Arguments
%   *  datafile:  a filename or a cell of filenames
%   *   channel:  defines which channels should be affected by epoch removal. This can be
%                 a numerical vector or channel identifier accepted by pspm_load_data.
%   * epochfile:  a filename which defines the epoch to be set to NaN. The epochs must
%                 be in seconds. This parameter is passed to pspm_get_timing().
%   * timeunits:  timeunits of the epochfile.
%   ┌───options
%   ├─.channel_action: ['add'/'replace'] Defines whether new channels should be added or
%   │                  corresponding channels should be replaced. The default value is 'add'.
%   └─.expand_epochs:  [pre, post]
%                              
% ● Output
%   * channel_index: index of channel containing the processed data
% ● History
%   Introduced in PsPM 4.0
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Maintained in 2024 by Bernhard Agoué von Raußendorf

global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = [];

% input checks for options only as these are not directly passed to
% other functions.
if nargin < 3
  warning('ID:invalid_input', 'Not enough input arguments');
  return;
elseif nargin < 4
  options = struct();
end
options = pspm_options(options, 'remove_epochs');
if options.invalid
  return
end
[lsts, ~, data, filestruct] = pspm_load_data(datafile, channel);
pos_of_channels = filestruct.posofchannels;
if lsts < 1
  return;
end

[lsts, ep] = pspm_get_timing('epochs', epochfile, 'seconds');
if lsts < 1
  return;
end


% expands the epoch if  options.expand_epochs exists
if isfield(options,'expand_epochs')
    if numel(options.expand_epochs) ~= 2 || ~isnumeric(options.expand_epochs)
        warning('Expansion must be a 2-element vector [pre, post].');
    else
        [psts, ep] = pspm_expand_epochs(ep, options.expand_epochs);
        if psts < 1
            return;
        end
    end
end





n_ep = size(ep, 1);
n_data = numel(data);
for i_data = 1:n_data
  channel = data{i_data};
  sr = channel.header.sr;
  channeltype = channel.header.chantype;
  for i_ep = 1:n_ep
    epoch = ep(i_ep, :);
    if strcmpi(settings.channeltypes(strcmpi({settings.channeltypes.type}, ...
        channeltype)).data, 'events')
      % remove markers within the period
      channel.data(channel.data >= epoch(1) & channel.data <= epoch(2)) = [];
    else
      % find start and stop sample and ensure they're not
      % going over the edges
      smp_start = max(1, round(sr*epoch(1)));
      smp_stop = min(numel(channel.data), round(sr*epoch(2)));
      % set period to NaN
      channel.data(smp_start:smp_stop) = NaN;
    end
    % write back to data struct
    data{i_data}.data = channel.data;
  end
end
% save data to file

[sts, out] = pspm_write_channel(datafile, data, options.channel_action, ...
    struct('channel', pos_of_channels));
outchanel = out.channel;