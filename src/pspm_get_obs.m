function [sts, import, sourceinfo] = pspm_get_obs(datafile, import)
% ● Description
%   pspm_get_obs imports text-exported Noldus Observer XT compatible files. 
%   The function is only assured to work with the output files of the 
%   system Vsrrp98.
%   This function is based on sample files, not on proper documentation of the
%   file format. Always check your imported data before using it. 
% ● Format
%   [sts, import, sourceinfo] = pspm_get_obs(datafile, import);
% ● Arguments
%   *   datafile : datafile to be imported.
%   *     import : import settings.
% ● Outputs
%   *        sts : status.
%   *     import : the updated import structure.
%   * sourceinfo : the source information structure.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2013-2015 by Linus Rüttimann (University of Zurich)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];

% get external file
% -------------------------------------------------------------------------
% read sample rate ---
fid = fopen(datafile);
obs.sr = textscan(fid, '%s%s%f', 1);
if ~strcmp(obs.sr{1}{1}, 'Sample') || ~strcmp(obs.sr{2}{1}, 'Rate:') || numel(obs.sr{3}) == 0 || isnan(obs.sr{3})
  warning('Wrong data format'); return
end
obs.sr = obs.sr{3};
fclose(fid);

% read channel names ---
fid = fopen(datafile);
fgetl(fid); %ignore first line
channel_names = textscan(fgetl(fid), '%s', 'Delimiter', '\t'); %read second line
fclose(fid);

if numel(channel_names{1}) == 0 || strcmp(channel_names{1}{1}, 'Time (s)') == 0
  warning('Wrong data format'); return
elseif numel(channel_names{1}) == 1
  warning('No channels were found in the datafile.'); return
end
obs.channel_names = channel_names{1};

% read data ---
formatSpec = '';
for i=1:numel(obs.channel_names)
  formatSpec = [formatSpec '%f'];
end
fid = fopen(datafile);
obs.data = textscan(fid, formatSpec, 'HeaderLines', 2);
fclose(fid);

% check sample rate
fid = fopen(datafile);
str = textscan(fid, '%s', 1, 'HeaderLines', 2);
fclose(fid);
str = str{1}{1};
pos = strfind(str, '.'); %position of the the decimal point

if isempty(pos)
  threshold = obs.sr;
elseif numel(pos) > 1
  warning('Wrong data format.'); return
else
  threshold = obs.sr * 10^-(length(str) - pos); %length(str) - pos = no. of decimal places
end

% diff(timestamps) < sr^-1 + abs(error)
% --> abs(1-diff(timestamps)) < threshold, with threshold = sr * abs(error)
if any(abs(1-obs.sr*diff(obs.data{1}))>threshold)
  warning('Samplerate and time stamps do not match.'); return;
end

% extract individual jobs
% -------------------------------------------------------------------------
for k = 1:numel(import)
  if import{k}.channel > 0
    channel = import{k}.channel;
  elseif strcmpi(import{k}.type, 'marker')
    channel = pspm_find_channel(obs.channel_names, {'sync'});
    if channel < 1, warning('Marker channel for import job %02.0f could not be identified (it''s name needs to be SYNC). Please specify as field .channel', k);  return; end
  else
    channel = pspm_find_channel(obs.channel_names, import{k}.type);
    if channel < 1, return; end
  end

  if channel > numel(obs.data), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end

  sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, obs.channel_names{channel});

  import{k}.sr = obs.sr;
  if strcmpi(import{k}.type, 'marker')
    import{k}.marker = 'continuous';
  end
  import{k}.data = obs.data{channel};

end

sts = 1;
return

