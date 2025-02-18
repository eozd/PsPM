function [sts, import, sourceinfo] = pspm_get_acq_bioread(datafile, import)
% ● Description
%   pspm_get_acq_bioread imports bioread-converted Biopac Acknowledge files 
%   from any Acknowledge version. This function is tested for conversion
%   with the tool acq2mat from the bioread package (https://github.com/njvack/bioread.)
%   You can also use pspm_get_acq_python if you have installed this package
%   on the same computer on which you run PsPM.
%   This function is based on sample files, not on proper documentation of the
%   file format. Always check your imported data before using it. 
% ● Format
%   [sts, import, sourceinfo] = pspm_get_acq_bioread(datafile, import);
% ● Arguments
%   * datafile : the path of the BIOPAC/AcqKnowledge file to be imported
%   ┌───import
%   ├─.channel : channel.
%   ├──────.sr : sampling rate.
%   ├────.type : channel type.
%   ├────.data : The data read from the acq file.
%   ├───.units : the unit of data.
%   └──.marker : The type of marker, such as 'continuous'.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
%% load data
inputdata = load(datafile);
%% extract individual channels
for k = 1:numel(import)
  channel_labels = transpose(cellfun(@(x) x.name, inputdata.channels, 'UniformOutput', 0));
  % define channel number ---
  if import{k}.channel > 0
    channel = import{k}.channel;
  else
    channel = pspm_find_channel(channel_labels, import{k}.type);
    if channel < 1, return; end
  end
  if channel > size(channel_labels, 1)
    warning('ID:channel_not_contained_in_file', ...
    'Channel %02.0f not contained in file %s.\n', channel, datafile);
    return
  end
  sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, channel_labels{channel});
  % define sample rate ---

  import{k}.sr = inputdata.channels{channel}.samples_per_second;
  % get data & data units
  import{k}.data = double(inputdata.channels{channel}.data);
  import{k}.units = inputdata.channels{channel}.units;
  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'events')
    import{k}.marker = 'continuous';
  end
end
%% Return values
sts = 1;
return
