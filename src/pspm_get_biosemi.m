function [sts, import, sourceinfo] = pspm_get_biosemi(datafile, import)
% ● Description
%   pspm_get_biosemi imports BioSemi bdf files using fieldtrip fileio 
%   functions
% ● Format
%   [sts, import, sourceinfo] = pspm_get_biosemi(datafile, import);
% ● Arguments
%   *   datafile : The BioSemi bdf data file to be imported.
%   ┌─────import
%   ├────.typeno : The number of channel type.
%   ├───.channel : The channel to be imported, check pspm_import.
%   ├──────.type : The type of channel, check pspm_import.
%   ├────────.sr : The sampling rate of the file.
%   ├──────.data : The data read from the file.
%   ├────.marker : The type of marker, such as 'continuous'.
%   └.markerinfo : The information of the marker, has two fields, value and name.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
addpath(pspm_path('Import','fieldtrip','fileio'));
sourceinfo = [];

% get external file, using fieldtrip
% -------------------------------------------------------------------------
hdr = ft_read_header(datafile);
indata = ft_read_data(datafile);
try mrk = ft_read_event(datafile); catch, mrk = []; end

% extract individual channels
% -------------------------------------------------------------------------
for k = 1:numel(import)

  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'wave')
    % channel number ---
    if import{k}.channel > 0
      channel = import{k}.channel;
    else
      channel = pspm_find_channel(hdr.label, import{k}.type);
      if channel < 1, return; end
    end

    if channel > size(indata, 1), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end

    sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, hdr.label{channel});

    % sample rate ---
    import{k}.sr = hdr.Fs;

    % get data ---
    import{k}.data = indata(channel, :);

  else                % event channels
    % time unit
    import{k}.sr = 1./hdr.Fs;

    if ~isempty(mrk)
      import{k}.data = [mrk(:).sample];
      import{k}.marker = 'timestamps';
      import{k}.markerinfo.value = pspm_struct2vec(mrk, 'value', 'marker');
      import{k}.markerinfo.name = {mrk(:).type};
    else
      import{k}.data = [];
      import{k}.marker = 'timestamps';
      import{k}.markerinfo.value = [];
      import{k}.markerinfo.name = [];
    end
  end

end

% clear path and return
% -------------------------------------------------------------------------
rmpath(pspm_path('Import','fieldtrip','fileio'));
sts = 1;
return
