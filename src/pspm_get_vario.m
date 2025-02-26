function [sts, import, sourceinfo] = pspm_get_vario(datafile, import)
% ● Description
%   pspm_get_vario imports VarioPort files using the conversion routine 
%   getVarioPort.m written and maintained by Christoph Berger at the 
%   University of Rostock.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_vario(datafile, import);
% ● Arguments
%   *   datafile : the data file to be imported.
%   *     import : the import struct of importing settings.
% ● Outputs
%   *     import : the import struct with added information.
%   * sourceinfo : the struct that includes source information.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
addpath(pspm_path('Import','vario'));

%% get data
[vario, event] = getVarioport_allChannels(datafile);

% extract individual channels
% -------------------------------------------------------------------------
% loop through import jobs ---
for k = 1:numel(import)
  if ~strcmpi(import{k}.type, 'marker')
    % define channel number ---
    if import{k}.channel > 0
      channel = import{k}.channel;
    else
      channel = pspm_find_channel({vario.channel.name}, import{k}.type);
      if channel < 1, return; end
    end

    if channel > size({vario.channel.name}, 2), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end

    sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, vario.channel(channel).name);

    % sample rate
    import{k}.sr = vario.channel(channel).scaled_scan_fac;

    % units
    import{k}.units = vario.channel(channel).unit;

    % get data
    import{k}.data =  vario.channel(channel).data(:);

  else
    import{k}.sr = 1; % converted to seconds in getVarioport_allChannels.m
    import{k}.data = [event.time];
    import{k}.marker = 'timestamp';
    import{k}.markerinfo.name = {event.name};
    import{k}.markerinfo.value = str2double(import{k}.markerinfo.name);
  end
end

%% clear path and return
rmpath(pspm_path('Import','vario'));
sts = 1;
return
