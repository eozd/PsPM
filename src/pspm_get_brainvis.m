function [sts, import, sourceinfo] = pspm_get_brainvis(datafile, import)
% ● Description
%   pspm_get_brainvis imports BrainVision files using FieldTrip fileio
%   functions.
%   This function has not been tested on sample files. Always check your 
%   imported data before using it. 
% ● Format
%   [sts, import, sourceinfo] = pspm_get_brainvis(datafile, import);
% ● Arguments
%   *                datafile : the path of data file to be imported
%   *                  import : the struct of import settings
% ● Developer
%   I did not have sample files, simply assumed that hdr.labels would be
%   a cell array - might have to be changed in lines 38 and 41
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
sourceinfo = [];
addpath(pspm_path('Import','fieldtrip','fileio'));

% get data
% -------------------------------------------------------------------------
hdr = ft_read_header(datafile);
indata = ft_read_data(datafile);
try mrk = ft_read_event(datafile); catch, mrk = []; end

% extract individual channels
% -------------------------------------------------------------------------
% loop through import jobs
for k = 1:numel(import)

  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'wave')
    % define channel number ---
    if import{k}.channel > 0
      channel = import{k}.channel;
    else
      channel = pspm_find_channel(hdr.label, import{k}.type);
      if channel < 1, return; end
    end

    if channel > numel(hdr.label), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end

    sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, hdr.label{channel});

    % sample rate ---
    import{k}.sr = hdr.Fs;

    % get data
    import{k}.data = indata(channel, :);

  else                % marker channels: get the ascending flank of each marker
    sourceinfo.channel{k, 1} = 'Automatically extracted marker recordings';
    % time unit
    import{k}.sr = 1./hdr.Fs;
    import{k}.marker = 'timestamps';
    import{k}.data = [mrk.sample];
    m_val = {mrk.value};
    val_length = length(m_val);
    val = cell(val_length, 1);
    % convert empty cells into empty strings
    for i=1:val_length
      v = m_val{i};
      if ~ischar(v) && isempty(v)
        val{i} = '';
      else
        val{i} = v;
      end
    end
    % convert into double
    num_val = str2double(regexprep(val, '[^0-9]*([0-9,.]*)', '$1'));
    import{k}.markerinfo.value = num_val;
    import{k}.markerinfo.name  = {mrk.type}';
  end

end

% clear path
rmpath(pspm_path('Import','fieldtrip','fileio'));
%% return values
sts = 1;
end
