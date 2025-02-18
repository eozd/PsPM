function [sts, outchannel, outinfos] = pspm_find_sounds(fn, options)
% ● Description
%   pspm_find_sounds finds (and if requested analyzes) sound events in a 
%   PsPM data file. This function can be used to precisely define the onset
%   of startle sounds for GLM-based analysis of startle eye blink data. The
%   detected events are written into a marker channel. 
%   A sound is detected as event if it is longer than 10 ms, and events are
%   recognized as distinct if they are at least 50 ms appart. Various
%   options allow customizing the algorithm to specific experimental
%   settings. In particular, events can be constrained to be in the
%   vicinity of event markers, and/or a desired number of events can be 
%   specified. 
% ● Format
%   [sts, channel_index, info] = pspm_find_sounds(fn, options)
% ● Arguments
%   *             fn : path and filename of the pspm file holding the sound
%   ┌─────── options
%   ├───────.channel : [optional, numeric/string, default: 'snd', i.e. last sound channel
%   │                  in the file] Channel type or channel ID to be preprocessed. Channel
%   │                  can be specified by its index (numeric) in the file, or by channel
%   │                  type (string). If there are multiple channels with this type, only
%   │                  the last one will be processed. If you want to preprocess several
%   │                  sound in a PsPM file, call this function multiple times with the
%   │                  index of each channel. In this case, set the option
%   │                  'channel_action' to 'add', to store each resulting channel
%   │                  separately.
%   ├.channel_action : ['add'/'replace'] sound events are written as marker channel to the
%   │                  specified pspm file. Onset times then correspond to marker events
%   │                  and duration is written to markerinfo. The values 'add' or
%   │                  'replace' state whether existing marker channels should be
%   │                  replaced (last found marker channel will be overwritten) or
%   │                  whether the new channel should be added at the end of the data
%   │                  file. Default is 'add'.
%   ├───.diagnostics : [0 (default) or 1] 
%   │                  Computes the delay between marker and detected sound, displays the
%   │                  mean delay and standard deviation.
%   ├──────.maxdelay : [number] Upper limit (in seconds) of the window in which
%   │                  pspm_find_sounds will accept sounds as relating to a marker.
%   │                  Default as 3 s.
%   ├──────.mindelay : [number] Lower limit (in seconds) of the window in which
%   │                  pspm_find_sounds will accept sounds as relating to a marker.
%   │                  Default is 0 s.
%   ├──────────.plot : [0(default) or 1] Display a histogramm of the delays found and a plot
%   │                  with the detected sound, the trigger and the onset of the sound
%   │                  events. These are color coded for delay, from green (smallest
%   │                  delay) to red (longest). Forces the 'diagnostics' option to true.
%   ├.channel_output : ['all'/'corrected'; 'corrected' requires enabled 
%   │                  diagnostics, but does not force it (the option will 
%   │                  otherwise not work).] Defines whether all sound
%   │                  events or only sound events which were related to an 
%   │                  existing marker should be written into the output 
%   │                  marker channel. Default is all sound events.
%   ├──────.resample : [integer] Spline interpolates the sound by the factor specified.
%   │                  (1 for no interpolation, by default). Caution must be used when
%   │                  using this option. It should only be used when following
%   │                  conditions are met:
%   │                  (1) All frequencies are well below the Nyquist frequency;
%   │                  (2) The signal is sinusoidal or composed of multiple sin waves
%   │                      all respecting condition 1.
%   │                  Resampling will restore more or less the original signal and lead
%   │                  to more accurate timings.
%   ├───────────.roi : [vector of 2 floats] Region of interest for discovering sounds.
%   │                  Especially useful if pairing events with markers. Only sounds
%   │                  included inbetween the 2 timestamps will be considered.
%   ├─────.threshold : [0...1] percent of the max of the power in the signal that will be
%   │                  accepted as a sound event. Default is 0.1.
%   ├.marker_chan_num: [integer] number of a channel holding markers. By default first
%   │                  'marker' channel.
%   └.expectedSoundCount : [integer] Checks for correct number of detected sounds. If too
%                      few are found, lowers threshold until at least specified count is
%                      reached. Threshold is lowered by .01 until 0.05 is reached for a max
%                      of 95 iterations. This is a EXPERIMENTAL variable, use with caution!
% ● Output
%   *  channel_index : index of channel containing the processed data
%   ┌───────────info
%   ├───.snd_markers : vector of begining of sound sound events
%   └────────.delays : vector of delays between markers and detected sounds. Only
%                      available with option 'diagnostics' turned on.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Samuel Gerster (University of Zurich)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = [];
outinfos = struct();

