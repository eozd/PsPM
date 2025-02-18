function [sts, data, newsr] = pspm_prepdata(varargin)
% ● Description
%   pspm_prepdata is a shared PsPM function for twofold butterworth filting and
%   downsampling raw data `on the fly`. This data is usually stored in results
%   files rather than data files.
% ● Format
%   [sts, data, newsr] = pspm_prepdata(varargin)
%   [sts, data, newsr] = pspm_prepdata(data, filt)
%   [sts, data, newsr] = pspm_prepdata(data, filt, options)
% ● Arguments
%   *      data:  a column vector of data
%   ┌──────filt
%   ├───────.sr:  current sample rate in Hz
%   ├───.lpfreq:  low pass filt frequency or 'none'
%   ├──.lporder:  low pass filt order
%   ├──.hporder:  high pass filt order
%   ├───.hpfreq:  high pass filt frequency or 'none'
%   ├.direction:  filt direction
%   └─────.down:  sample rate in Hz after downsampling or 'none'
%   ┌───options
%   └──.fillnan:  0/1 specify whether to fill nan if there is. Default: 1
% ● Developer's Notes
%   Note that the order for bandpass and bandstop filters is equal to
%   order = lporder + hporder
%   the new sample rate is returned as newsr because downsampling might fail
%   for some required sampling rates; a fallback is used then used by pspm_glm,
%   pspm_sf, pspm_pulse_convert, pspm_dcm, pspm_pp.
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
data = varargin{1};
options = struct();
switch nargin
  case 2
    filt = varargin{2};
  case 3
    filt = varargin{2};
    options = varargin{3};
end
outdata = data;
newsr = 0;

%% Check input
options = pspm_options(options, 'prepdata');
if nargin < 2
  warning('ID:invalid_input', 'Nothing to do.'); return;
elseif ~isnumeric(data)
  warning('ID:invalid_input', 'Data must be numeric.'); return;
elseif (~isfield(filt, 'lpfreq') || ~isfield(filt, 'lporder') || ...
    ~isfield(filt, 'hpfreq') || ~isfield(filt, 'hporder') || ...
    ~isfield(filt, 'down')   || ~isfield(filt, 'direction') || ...
    ~isfield(filt, 'sr'))
  warning('ID:invalid_input', 'filt structure has missing fields.'); return;
elseif ((~isnumeric(filt.lpfreq) && (~ischar(filt.lpfreq) || ~strcmpi(filt.lpfreq, 'none'))) || ...
    ~isnumeric(filt.lporder) || ...
    (~isnumeric(filt.hpfreq) && (~ischar(filt.hpfreq) || ~strcmpi(filt.hpfreq, 'none'))) || ...
    ~isnumeric(filt.hporder) || ...
    (~isnumeric(filt.down)   && (~ischar(filt.down  ) || ~strcmpi(filt.down, 'none'))) || ...
    ~ischar(filt.direction)   || ~isnumeric(filt.sr) || ...
    ~any(strcmpi(filt.direction, {'uni', 'bi'})))
  warning('ID:invalid_input', 'filt structure has misspecified fields.');
  return;
end
uni = strcmpi(filt.direction, 'uni');
%% Preprocessing data for nan
if any(isnan(data))
  if options.fillnan
    data_index = 1:length(data);
    data_nan_index = data_index(isnan(data));
    data = pspm_interp1(data);
  else
    warning('ID:invalid_input', ...
    ['Data contains NaN values but filling nan is not allowed. ',...
    'Processing cannot be performed.']);
    return
  end
end
%% Prepare data
% determine nyquist frequency
nyq = filt.sr/2;
% transform data into column
data = data(:);
% if unidirectional, append data to avoid filter ringing
if uni
  data = [data(1) * ones(floor(50 * filt.sr), 1); data];
end
lowpass_filt = false;
%% Lowpass filt
if ~ischar(filt.lpfreq) && ~isnan(filt.lpfreq)
  lowpass_filt = true;
elseif isnumeric(filt.down) && ~isnan(filt.down) && filt.down < filt.sr
  % if lowpass filtering is disabled and downsampling is enabled
  % enable lpfiltering with down/2 in order to avoid creating artifacts
  lowpass_filt = true;
  filt.lpfreq = filt.down/2;
  filt.lporder = 1;
end
if lowpass_filt
  if filt.lpfreq >= nyq
    warning('ID:no_low_pass_filtering', ...
      'The low pass filter cutoff frequency is higher (or equal) than the nyquist frequency. The data won''t be low pass filtered!');
  else
    [lsts, filt.b, filt.a]=pspm_butter(filt.lporder, filt.lpfreq/nyq, 'low');
    if lsts == -1
      warning('ID:invalid_input', 'call of pspm_butter failed');
      return;
    end
    if uni
      data = filter(filt.b, filt.a, data);
      data = filter(filt.b, filt.a, data);
    else
      [~, data] = pspm_filtfilt(filt.b, filt.a, data);
    end
  end
end
%% Highpass filt
if ~ischar(filt.hpfreq) && ~isnan(filt.hpfreq)
  [lsts, filt.b, filt.a]=pspm_butter(filt.hporder, filt.hpfreq/nyq, 'high');
  if lsts == -1
    warning('ID:invalid_input', 'call of pspm_butter failed');
    return;
  end
  if uni
    data = filter(filt.b, filt.a, data);
    data = filter(filt.b, filt.a, data);
  else
    [~, data] = pspm_filtfilt(filt.b, filt.a, data);
  end
end
% if uni, remove dummy data
if uni
  data = data((floor(50 * filt.sr) + 1):end);
end
%% Downsample
if exist('data_nan_index','var')
  data(data_nan_index) = NaN; % reverse filled values back to nan if necessary
end
if ~ischar(filt.down) && filt.sr > filt.down
  if strcmpi(filt.lpfreq, 'none') || isnan(filt.lpfreq)
    warning('No low pass filter applied - aliasing is possible. Use a low pass filter to prevent.');
  elseif filt.down < 2 * filt.lpfreq
    filt.down = 2 * filt.lpfreq;
    warning('ID:freq_change', ...
      'Sampling rate was changed to %01.2f Hz to prevent aliasing', filt.down)
  end
  [lsts, data, newsr] = pspm_downsample(data, filt.sr, filt.down);
  if lsts == -1
    return
  end
else
  newsr = filt.sr;
end
%% Prepare the final data
outdata = data;
sts = 1;
return
