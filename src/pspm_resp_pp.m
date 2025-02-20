function [sts, outchannel] = pspm_resp_pp(fn, sr, options)
% ● Description
%   pspm_resp_pp preprocesses raw respiration traces. The function detects respiration
%   cycles for bellows and cushion systems and creates respiration time 
%   stamps (rs), computes respiration period (rp), amplitude (ra) and
%   respiratory flow rate (rfr), assigns these measures to the start of 
%   each cycle and linearly interpolates these. The output data type can be
%   restricted in options; otherwise all four outputs are created.
% ● Format
%   [sts, channel_index] = pspm_resp_pp(fn, sr, options)
% ● Arguments
%   *             fn: data file name
%   *             sr: sample rate for new interpolated channel. This will
%   be ignored if the chosen output is only respiration time stamps.
%   ┌─────── options
%   ├───────.channel: [optional, numeric/string, default: 'resp', i.e. last
%   │                 respiration channel in the file]
%   │                 Channel type or channel ID to be preprocessed.
%   │                 Channel can be specified by its index (numeric) in the
%   │                 file, or by channel type (string).
%   │                 If there are multiple channels with this type, only
%   │                 the last one will be processed. If you want to
%   │                 preprocess several respiration in a PsPM file,
%   │                 call this function multiple times with the index of
%   │                 each channel.  In this case, set the option
%   │                 'channel_action' to 'add',  to store each
%   │                 resulting channel separately.
%   ├────.systemtype: ['bellows'(default) /'cushion'] Bellows system
%   │                 (increased air flow upon inspiration) or cushion 
%   │                 system (increased air pressure upon inspiration).
%   ├──────.datatype: a cell array with any of 'rp', 'ra', 'rfr',
%   │                   'rs', 'all' (default).
%   ├──────────.plot: [0/1] Create a respiratory cycle detection plot
%   └.channel_action: ['add'(default) /'replace']
%                     Defines whether the new channels should be added or the
%                     corresponding channel should be replaced.
% ● Outputs
%   *  channel_index: index of channel containing the processed data
%
% ● References
%   [1] Bach DR, Gerster S, Tzovara A, Castegnetti G (2016). A linear model
%       for event-related respiration responses. Journal of Neuroscience
%       Methods, 270, 174-155.
%
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
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

options = pspm_options(options, 'resp_pp');
if options.invalid
  return
end

datatype = ismember({'rp', 'ra', 'rfr', 'rs', 'all'}, options.datatype);
if datatype(end), datatype(1:end) = 1; end

%% get data
[nsts, data, infos] = pspm_load_channel(fn, options.channel, 'resp');
if nsts < 1, return; end
old_channeltype = data.header.chantype;

resp = data.data;
%% filter mean-centred data
% Butterworth filter
filt.sr        = data.header.sr;
filt.lpfreq    = 0.6;
filt.lporder   = 1;
filt.hpfreq    = .01;
filt.hporder   = 1;
filt.direction = 'bi';
filt.down      = 10;
[sts, newresp, newsr] = pspm_prepdata(resp - mean(resp,"omitnan"), filt);
% Median filter
newresp = medfilt1(newresp, ceil(newsr) + 1);
%% detect breathing cycles
if strcmpi(options.systemtype, 'bellows')
  % find pos/neg zero crossings
  respstamp = find(diff(sign(newresp)) == -2)/newsr;
elseif strcmpi(options.systemtype, 'cushion')
  % find neg/pos zero crossings of first derivative
  diffresp = diff(newresp);
  foo = diff(sign(diffresp));
  % find direct zero crossings
  zero1 = find(foo == 2);
  % find zero crossings that stay at zero for a while
  indx = find(foo ~= 0);
  neighbour_sums = conv(foo(indx), [1 1], 'valid');
  pairs = find(neighbour_sums == 2);
  zero2 = ceil(mean([indx(pairs + 1), indx(pairs)], 2));
  % combine while accouting for differentiating twice
  respstamp = sort([zero1;zero2] + 1)/newsr;