% check input
% -------------------------------------------------------------------------
if nargin < 1
  warning('ID:invalid_input','No input. Don''t know what to do.'); return;
elseif nargin < 2
    options = struct();
end

options = pspm_options(options, 'find_sounds');
if options.invalid
  return
end

fprintf('Processing sound in file %s\n',fn);

% Load Data
[lsts, snd] = pspm_load_channel(fn, options.channel, 'snd');
if lsts < 1
  return;
end

%% Sound

% Process Sound
snd.data = snd.data-mean(snd.data);
snd.data = snd.data/(max(snd.data));
tsnd = (0:length(snd.data)-1)'/snd.header.sr;

if options.resample>1
  % Interpolate data to restore sin like wave for more precision
  t = (0:1/options.resample:length(snd.data)-1)'/snd.header.sr;
  snd_pow = interp1(tsnd,snd.data,t,'spline').^2;
else
  t = tsnd;
  snd_pow = snd.data.^2;
end
% Apply simple bidirectional square filter
snd_pow = snd_pow-min(snd_pow);
mask = ones(round(.01*snd.header.sr),1)/round(.01*snd.header.sr);
snd_pow = conv(snd_pow,mask);
snd_pow = sqrt(snd_pow(1:end-length(mask)+1).*snd_pow(length(mask):end));

%% Process roi option
if isempty(options.roi)
  ll = 1;
  ul = length(snd.data);
else
  ll = dsearchn(t,options.roi(1));
  ul = dsearchn(t,options.roi(2));
end
roi_mask = false(size(snd.data));
roi_mask(ll:ul) = true;
loc_snd_pow = snd_pow;
loc_snd_pow(~roi_mask) = 0;


