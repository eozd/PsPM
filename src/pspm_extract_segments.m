function [sts, out] = pspm_extract_segments(method, data, varargin)
% ● Description
%   pspm_extract_segments extracts data segments of fixed length after 
%   defined onsets, groups them by condition, and computes summary 
%   statistics (mean, SD, SEM, NaN) for each condition. This is a 
%   first-level (subject-level) function. 
%   The function supports automated extraction from a model file, or
%   manually defining timing definitions and extracting from a PsPM data 
%   file. For non-linear models, each trial will be treated as a separate 
%   condition unless trial names were specified in the model setup.
%   The function returns a cell array of struct named 'segments'
%   with c elements, where c is the number of conditions 
%   specified. Each element contains the following fields: data, mean, std, 
%   sem, trial_nan_percent, and total_nan_percent. 
%   The output can also be written to a matlab file. 
% ● Format
%   [sts, segments] = pspm_extract_segments('file', data_fn, channel, timing, options)
%   [sts, segments] = pspm_extract_segments('data', data, sr, timing, options)
%   [sts, segments] = pspm_extract_segments('model', modelfile, options)
% ● Arguments
%   *               mode:  Tells the function in which mode get the
%                          settings from. Either 'file', 'data', or 'model'.
%   *          modelfile:  Path to the glm or dcm file or a glm/dcm structure.
%   *            data_fn:  Path or cell of paths to data file from which
%                          the segments should be extracted.
%   *               data:  Numeric data or a cell array of numeric data.
%   *            channel:  Channel identifier accepted by pspm_load_channel
%   *                 sr:  Sample rate (ignored if options.timeunits ==
%                          'samples')
%   *             timing:  An onsets definition or file, as accepted by
%                          pspm_get_timing, or cell array thereof.
%   ┌────────────options:
%   ├─────────.timeunits: 'seconds' (default), 'samples' or 'markers'. In 'model'
%   │                     mode the value will be ignored and taken from
%   │                     the model file. In case a data vector is passed
%   │                     as input, timeunits must be 'samples' or 'seconds'.
%   ├────────────.length: Length of the segments in the specified 'timeunits'.
%   │                     The default value is 10.
%   ├──────────────.plot: [0/1] Plot mean values (solid) and standard error of
%   │                     the mean (dashed) will be ploted. Default is no plot.
%   ├────────.outputfile: Define filename to store segments. If is equal
%   │                     to '', no file will be written. Default is 0.
%   ├─────────.overwrite: Define if already existing files should be
%   │                     overwritten. Default ist 0.
%   ├───.marker_chan_num: Optional if timeunits are 'markers'. Channel
%   │                     identifier for the marker channel. Default: first
%   │                     marker channel in the file.
%   ├───────────.missing: allows to specify missing (e. g. artefact) epochs in the
%   │                     data file. See pspm_get_timing for epoch definition;
%   │                     specify a cell array for multiple input files. This
%   │                     must always be specified in SECONDS. if method is
%   │                     'model', then this option overides the missing
%   │                     values given in the model
%   │                     Default: no missing values
%   ├────────.nan_output: ['screen', filename, or 'none'] Output
%   │                     NaN ratios of the trials for each condition.
%   │                     Values can be printed on the screen or written to 
%   │                     a matlab file. Default is no NaN output.
%   └──────────────.norm: If 1, z-scores the entire data time series
%                         (default: 0).
% ● History
%   Introduced in PsPM 4.3
%   Written in 2008-2018 by Tobias Moser (University of Zurich)
%   Refactored 2024 Dominik R Bach (Uni Bonn)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
out = struct();

%% check input
if nargin < 2 || ~ischar(method) || ~ismember(method, {'file', 'data', 'model'}) || ...
        (~strcmpi(method, 'model') && nargin < 4)
    warning('ID:invalid_input', 'Don''t know what to do'); return
elseif strcmpi(method, 'model')
     [~, data, ~] = pspm_load1(data, 'all');
    if nargin > 2
        options = varargin{1};
    end
else
    timing = varargin{2};
    if nargin > 4
        options = varargin{3};
    end
end

% set options (required for next input checks)
if ~exist('options', 'var')
    options = struct();
end
options = pspm_options(options, 'extract_segments');
if options.invalid, return, end

% check consistency of input for the other methods
if strcmpi(method, 'file') % in this case use pspm_check_model to verify
    channel = varargin{1};
    model = struct('modelfile', 'dummyfile.mat', ...
                   'datafile', data, ...
                   'timing', timing, ...
                   'timeunits', options.timeunits);
    if isfield(options, 'missing')
        model.missing = options.missing;
    end
    % set overwrite = 1 to override test of existing model file
    model = pspm_check_model(model, struct('overwrite', 1), 'glm'); 
    if model.invalid, return; end
    timing = model.timing;
    datafile = model.datafile;
    if isfield(options, 'missing')
        options.missing =  model.missing;
    end