end
%% exclude < 1 s IBIs
ibi = diff(respstamp);
indx = find(ibi < 1);
respstamp(indx + 1) = [];
if strcmp(options.channel_action, 'replace') && numel(find(datatype == 1)) > 1
  % replace makes no sense
  warning('ID:invalid_input', ...
    ['More than one datatype defined. Replacing data makes no sense. '...
    'Resetting ''options.channel_action'' to ''add''.']);
  options.channel_action = 'add';
end
%% compute data values, interpolate and write
for iType = 1:(numel(datatype) - 1)
  respdata = [];
  if datatype(iType)
    clear newdata
    % compute new data values
    switch iType
      case 1
        %rp
        respdata = diff(respstamp);
        newdata.header.chantype = 'rp';
        action_msg = 'Respiration converted to respiration period';
        newdata.header.units = 's';
      case 2
        %ra
        for k = 1:(numel(respstamp) - 1)
          win = ceil(respstamp(k) * data.header.sr):ceil(respstamp(k + 1) * data.header.sr);
          respdata(k) = range(resp(win));
        end
        newdata.header.chantype = 'ra';
        action_msg = 'Respiration converted to respiration amplitude';
        newdata.header.units = 'unknown';
      case 3
        %rfr
        ibi = diff(respstamp);
        for k = 1:(numel(respstamp) - 1)
          win = ceil(respstamp(k) * data.header.sr):ceil(respstamp(k + 1) * data.header.sr);
          respdata(k) = range(resp(win))/ibi(k);
        end
        newdata.header.chantype = 'rfr';
        action_msg = 'Respiration converted to rfr';
        newdata.header.units = 'unknown';
      case 4
        %rs
        newdata.header.chantype = 'rs';
        action_msg = 'Respiration converted to respiration time stamps';
        newdata.header.units = 'events';
    end
    channel_str = num2str(options.channel);
    o.msg.prefix = sprintf(...
      'Respiration preprocessing :: Input channel: %s -- Input channeltype: %s -- Output channel: %s -- Action: %s --', ...
      channel_str, ...
      old_channeltype, ...
      newdata.header.chantype, ...
      action_msg);
    % interpolate
    switch iType
      case {1, 2, 3}
        newt = (1/sr):(1/sr):infos.duration;
        if ~isempty(respdata)
          % assign rp/ra/RFR to following zero crossing
          writedata = interp1(respstamp(2:end), respdata, newt, 'linear');
          nanindx = isnan(writedata);
          if any(nanindx)
            writedata(nanindx) = interp1(find(~nanindx),writedata(~nanindx),find(nanindx), 'nearest', 'extrap'); % avoid out-of-range values at the edges by nearest neighbour extrapolation
          end
        else
          writedata = NaN(length(newt), 1);
        end
        newdata.header.sr = sr;
      case {4}
        writedata = respstamp;
        newdata.header.sr = 1;
    end
    % write
    newdata.data = writedata(:);
    [nsts, out] = pspm_write_channel(fn, newdata, options.channel_action, o);
    if nsts == -1, return; end
    outchannel(iType) = out.channel;
  end
end
%% create diagnostic plot for detection/interpolation
if options.plot
  figure('Position', [50, 50, 1000, 500]);
  axes; hold on;
  oldsr = data.header.sr;
  oldt = (1/oldsr):(1/oldsr):infos.duration;
  newt = (1/newsr):(1/newsr):infos.duration;
  % normal breathing is 12-20 per minute, i. e. 3 - 5 s per breath. prd.
  % according to Schmidt/Thews, 10-18 per minute, i. e. 3-6 s per period
  % here we flag values outside 1-10 s breathing period
  plot(oldt, resp(1:numel(oldt)), 'k');
  plot(newt, newresp(1:numel(newt)), 'b');
  indx = (diff(respstamp)<1)|(diff(respstamp)>10);
  stem(respstamp(indx), 2*ones(size(respstamp(indx))), 'Marker', 'none', 'Color', 'r', 'LineWidth', 4);
  stem(respstamp, ones(size(respstamp)), 'Marker', 'o', 'Color', 'b');
end
sts = 1;
outchannel = outchannel(datatype(1:(end-1)));
return