%% Find sound events
searchForMoreSounds = true;
while searchForMoreSounds == true
  clear snd_pres
  thresh_l = max(loc_snd_pow)*options.threshold;
  snd_pres(loc_snd_pow>thresh_l) = 1;
  snd_pres(loc_snd_pow<=thresh_l) = 0;
  % Convert detected sounds into events. If pulses are separated by less than
  % 50ms, combine into one event.
  mask = ones(round(0.05*snd.header.sr*options.resample),1);
  n_pad = length(mask)-1;
  c = conv(snd_pres,mask)>0;
  snd_pres = (c(1:end-n_pad) & c(n_pad+1:end));

  % Find rising and falling edges
  snd_re = t(conv([1,-1],snd_pres(1:end-1)+0)>0);
  % Find falling edges
  snd_fe = t(conv([1,-1],snd_pres(1:end-1)+0)<0);
  if numel(snd_re) ~= 0 && numel(snd_fe) ~= 0
    % Start with a rising and end with a falling edge
    if snd_re(1)>snd_fe(1)
      snd_re = snd_re(2:end);
    end
    if snd_fe(end) < snd_re(end)
      snd_fe = snd_fe(1:end-1);
    end
  end
  % Discard sounds shorter than 10ms
  noevent_i = find((snd_fe-snd_re)<0.01);
  snd_re(noevent_i)=[];
  snd_fe(noevent_i)=[];

  % find sound in sound
  if isstruct(options.snd_in_snd)
    % look for sound bursts of specific length option.snd_in_snd.width
    % within previously found sounds

    % go through all detected events
    clear snd_re_l snd_fe_l;
    for i_re = 1:length(snd_re)
      % if the detected sound is too small to be a possible snd in
      % snd ignore and continue for loop
      if (snd_fe(i_re) - snd_re(i_re)) < options.snd_in_snd.max_width
        continue
      end

      % get event's sound power, remoce DC component and normalize
      loc_snd_pow_l = loc_snd_pow(t>snd_re(i_re) & t<snd_fe(i_re));
      loc_snd_pow_l = loc_snd_pow_l-mean(loc_snd_pow_l);
      loc_snd_pow_l = loc_snd_pow_l/range(loc_snd_pow_l);
      % create time vector
      t_l = t(t>snd_re(i_re) & t<snd_fe(i_re));

      thresh_l = options.snd_in_snd.threshold;
      snd_pres_l = [];
      snd_pres_l(loc_snd_pow_l>thresh_l) = 1;
      snd_pres_l(loc_snd_pow_l<=thresh_l) = 0;
      % Convert detected sounds into events. If pulses are separated by less than
      % 10ms, combine into one event.
      mask_l = ones(round(0.01*snd.header.sr*options.resample),1);
      n_pad_l = length(mask_l)-1;
      c_l = conv(snd_pres_l,mask_l)>0;
      snd_pres_l = (c_l(1:end-n_pad_l) & c_l(n_pad_l+1:end));

      % Find rising and falling edges
      if sum(snd_pres_l)>0
        snd_re_l(i_re) = t_l(conv([1,-1],snd_pres_l(1:end-1)+0)>0); %#ok<*AGROW>
        % Find falling edges
        snd_fe_l(i_re) = t_l(conv([1,-1],snd_pres_l(1:end-1)+0)<0);
      else
        snd_re_l(i_re)=NaN;
        snd_fe_l(i_re)=NaN;
      end
    end
    snd_re_l(isnan(snd_re_l))=[];
    snd_fe_l(isnan(snd_fe_l))=[];
    if numel(snd_re_l) ~= 0 && numel(snd_fe_l) ~= 0
      % Start with a rising and end with a falling edge
      if snd_re_l(1)>snd_fe_l(1)
        snd_re_l = snd_re_l(2:end);
      end
      if snd_fe_l(end) < snd_re_l(end)
        snd_fe_l = snd_fe_l(1:end-1);
      end
    end
    % discard empty fields
    snd_re_l(snd_re_l==0)=[];
    snd_fe_l(snd_fe_l==0)=[];

    % assigne new values
    snd_re = snd_re_l';
    snd_fe = snd_fe_l';
  end

  % keep current snd_re for channel_output 'all'
  snd_re_all = snd_re;
  snd_fe_all = snd_fe;

  %% Triggers
  if options.diagnostics
    [lsts, mkr] = pspm_load_channel(fn, options.marker_chan_num, 'marker');
    if lsts == -1
      return;
    end

    %% Estimate delays from trigger to sound
    delays = nan(length(mkr.data),1);
    snd_markers = nan(length(mkr.data),1);
    for i=1:length(mkr.data)
      % Find sound onset in region of interest
      t_re = snd_re(find(snd_re>mkr.data(i)+options.mindelay,1));
      delay = t_re-mkr.data(i);
      if delay<options.maxdelay
        delays(i) = delay;
        snd_markers(i)=t_re;
      end
    end
    delays(isnan(delays)) = [];
    %if isempty(delays)
    %    warning('ID:out_of_range', 'Too strict max delay was set, no results would be generated.');
    %end
    snd_markers(isnan(snd_markers)) = [];
    % Discard any sound event not related to a trigger
    if ~isempty(snd_fe)
      snd_fe = snd_fe(dsearchn(snd_re,snd_markers));
    end
    if ~isempty(snd_re)
      snd_re = snd_re(dsearchn(snd_re,snd_markers));
    end
    %% Display some diagnostics
    fprintf(['%4d sound events associated with a marker found\n', ...
      'Mean Delay : %5.1f ms\nStd dev    : %5.1f ms\n'],...
      length(snd_markers),mean(delays)*1000,std(delays)*1000);

    outinfos.delays = delays;
    outinfos.snd_markers = snd_markers;
  end
  if length(snd_re)>=options.expectedSoundCount
    searchForMoreSounds = false;
  elseif options.threshold < .05
    searchForMoreSounds = false;
    warning('ID:max_iteration','Not enough sounds could be detected to match expectedSoundCount option, result is incomplete');sts=2;
  else
    options.threshold = options.threshold - 0.01;
    warning('ID:bad_data',sprintf('Only %d sounds detected but %d expected. threshold lowered to %3.2f',...
      length(snd_re),options.expectedSoundCount,options.threshold));sts=2;
  end
