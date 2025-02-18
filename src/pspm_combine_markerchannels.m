function [sts, outchannel] = pspm_combine_markerchannels(datafile, options)
% ● Description
%   This function combines several marker channels into one.
%   Index of original marker channel is converted into marker name and marker
%   value of the new channel.
%   This allows for example creating GLM timing definitions based on
%   markers distributed across multiple channels.
% ● Format
%   [sts, outchannel] = pspm_combine_markerchannels(datafile, options)
% ● Arguments
%   *        datafile : data file name: char
%   ┌─────────options
%   ├─.channel_action : Accepted values: 'add'/'replace'
%   │                   Defines whether the new channel should be added
%   │                   on top of combined marker channels ('add'), or all
%   │                   combined marker channels should be deleted and
%   │                   replaced with the one new channel ('replace'). If
%   │                   the first option is used, then use marker channel
%   │                   indexing in further processing which by default
%   │                   takes the first marker channel as input
%   └.marker_chan_num:  Choose any number of marker channel numbers to 
%                       combine. If 0 all marker channels are 
%                       used [default: use all channels].
% ● History
%   Introduced In PsPM 6.1.2
%   Written in 2023 by Dominik R Bach (Uni Bonn)

%% Initialise
global settings
if isempty(settings)
    pspm_init;
end
sts = -1;
outchannel = [];

% check faulty input --
if nargin < 1; errmsg = 'Nothing to do.'; warning('ID:invalid_input', errmsg); return
elseif nargin < 2; options = struct(); end

options = pspm_options(options, 'combine_markerchannels');
if options.invalid
    return
end

% combine all markers
[sts, infos, data, filestruct] = pspm_load_data(datafile, options.marker_chan_num);
if sts < 1, return; end
for iChannel = 1:numel(data)
    if ~strcmpi(data{iChannel}.header.chantype, 'marker')
        warning('ID:invalid_input', sprintf('Channel %1.0f is not of type marker', ...
            filestruct.posofchannels(iChannel))); return;
    end
end
newdata{1}.data = sort(reshape(cell2mat(cellfun(@(x) x.data(:), data, ...
    'UniformOutput', false)), [], 1));
newdata{1}.header = data{1}.header;
newdata{1}.markerinfo.value = reshape(cumsum(cell2mat(cellfun(@(x) ones(length(x.data), 1), ...
    data, 'UniformOutput', false)), 2), [], 1);
newdata{1}.markerinfo.name = cellstr(num2str(newdata{1}.markerinfo.value));
% decide which channels to drop
if strcmpi(options.channel_action, 'replace')
    dropchannels = filestruct.posofchannels;
else
    dropchannels = [];
end
% load entire file, add new channel, drop channels and save
[sts, infos, data] = pspm_load_data(datafile);
data(dropchannels) = [];
data(end + 1) = newdata;
sts = pspm_load_data(datafile, struct('data', {data}, ...
    'infos', infos, 'options', struct('overwrite', 1)));
outchannel = numel(data);
if sts < 1, return; end



