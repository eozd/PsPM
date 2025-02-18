function [sts, import, sourceinfo] = pspm_get_cnt(datafile, import)
% ● Description
%   pspm_get_cnt imports NeuroScan cnt files using FieldTrip functions.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_cnt(datafile, import);
% ● Developer's notes
%   This function uses fieldtrip fileio functions
% ● Arguments
%   *   datafile : The data file to be imported.
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
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
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
% data storage is assumed to be 16 bit by default, see also
% http://fieldtrip.fcdonders.nl/faq/i_have_problems_reading_in_neuroscan_.cnt_files._how_can_i_fix_this
if isfield(import{1}, 'bit') && import{1}.bit == 32
  headerformat = 'ns_cnt32';
else
  headerformat = 'ns_cnt16';
end

hdr = ft_read_header(datafile, 'headerformat', headerformat);
indata = ft_read_data(datafile, 'headerformat', headerformat, 'dataformat', headerformat);
try mrk = ft_read_event(datafile, 'headerformat', headerformat, 'dataformat', headerformat, 'eventformat', headerformat); catch, mrk = []; end;

% extract individual channels
% -------------------------------------------------------------------------
for k = 1:numel(import)
  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'wave')
    if import{k}.channel > 0
      channel = import{k}.channel;
    else
      channel = pspm_find_channel(hdr.label, import{k}.type);
      if channel < 1, return; end
    end

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
      import{k}.markerinfo.value = [];
      import{k}.markerinfo.name = [];
    end
  end

end

% clear path and return
% -------------------------------------------------------------------------
rmpath(pspm_path('Import','fieldtrip','fileio'));
%% return values
sts = 1;
return