end

%% Save as new channel
% Save the new channel
if strcmpi(options.channel_output, 'all')
    snd_events.data = snd_re_all;
    vals = snd_fe_all-snd_re_all;
    snd_events.markerinfo.value = vals;
    vals_cell =num2cell(vals);
    snd_events.markerinfo.name = cellfun(@(x) num2str(x),vals_cell,'UniformOutput',0);
else
    snd_events.data = snd_re;
    vals =snd_fe-snd_re;
    snd_events.markerinfo.value = vals;
    vals_cell =num2cell(vals);
    snd_events.markerinfo.name = cellfun(@(x) num2str(x),vals_cell,'UniformOutput',0);
end

% marker channels have sr = 1 (because marker events are specified in
% seconds)
snd_events.header.sr = 1;
snd_events.header.chantype = 'marker';
snd_events.header.units ='events';
[~, ininfos] = pspm_write_channel(fn, snd_events, options.channel_action);
outchannel = ininfos.channel;

%% Plot Option
if options.plot
  % Histogramm
  fh = findobj('Tag','delays_hist');
  if isempty(fh)
    fh=figure('Tag','delays_hist');
  else
    figure(fh)
  end
  % use version dependent histogram function
  if verLessThan('matlab', '8.4')
    hist(delays*1000,10)
  else
    histogram(delays*1000, 10)
  end
  set(get(gca, 'title'), ...
      'String', 'Sound onset delay wrt marker', ...
      'FontSize', 18, ...
      'FontWeight', 'Bold');
  set(get(gca, 'xlabel'), ...
      'String', 'Time [ms]', ...
      'FontSize', 15, ...
      'FontWeight', 'Bold');
  set(get(gca, 'ylabel'), ...
      'String', 'Frequency', ...
      'FontSize', 15, ...
      'FontWeight', 'Bold');
  set(gca, ...
      'FontSize', 12, ...
      'FontWeight', 'Bold');
  if options.resample
    % downsample for plot
    t = t(1:options.resample:end);
    snd_pres = snd_pres(1:options.resample:end);
  end
  % Time series
  fh = findobj('Tag','delays_time_series');
  if isempty(fh)
    fh=figure('Tag','delays_time_series');
  else
    figure(fh)
  end

  plot(t,snd_pres)
  hold on
  scatter(mkr.data,ones(size(mkr.data))*.1,'k')
  colormap jet
  for i = 1:length(delays)
    clr = (delays(i)-min(delays))/range(delays);
    scatter(snd_re(i),.2,500,clr,'.')
  end
  set(get(gca, 'xlabel'), ...
      'String', 'Time [s]', ...
      'FontSize', 15, ...
      'FontWeight', 'Bold');
  set(get(gca, 'title'), ...
      'String', 'Markers and sound onsets', ...
      'FontSize', 18, ...
      'FontWeight', 'Bold');
  legend('Detected sound','Marker','Sound onset (color-coded delay)');
  colorbar('Ticks', [0, 1], 'TickLabels', {'Min delay', 'Max delay'});
    set(gca, ...
      'YTick', [], ...  
      'FontSize', 12, ...
      'FontWeight', 'Bold');
hold off
end

%% Return values
sts = 1;