elseif strcmpi(method, 'data') % verify directly
   sr = varargin{1};
   if isnumeric(data)
       data = {data};
   elseif ~iscell(data)
        warning('ID:invalid_input', 'Data format not recognised.'); return
   end
   if ischar(timing) || isstruct(timing)
       timing = {timing};
   elseif ~iscell(timing)
        warning('ID:invalid_input', 'Onsets definition not recognised.'); return;
   end
   if ~isnumeric(sr)
        warning('ID:invalid_input', 'Sample rate definition not recognised.'); return;
   end
end

%% prepare data
events = {};
switch method
    case 'data'
        data_raw = data;
        if isnumeric(data), data_raw = {data}; end
    case 'file'
        for i_sn = 1:numel(datafile)
            [lsts, alldata{i_sn}] = pspm_load_channel(datafile{i_sn}, channel);
            if lsts < 1, return; end
            data_raw{i_sn} = alldata{i_sn}.data;
            if i_sn == 1
                sr = alldata{i_sn}.header.sr;
            elseif alldata{i_sn}.header.sr ~= sr
                warning('ID:invalid_input', 'Unequal sample rates detected.'); return;
            end
            if strcmpi(options.timeunits, 'markers')
                [lsts, markerdata] = pspm_load_channel(datafile{i_sn}, options.marker_chan_num);
                if lsts < 1, return; end
                events{i_sn} = markerdata.data;
            end
        end
case 'model'
    if strcmpi(data.modeltype, 'glm')
        data_raw = data.input.data;
        timing = data.input.timing;
        options.timeunits = data.input.timeunits;
        events = data.input.events;
    elseif strcmpi(data.modeltype, 'dcm')
        data_raw = data.input.scr;
    else
        warning('ID:invalid_input', 'Unknown model type.');
        return;
    end
    % GLM stores sample rate for each session separately, but checks if
    % they are the same and errors if not. So we can assume the first
    % element is the same as the other ones.
    sr = data.input.sr(1);
end

if options.norm
  newmat = cell2mat(data_raw(:));
  newmat = newmat(~isnan(newmat));
  if ~isempty(newmat)
      zfactor = std(newmat(:));
      offset  = mean(newmat(:));
      for iSn = 1:numel(data_raw)
        data_raw{iSn} = (data_raw{iSn} - offset) / zfactor;
      end
  end
end

%% prepare timing
for i_sn = 1:numel(data_raw)
    session_duration(i_sn, 1) = numel(data_raw{i_sn});
end

if strcmpi(method, 'model') && strcmpi(data.modeltype, 'dcm')
    temponsets = cellfun(@(x, y) pspm_time2index(x, sr , y), ...
    data.input.trlstart(:), ...
    num2cell(session_duration), ...
    'UniformOutput', false);
    trlnum = cellfun(@(x) numel(x), temponsets);
    trlnum = trlnum(:);
    % if DCM has condition information
    if isfield(data, 'trlnames') && numel(data.trlnames) == sum(trlnum)
        names = unique(data.trlnames);
        n_cond = numel(names);
        prevtrlnum = [0; cumsum(trlnum(1:(end-1)))];
        for i_cond = 1:numel(names)
            for i_sn = 1:numel(temponsets)
                snindx = prevtrlnum(i_sn) + (1:trlnum(i_sn));
                onsets{i_cond}{i_sn} = temponsets{i_sn}(strcmpi(data.trlnames(snindx), names{i_cond}));
            end
        end
    else
    % if DCM has no condition information
        names{1} = 'all';
        n_cond = 1;
        options.timeunits = 'seconds';
        onsets{1} = temponsets;
    end
else
    [lsts, multi] = pspm_get_timing('onsets', timing, options.timeunits);
     [msts, onsets] = pspm_multi2index(options.timeunits, multi, sr, session_duration, events);
     if lsts < 1 || msts < 1, return; end
     n_cond = numel(multi(1).names);
     for i_cond = 1:n_cond
         names{i_cond} = multi(1).names{i_cond};
     end
end

% onsets has the structure: onsets{i_cond}{i_sn}

%% prepare missing
if isfield(options, 'missing')
    missing = options.missing;
elseif strcmpi(method, 'model') && isfield(data.input, 'missing')
    missing = data.input.missing;
else
    missing = {};
end

if numel(missing) > numel(data_raw)
    warning('ID:invalid_input', 'Wrong number of missing epoch definitions.')
    return
elseif numel(missing) < numel(data_raw)
    for i_sn = (numel(missing) + 1):numel(data_raw)
        missing{i_sn} = [];
    end
end

missing = cellfun(@(x, y) pspm_epochs2logical(x, y, sr), missing(:), num2cell(session_duration), 'un', false);

%% extract segments
for i_cond = 1:numel(onsets)
    [sts, segments{i_cond}.data, segments{i_cond}.sessions] = pspm_extract_segments_core(data_raw, onsets{i_cond}, pspm_time2index(options.length, sr, inf, 1), missing);
    if sts < 1, return; end
end

