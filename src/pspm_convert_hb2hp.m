function [sts, outchannel] = pspm_convert_hb2hp(fn, sr, options)
% ● Description
%   pspm_convert_hb2hp transforms heart beat data into an interpolated heart
%   rate signal and adds this as an additional channel to the data file
% ● Format
%   [sts, channel_index] = pspm_convert_hb2hp(fn, sr, options)
% ● Arguments
%   *             fn: data file name
%   *             sr: new sample rate for heart period channel
%   ┌─────── options
%   ├───────.channel: [optional, numeric/string, default: 'hb', i.e. last
%   │                 heart beat channel in the file]
%   │                 Channel type or channel ID to be preprocessed.
%   │                 Channel can be specified by its index (numeric) in the
%   │                 file, or by channel type (string).
%   │                 If there are multiple channels with this type, only
%   │                 the last one will be processed. If you want to
%   │                 convert several heart beat channels in a PsPM file,
%   │                 call this function multiple times with the index of
%   │                 each channel.  In this case, set the option
%   │                 'channel_action' to 'add',  to store each
%   │                 resulting 'hp' channel separately.
%   ├.channel_action: ['add'/'replace', default as 'replace']
%   │                 Defines whether heart rate signal
%   │                 should be added or the corresponding preprocessed
%   │                 channel should be replaced.
%   ├─────────.limit: [struct]
%   │                 Specifies upper and lower limit for heart
%   │                 periods. If the limit is exceeded, the values will
%   │                 be ignored/removed and interpolated.
%   ├─────────.upper: [numeric]
%   │                 Specifies the upper limit of the
%   │                 heart periods in seconds. Default is 2.
%   └─────────.lower: [numeric]
%                     Specifies the lower limit of the
%                     heart periods in seconds. Default is 0.2.
% ● Outputs
%   *  channel_index: index of channel containing the processed data
% ● References
%   [1] Paulus PC, Castegnetti G, & Bach DR (2016). Modeling event-related
%       heart period responses. Psychophysiology, 53, 837-846.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% initialise & user output
sts = -1;
global settings;
if isempty(settings)
    pspm_init;
end
outchannel = [];

% check input
% -------------------------------------------------------------------------
if nargin < 1
  warning('ID:invalid_input','No input. Don''t know what to do.'); return;
elseif nargin < 2
  warning('ID:invalid_input','No sample rate given.'); return;
elseif ~isnumeric(sr)
  warning('ID:invalid_input','Sample rate needs to be numeric.'); return;
elseif nargin < 3
    options = struct();
end
options = pspm_options(options, 'convert_hb2hp');
if options.invalid
  return
end

% get data
% -------------------------------------------------------------------------
[nsts, data, dinfos] = pspm_load_channel(fn, options.channel, 'hb');
if nsts == -1, return; end


% interpolate
% -------------------------------------------------------------------------
hb  = data.data;
ibi = diff(hb);
idx = find(ibi > options.limit.lower & ibi < options.limit.upper);
hp = 1000 * ibi; % in ms
newt = (1/sr):(1/sr):dinfos.duration;
try
  newhp = interp1(hb(idx+1), hp(idx), newt, 'linear', NaN); % assign hr to following heart beat
  nanindx = isnan(newhp);
  if any(nanindx)
    newhp(nanindx) = interp1(find(~nanindx),newhp(~nanindx),find(nanindx), 'nearest', 'extrap'); % avoid out-of-range values at the edges by nearest neighbour extrapolation
  end
catch
  warning('ID:too_strict_limits', ['Interpolation failed because there weren''t enough heartbeats within the ',...
    'required period limits. Filling the heart period channel with NaNs.']);
  newhp = NaN(1, size(newt, 2));
end


% save data
% -------------------------------------------------------------------------
newdata.data = newhp(:);
newdata.header.sr = sr;
newdata.header.units = 'ms';
newdata.header.chantype = 'hp';

o.msg.prefix = 'Heart beat converted to heart period and';
try
  [nsts,winfos] = pspm_write_channel(fn, newdata, options.channel_action, o);
  if nsts == -1, return;
  end
catch
  warning('ID:invalid_input', 'call of pspm_write_channel failed');
  return;
end
outchannel = winfos.channel;
sts = 1;
return
