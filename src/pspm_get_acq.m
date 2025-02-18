function [sts, import, sourceinfo] = pspm_get_acq(datafile, import)
% ● Description
%   pspm_get_acq imports Biopac Acknowledge files from version 3.9.0 or
%   lower. This function uses the conversion routine acqread.m version 2.0 (2007-08-21)
%   by Sebastien Authier and Vincent Finnerty at the University of Montreal
%   which supports all files created with Windows/PC versions of
%   AcqKnowledge (3.9.0 or below), BSL (3.7.0 or below), and BSL PRO
%   (3.7.0 or below).
% ● Format
%   [sts, import, sourceinfo] = pspm_get_acq_python(datafile, import);
% ● Arguments
%   *   datafile : The .acq data file to be imported
%   ┌─────import
%   ├───.channel : The channel to be imported, check pspm_import
%   ├──────.type : The type of channel, check pspm_import
%   ├────────.sr : The sampling rate of the acq file.
%   ├──────.data : The data read from the acq file.
%   └────.marker : The type of marker, such as 'continuous'
% ● Output
%   *     import : The import struct that saves importing information
%   * sourceinfo : The struct that saves information of original data source
% ● Developer
%   The main part of this function is shared with pspm_get_acq_python.
%   The function acqread is stored in the path /Import/acq.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2011-2014 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Updated in 2024 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
addpath(pspm_path('Import','acq'));
%% Load data
[sts, header, inputdata] = evalc('acqread(datafile)');
%% Extract individual channels
for k = 1:numel(import)
  % define channel number ---
  if import{k}.channel > 0
    channel = import{k}.channel;
  else
    channel = pspm_find_channel(header.szCommentText, import{k}.type);
    if channel < 1, return; end
  end
  if channel > numel(header.szCommentText)
    warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return
  end
  sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, header.szCommentText{channel});
  % retrieve sample rate ---
  % we might need to change this if different sample rates are used for
  % each channel
  if numel(header.dSampleTime) > 1
    warning('Unknown sample rate format Please contact the developers.'); return;
  elseif isfield(header, 'nVarSampleDivider') && ~isempty(header.nVarSampleDivider) && numel(header.nVarSampleDivider) >= channel
    % allows for channel-specific sample rates from version 3.7 upwards
    import{k}.sr = double(1000 * (1./header.dSampleTime) ./ header.nVarSampleDivider(channel)); % acqread returns the sample rate in milliseconds
  else
    import{k}.sr = double(1000 * 1./header.dSampleTime); % acqread returns the sampling time in milliseconds
  end
  % acqread function returns the signal without any processing. scale and offset parameters
  % provided an .acq files are meant to apply a linear transformation to each x_i.
  % See https://www.mathworks.com/matlabcentral/fileexchange/16023-acqread
  temp = header.dAmplScale(channel) * double(inputdata{channel}) + header.dAmplOffset(channel);
  [r,c]= size(temp);
  if r == 1 && c > 1
    temp = transpose(temp);
  end
  import{k}.data = temp;
  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'events')
    import{k}.marker = 'continuous';
  end
end
%% Clear path and return
rmpath(pspm_path('Import','acq'));
sts = 1;
return
