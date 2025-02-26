function [sts, wavedata] = pspm_pulse_convert(pulsedata, resamplingrate, samplingrate)
% ● Description
%   pspm_pulse_convert converts pulsed data into a data waveform, assuming
%   milliseconds as time unit and a resamplingrate in Hz given as input argument
% ● Developer
%   This function is designed for data from CED spike, recorded by CED Micro
%   1401. These data should not normally exceed pulse frequencies of 10 kHz,
%   corresponding to a pulse time stamp difference of 0.1 ms. Smaller values
%   are frequently observed, in time series with otherwise much higher
%   values. This is unlikely to reflect a pulse frequency above the sampling
%   resolution of the 1401 and more likely to be a technical glitch. These
%   time stamps are filtered out before re-sampling.
% ● Format
%   [sts, wavedata] = pspm_pulse_convert(pulsedata, resamplingrate, samplingrate)
% ● Arguments
%   *      pulsedata : timestamps in ms
%   * resamplingrate : for interpolation
%   *   samplingrate : to be downsampled to
% ● Outputs
%   *            sts : status of function processing
%   *       wavedata : the waveform data that is converted from pulsed data
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
wavedata = [];

% check input arguments
if nargin<1
  errmsg='No data for pulse conversion.';
  warning('ID:invalid_input', errmsg);
  wavedata=[];
elseif nargin<2
  errmsg='No resamplingrate for pulse conversion.';
  warning('ID:invalid_input', errmsg);
  wavedata=[];
elseif nargin < 3
  warning('ID:invalid_input', 'No sampling rate given.');
  return;
  % convert data
else
  pulsedata = pulsedata(:);
  % filter pulsedata (diagnostic plot see below)
  % figure;hist(diff(pulsedata), 20)
  pulsedata(find(diff(pulsedata) < .1) + 1) = [];
  % convert resamplingrate to match time units (ms)
  resamplingrate=resamplingrate/1000;
  maxtruesamplingrate = 1/min(diff(pulsedata));
  if 10*maxtruesamplingrate > resamplingrate
    newresamplingrate = min([round(maxtruesamplingrate*10), 10000/1000]); % max resamplingrate: 10 kHz, otherwise out of memory
    resamplingrate = newresamplingrate;
  end
  fprintf('\nPulse data was converted to waveform with a sampling rate of %01.2f Hz, to allow 10-fold oversampling.\n', resamplingrate*1000);
  scrt = pulsedata;
  scr = 1./diff(scrt);                                            % get frequency information for each timepoint
  newscrt = (1/resamplingrate):(1/resamplingrate):(max(scrt));    % create new timepoint vector
  % note: for speed and memory, use linear interpolation, at high rsr there
  % shouldn't be any advantage of more accurate interpolation
  newscr = interp1(scrt(2:end), scr, newscrt, 'linear', 'extrap');   % interpolate with resampling rate
  wavedata = newscr'*1000;          % transpose into one column and convert into correct time unit
  % put back into correct timeunits (seconds)
  resamplingrate = 1000 * resamplingrate;
  % substitute missing samplingrate
  if nargin < 3, samplingrate = resamplingrate; end
  % convert
  if samplingrate < resamplingrate
    filt.lpfreq = 0.5 * samplingrate;
    filt.lporder = 1;
    filt.hpfreq = 'none';
    filt.hporder = 1;
    filt.direction = 'bi';
    filt.down = samplingrate;
    filt.sr = resamplingrate;
    [sts_prepdata, wavedata, ~] = pspm_prepdata(wavedata, filt);
    if sts_prepdata ~= 1
      warning('ID:invalid_input', 'call of pspm_prepdata failed');
      return
    end
  end
end
sts = 1;
return
