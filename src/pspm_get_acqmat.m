function [sts, import, sourceinfo] = pspm_get_acqmat(datafile, import)
% ● Description
%   pspm_get_acqmat imports exported Biopac Acknowledge files from version 
%   4.0 or higher. Export into matlab format from within the Acknowledge
%   software. This function has been tested for Acknowledge version 4.2.0
%   only. 
%   This function is based on sample files, not on proper documentation of the
%   file format. Always check your imported data before using it.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_acqmat(datafile, import);
% ● Arguments
%   *   datafile : The data file to be imported
%   ┌─────import
%   ├───.channel : The channel to be imported, check pspm_import
%   ├──────.type : The type of channel, check pspm_import
%   ├────────.sr : The sampling rate of the file.
%   ├──────.data : The data read from the file.
%   └────.marker : The type of marker, such as 'continuous'
% ● Outputs
%   *     import : The import struct that saves importing information
%   * sourceinfo : The struct that saves information of original data source
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];

% load data
% -------------------------------------------------------------------------
inputdata = load(datafile);


% extract individual channels
% -------------------------------------------------------------------------
for k = 1:numel(import)
  % define channel number ---
  if import{k}.channel > 0
    channel = import{k}.channel;
  else
    channel = pspm_find_channel(cellstr(inputdata.labels), import{k}.type);
    if channel < 1, return; end
  end

  if channel > size(inputdata.labels, 1), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end;

  sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, inputdata.labels(channel, :));

  % define sample rate ---
  % catch cases that are not documented and on which we have no example
  % data
  if numel(inputdata.isi) == 1 && strcmpi(inputdata.isi_units, 'ms')
    import{k}.sr = 1000/inputdata.isi;
  else
    warning('\nUnsupported modality - please notify the developers.\n'); return;
  end

  if inputdata.start_sample ~= 0
    warning('\nUnsupported sampling scheme - please notify the developers.\n'); return;
  end

  % get data & data units
  import{k}.data = double(inputdata.data(:, channel));
  import{k}.units = inputdata.units(channel,:);

  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'events')
    import{k}.marker = 'continuous';
  end
end
%% Return values
sts = 1;
return