if options.plot
  fg = figure('Name', 'Condition means and SEM', 'Visible', 'off');
  ax = axes('NextPlot', 'add');
  set(fg, 'CurrentAxes', ax);

  % load colormap
  corder = get(fg, 'defaultAxesColorOrder');
  cl = length(corder);

  % legend labels
  legend_lb = cell(n_cond*3,1);
end

%% create statistics for each condition
for c=1:numel(onsets)
  m = segments{c}.data;
  segments{c}.name = names{c};
  % create mean
  segments{c}.mean = nanmean(m, 1);
  segments{c}.std = nanstd(m, [], 1);
  segments{c}.sem = segments{c}.std./sqrt(size(segments{c}.data, 1));
  segments{c}.trial_nan_percent = 100.0 * sum(isnan(m), 2)/size(m,2);
  segments{c}.total_nan_percent = 100.0 * sum(sum(isnan(m), 2))/numel(m);
  %   segments{c}.total_nan_percent = mean(segments{c}.trial_nan_percent);
  segments{c}.t = linspace(sr^-1, numel(segments{c}.mean)/sr, numel(segments{c}.mean))';
  %% create plot per condition
  if options.plot
    p = plot(ax, segments{c}.t, segments{c}.mean, '-', ...
      segments{c}.t, segments{c}.mean + segments{c}.sem, '-', ...
      segments{c}.t, segments{c}.mean - segments{c}.sem, '-');
    % correct colors
    color = corder(mod(c,cl) + 1, :);
    set(p(1), 'LineWidth', 2, 'Color', color);
    set(p(2), 'Color', color);
    set(p(3), 'Color', color);

    legend_lb{(c-1)*3 + 1} = [names{c} ' condition mean'];
    legend_lb{(c-1)*3 + 2} = [names{c} ' mean+SEM'];
    legend_lb{(c-1)*3 + 3} = [names{c} ' mean-SEM'];

    f.lg = legend('String', legend_lb, 'Interpreter', 'none', 'Location', 'best');
    legend boxoff

    set(ax, 'FontSize', 12, 'FontWeight', 'Bold');
    set(get(ax, 'xlabel'), 'String', 'Time (seconds)', 'FontSize', 15, 'FontWeight', 'Bold');
    set(get(ax, 'ylabel'), 'String', 'Mean Response (data units)', 'FontSize', 15, 'FontWeight', 'Bold');
    set(get(ax, 'title'), 'String', 'Mean Responses for All Segments', 'FontSize', 18, 'FontWeight', 'Bold');

  end
end

%% nan_output
if ~strcmpi(options.nan_output,'none')
  %count number of trials
  trials_nr_per_cond = cell2mat(cellfun(@(x) size(x.data,1),segments,'un',0));
  trials_nr_max = max(trials_nr_per_cond);

  % create matix with values
  trials_nan(1:(trials_nr_max+1),1:n_cond) = NaN;
  for i=1:n_cond
    for j = 1:trials_nr_per_cond(i)
      nan_perc = segments{i}.trial_nan_percent(j);
      trials_nan(j,i) = nan_perc;
    end
    trials_nan(trials_nr_max+1,i) = segments{i}.total_nan_percent;
  end

  %define names of rows in table
  r_names = cellstr(strcat('Trial (per condition) #', num2str((1:trials_nr_max)')));
  r_names{end+1} = 'total';
  %create table with the right format
  trials_nan_output = array2table(trials_nan, 'VariableNames', names, 'RowNames', r_names');
  switch options.nan_output
    case 'screen'
      fprintf(['\nThe following table shows for each condition the NaN-ratio ',...
        'in the different trials.\nA NaN-value indicates ',...
        'that this trial does not occur the condition.\n',...
        'The last row indicates the average Nan-ratio over all trials ',...
        'belonging to this condition.\n\n']);
      disp(trials_nan_output);
    case 'none'
    otherwise
      %print Nan-Value in file
      %expect the path to file in options.nan_output
      %find information about file
      [path, name, ext ]= fileparts(options.nan_output);

      %if the file already exists, we overwrite the file with the
      %data. Otherwise we create a new file and save the data
      %             new_file_base = sprintf('%s.csv', name);
      new_file_base = sprintf('%s.txt', name);
      output_file = fullfile(path,new_file_base);
      fprintf(['\nThe table in file (%s)shows for each condition the NaN-ratio ',...
        'in the different trials.\nA NaN-value indicates ',...
        'that this trial does not occur the condition.\n',...
        'The last row indicates the average Nan-ratio over all trials ',...
        'belonging to this condition.\n\n'],new_file_base);
      writetable(trials_nan_output, output_file,'WriteRowNames', true ,'Delimiter', '\t');


  end
end
%% set output and save segments into file
out.segments = segments;

if ~isempty(options.outputfile)
  % ensure correct file suffix
  [pt, fn, ~] = fileparts(options.outputfile);
  outfile = [pt filesep fn '.mat'];
  
  if pspm_overwrite(options.outputfile, options.overwrite)
    save(outfile, 'segments');
    out.outputfile = outfile;   
  end


end

if options.plot
  % show plot
  set(fg, 'Visible', 'on');
end

%% Return values
sts = 1;
return
