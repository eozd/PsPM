function [sts, data, duration] = pspm_align_channels(data, induration)
% ● Description
%   pspm_align_channels is an import functions that checks recording length
%   for all channels of a data file and aligns them.
%   If a duration argument is stated, all channels will be aligned to this
%   duration.
% ● Format
%   [sts, data, duration] = pspm_align_channels(data, induration)
% ● Arguments
%   *                data : [struct] the input data to be processed, in PsPM data format.
%   *          induration : [double] the duration of the input data.
% ● History
%   Introduced in PsPM 3.1
%   Written    in 2008-2016 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022      by Teddy

%% Initialise
global settings;
if isempty(settings)
  pspm_init;
end
sts = -1;
%% Check input arguments
if nargin == 2;
  if ~(isnumeric(induration) && numel(induration) == 1)
    warning('ID:invalid_input', 'induration must be a numeric scalar'); return;
  end
else
  induration = 0;
end
for k = 1:numel(data)
  if strcmp(data{k}.header.units, 'events')
    if isempty(data{k}.data)
      duration(k) = 0;
    else
      duration(k) = max(data{k}.data);
    end
  else
    duration(k) = numel(data{k}.data)/double(data{k}.header.sr);
  end
end
duration = max([duration, induration]);
for k = 1:numel(data)
  if ~strcmp(data{k}.header.units, 'events')
    followingtime = duration - numel(data{k}.data)/data{k}.header.sr;
    if followingtime > 0
      data{k}.data = [data{k}.data; zeros(round(followingtime*data{k}.header.sr), 1)];
      if followingtime > .1
        fprintf('\nData recordings in %s channel were non-existent %0.2f s before the last recording in one or more other channel(s).\nThis gap was padded with zeros.', data{k}.header.chantype, followingtime);
      end
    end
  end
end
sts = 1;
return
