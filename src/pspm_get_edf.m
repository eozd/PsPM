function [sts, import, sourceinfo] = pspm_get_edf(datafile, import)
% ● Description
%   pspm_get_edf imports European Data Format (EDF) files using FieldTrip 
%   fileio functions.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_edf(datafile, import);
% ● Arguments
%   * datafile: the EDF data file to be imported
%   *   import: the struct of import settings
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Tobias Moser (University of Zurich)
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
w_state = warning('query');
warning('off', 'all'); % unfortunately the warning is not issued with an ID
hdr = ft_read_header(datafile);
indata = ft_read_data(datafile);
try mrk = ft_read_event(datafile, 'detectflank', []); catch, mrk = []; end
warning(w_state);


% convert 3 dim to 2 dim (collapse all trials into continuous data)
if numel(size(indata)) == 3,
  indata = indata(:,:);
end

% extract individual channels
% -------------------------------------------------------------------------
% loop through import jobs
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
      warning('ID:channel_not_contained_in_file', ...
        'Marker channel not contained in file %s.\n', datafile); return;
    end
  end

end

% clear path and return
% -------------------------------------------------------------------------
rmpath(pspm_path('Import','fieldtrip','fileio'));
sts = 1;
return
