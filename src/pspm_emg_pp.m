function [sts, outchannel] = pspm_emg_pp(fn, options)
% ● Description
%   pspm_emg_pp pre-processes startle eyeblink EMG data in 3 steps, which
%   were optimised in reference [1].
%   (1)  Initial filtering:
%       4th order Butterworth with 50 Hz and 470 Hz cutoff frequencies.
%   (2)  Removing mains noise:
%       adjustable notch filter (default 50 Hz).
%   (3)  Smoothing and rectifying:
%       4th order Butterworth low-pass filter with a time constant of 3 ms
%       (corresponding to a cutoff of 53.05 Hz).
%   While the input data must be an EMG channel, the output channel will be
%   of type emg_pp, as required by the startle eyeblink GLM.
% ● Format
%   [sts, channel_index]  = pspm_emg_pp(fn, options)
% ● Arguments
%   *             fn: [string]
%                     Path to the PsPM file which contains the EMG data.
%   ┌─────── options:
%   ├────.mains_freq: [integer] Frequency of mains noise to remove
%   │                 with notch filter (default: 50 Hz).
%   ├───────.channel: [numeric/string] Channel to be preprocessed.
%   │                 Can be a channel ID or a channel name.
%   │                 Default is 'emg' (i.e. last EMG channel)
%   └.channel_action: ['add'/'replace'] Defines whether the new channel should
%                     be added or the previous outputs of this function should
%                     be replaced. (Default: 'replace')
% ● Outputs
%   *   channel_index: index of channel containing the processed data
% ● References
%   [1] Khemka S, Tzovara A, Gerster S, Quednow BB, Bach DR (2017).
%       Modelling startle eye blink electromyogram to assess fear learning.
%       Psychophysiology, 54, 202-214.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2009-2016 by Tobias Moser (University of Zurich)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = [];

% set default values
% -------------------------------------------------------------------------
if nargin < 2
  options = struct();
end

if ~isfield(options, 'mains_freq')
  options.mains_freq = 50;
end

options = pspm_options(options, 'emg_pp');
if options.invalid
  return
end

% check values
% -------------------------------------------------------------------------
if ~isnumeric(options.mains_freq)
  warning('ID:invalid_input', 'Option mains_freq must be numeric.');
  return;
end

% load data
% -------------------------------------------------------------------------
[lsts, data] = pspm_load_channel(fn, options.channel, 'emg');
if lsts ~= 1, return, end

% do the job
% -------------------------------------------------------------------------

% (1) 4th order Butterworth band-pass filter with cutoff frequency of 50 Hz and 470 Hz
filt.sr = data.header.sr;
filt.lpfreq = 470;
filt.lporder = 4;
filt.hpfreq = 50;
filt.hporder = 4;
filt.down = 'none';
filt.direction = 'uni';

[lsts, data.data, data.header.sr] = pspm_prepdata(data.data, filt);
if lsts < 1, return; end

% (2) remove mains noise with notch filter
% design from
% http://dsp.stackexchange.com/questions/1088/filtering-50hz-using-a-
% notch-filter-in-matlab
nfr = filt.sr/2;                         % Nyquist frequency
freqRatio = options.mains_freq/nfr;      % ratio of notch freq. to Nyquist freq.
nWidth = 0.1;                            % width of the notch filter

% Compute zeros
nZeros = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];
% Compute poles
nPoles = (1-nWidth) * nZeros;

b = poly( nZeros ); % Get moving average filter coefficients
a = poly( nPoles ); % Get autoregressive filter coefficients

% filter signal x
data.data = filter(b,a,data.data);

% (3) smoothed using 4th order Butterworth low-pass filter with
% a time constant of 3 ms corresponding to a cutoff frequency of 53.05 Hz
filt.sr = data.header.sr;
filt.lpfreq = 1/(2*pi*0.003);
filt.lporder = 4;
filt.hpfreq = 'none';
filt.hporder = 0;
filt.down = 'none';
filt.direction = 'uni';

% rectify before with abs()
[lsts, data.data, data.header.sr] = pspm_prepdata(abs(data.data), filt);
if lsts < 1, return; end

% change channel type to emg_pp to match sebr modality
old_channeltype = data.header.chantype;
data.header.chantype = 'emg_pp';

% save data
% -------------------------------------------------------------------------
channel_str = num2str(options.channel);
o.msg.prefix = sprintf(...
  'EMG preprocessing :: Input channel: %s -- Input channeltype: %s -- Output channeltype: %s --', ...
  channel_str, ...
  old_channeltype, ...
  data.header.chantype);
[lsts, outinfos] = pspm_write_channel(fn, data, options.channel_action, o);
if lsts < 1, return; end

outchannel = outinfos.channel;
sts = 1;

