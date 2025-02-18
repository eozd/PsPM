function [ sts, outchannel ] = pspm_convert_ppg2hb( fn , options )
% ● Description
%   pspm_convert_ppg2hb converts a pulse oxymeter channel to heartbeats.
%   Two methods are available: (1) Template-matching algorithm (method 
%   "classic"): First a template is generated from non-ambiguous 
%   heartbeats. The ppg signal is then cross-correlated with the template 
%   and maxima are identified as heartbeats. (2) HeartPy (see reference
%   [1], requires Python installation. 
% ● Format
%   [sts, channel_index] = pspm_convert_ppg2hb( fn, options )
% ● Arguments
%   *             fn: file name with path
%   ┌────────options
%   ├────────.method: 'classic' (default) or 'heartpy'.
%   ├───────.channel: [optional, numeric/string, default: 'ppg', i.e. last
%   │                 PPG channel in the file]
%   │                 Channel type or channel ID to be preprocessed.
%   │                 Channel can be specified by its index (numeric) in the
%   │                 file, or by channel type (string).
%   │                 If there are multiple channels with this type, only
%   │                 the last one will be processed. If you want to
%   │                 process several PPG channels in a PsPM file,
%   │                 call this function multiple times with the index of
%   │                 each channel.  In this case, set the option
%   │                 'channel_action' to 'add',  to store each
%   │                 resulting 'hb' channel separately.
%   ├───.diagnostics: [true/FALSE]
%   │                 displays some debugging information
%   ├.channel_action: ['add'/'replace', 'replace']
%   │                 Defines whether the interpolated
%   │                 data should be added or the corresponding channel
%   │                 should be replaced.
%   ├───────.missing: allows to specify missing (e. g. artefact) epochs in the
%   │                 data file. See pspm_get_timing for epoch definition. This
%   │                 must always be specified in SECONDS. These epochs will be
%   │                 set to 0 for the detection.
%   │                 Default: no missing values
%   ├───────────.lsm: [integer] for method 'classic'
%   │                 large spikes mode compensates for large spikes
%   │                 while generating template by removing the [integer]
%   │                 largest percentile of spikes from consideration.
%   └───.python_path: [char] for method 'heartpy'
%                     The path where python can be found. Mandatory if
%                     python environment is not yet set up
% ● Output
%   *  channel_index: index of channel containing the processed data
% ● References
%   [1] van Gent, P, Farah, H, van Nes, N, & van Arem, B. (2019) Heartpy: 
%   A novel heart rate algorithm for the analysis of noisy signals. 
%   Transportation Research Part F: Traffic Psychology and Behaviour 66, 
%   368–378. 
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by Samuel Gerster (University of Zurich)
%                      Tobias Moser (University of Zurich)
%   Updated in 2024 by Dominik Bach/Uzay Gokay (Uni Bonn)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = [];

%% check input
% -------------------------------------------------------------------------
if nargin < 1
  warning('ID:invalid_input', 'No input. Don''t know what to do.'); return;
elseif nargin < 2
  options = struct();
  options.channel = 'ppg';
end

options = pspm_options(options, 'convert_ppg2hb');
if options.invalid
  return
end

%% user output
% -------------------------------------------------------------------------
fprintf('Heartbeat detection for %s ... \n', fn);

% get data
% -------------------------------------------------------------------------
[nsts, data, infos, pos_of_channel] = pspm_load_channel(fn, options.channel, 'ppg');
if nsts == -1, return; end

ppg = data.data;
sr = data.header.sr;

% process missing data
nan_index = isnan(ppg);
if ~isempty(nan_index)
  ppg(nan_index) = 0;
end

if ~isempty(options.missing)
  [sts, missing] = pspm_get_timing('epochs', options.missing, 'seconds');
  if sts < 1, return; end
  index   = pspm_epochs2logical(missing, numel(ppg), sr);
  if (sum(index) > 0)
    ppg(find(index)) = 0; % sometimes the logical indexing does not work even though index contains only 0 and 1 and is of correct size
  end
end

% -------------------------------------------------------------------------
%% Heartpy
if strcmpi(options.method, 'heartpy')
  % initialise python
  if isempty(options.python_path)
    psts = pspm_check_python;
  else
    psts = pspm_check_python(options.python_path);
  end
  if psts < 1, return; end
  psts = pspm_check_python_modules('heartpy');
  if psts < 1, return; end

  filtered_ppg = py.heartpy.filter_signal(ppg, ...
    pyargs('cutoff', [1,20], ...
    'filtertype',  'bandpass', ...
    'sample_rate', sr, ...
    'order', 3));
  filtered_ppg = double(py.array.array('d',(filtered_ppg)));
  try
    tup = py.heartpy.process(filtered_ppg, pyargs('sample_rate', sr));
    wd = tup{1};
    m = tup{2};
    py_peak_list =  py.array.array('d',(wd{'peaklist'}));
    py_removed =  py.array.array('d',(wd{'removed_beats'}));
    peak_list = double(py_peak_list) ;
    rejected_peaks = double(py_removed);
    msg = sprintf(['Heart beat detection from PPG with cross correlation ',...
      'HB-timeseries added to data on %s'],...
      date);
    hb = peak_list(:) / sr;
  catch
    msg = sprintf('HeartPy did not find any heart beats on %s', date);
    hb = [];
  end
else
  %% large spike mode
  if options.lsm
    fprintf('Entering large spikes mode. This might take some time.');
    % Look for all peaks lower than 200 bpm (multiple of two in heart rate
    %  to compensate for absolute value and therefore twice as mani maxima)
    [pks,pis] = findpeaks(abs(ppg),...
      'MinPeakDistance',30/200*sr);
    % Ensure at least one spike is removed by adapting quantil to realistic
    % values, given number of detected spikes
    q = floor(length(pks)*(1-options.lsm/100))/length(pks);
    % define large spikes index as last lsm percentile (or as adapted above)
    lsi = pks>quantile(pks,q);
    %define a minimum peak prominence 2/3 of non large spikes range (more
    %or less)
    minProm = max(pks(~lsi))*2/3;
    % save indexes of large spikes for later removal while generating
    % template
    lsi = pis(lsi);
    fprintf('   done.\n');
  else
    minProm = range(ppg)/3;
  end

  %% Create template
  %--------------------------------------------------------------------------
  fprintf('Creating template. This might take some time.');
  % Find prominent peaks for a max heart rate of 200 bpm
  [~,pis] = findpeaks(ppg,...
    'MinPeakDistance',60/200*sr,...
    'MinPeakProminence',minProm);

  if options.lsm
    % Remove large spikes from
    [~,lsi_in_pis,~] = intersect(pis,lsi);
    pis(lsi_in_pis) = [];
  end

  % handle possible errors
  if isempty(pis),warning('ID:NoPulse', 'No pulse found, nothing done.');return;end
  if length(pis)==1,warning('ID:OnePulse', 'Only one pulse found, unable to calculate min_pulse_period.');return;end

  % get pulse period lower limit (assumed onset) as 30% of smalest period
  % before detected peaks
  min_pulse_period = min(diff(pis));
  period_index_lower_bound = floor(pis(2:end-1)-.3*min_pulse_period);
  fprintf('...');

  % Create template from mean of peak time-locked ppg pulse periods
  pulses = cell2mat(arrayfun(@(x) ppg(x:x+min_pulse_period),period_index_lower_bound','un',0));
  template = mean(pulses,2);
  fprintf('done.\n');

  % handle diagnostic plots relevant to template building
  if options.diagnostics
    t_template = (0:length(template)-1)'/sr;
    t_pulses = repmat(t_template,1,length(pis)-2);
    figure
    plot(t_pulses,pulses,'--')
    set(gca,'NextPlot','add')
    plot(t_template,template,'k','lineWidth',3)
    xlabel('time [s]')
    ylabel('Amplitude')
    title('Generated ppg template (bk) and pulses used (colored)')
  end

  %% Cross correlate the signal with the template and find peaks
  %--------------------------------------------------------------------------
  fprintf('Applying template.');
  ppg_corr = xcorr(ppg,template)/sum(template);
  % Truncate ppg_xcorr and realigne it so the max correlation corresponds to
  % templates peak and not beginning of template.
  ppg_corr = ppg_corr(length(ppg)-floor(.3*min_pulse_period):end-floor(.3*min_pulse_period));
  if options.diagnostics
    t_ppg = (0:length(ppg)-1)'/sr;
    figure
    if length(t_ppg) ~= length(ppg_corr)
      length(t_ppg)
    end
    plot(t_ppg,ppg_corr,t_ppg,ppg)
    xlabel('time [s]')
    ylabel('Amplitude')
    title('ppg cross-corelated with template and ppg')
    legend('ppg (X) template','ppg')
  end
  % Get peaks that are at least one template width appart. These are the best
  % correlation points.
  [~,hb] = findpeaks(ppg_corr/max(ppg_corr),...
    sr,...
    'MinPeakdistance',min_pulse_period/sr);
end


%% Prepare output and save
%--------------------------------------------------------------------------
% save data
fprintf('Saving data.');
msg = sprintf('Heart beat detection from ppg with cross correlation HB-timeseries added to data on %s', date);

newdata.data = hb(:);
newdata.header.sr = 1;
newdata.header.units = 'events';
newdata.header.chantype = 'hb';

write_options = struct();
write_options.msg = msg;
write_options.channel = pos_of_channel;

% Replace last existing channel or save as new channel
[nsts, nout] = pspm_write_channel(fn, newdata, options.channel_action, write_options);
if ~nsts
  return
end
% user output
fprintf('  done.\n');
sts = 1;
outchannel = nout.channel;
return
