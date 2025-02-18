function [sts, import, sourceinfo] = pspm_get_labchart(datafile, import)
% ● Description
%   pspm_get_labchart imports ADInstruments LabChart *.adicht files. This
%   function uses an external library that requires Windows as OS. See 
%   pspm_get_labchartmat_in and pspm_get_labchartmat_ext for import of matlab
%   files that were exported either using the built-in function or the
%   online conversion tool.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_labchart(datafile, import);
% ● Arguments
%   * datafile: The data file to be imported.
%   *   import: Importing settings.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];

% add path
% -------------------------------------------------------------------------
addpath(pspm_path('Import','labchart','adi'));
% load & check data
% -------------------------------------------------------------------------
[labchart] = adi.readFile(datafile);

% check for multiple sessions
if labchart.n_records > 1
  fprintf(['\nFound (%i) sessions in file %s. ', ...
    'Will concatenate the sessions into one PsPM file.\n'], ...
    labchart.n_records, datafile);
end

% verify if all channels are constant in unit and sampling rate
chans_constant = 1;
for i_chan = 1:labchart.n_channels
  chan_spec = labchart.channel_specs(i_chan);
  chans_constant = chans_constant && (all(strcmpi(chan_spec.units{1}, chan_spec.units)) ...
    && all(chan_spec.fs(1) == chan_spec.fs));
end

if ~chans_constant
  warning('ID:invalid_data_structure', ...
    ['Not all sessions match in either units or sampling rate. ', ...
    'Will only import first session!']);
  n_records = 1;
else
  n_records = labchart.n_records;
end

% loop through import jobs
% -------------------------------------------------------------------------
for k = 1:numel(import)

  % assemble data
  offset = 0;
  rec_data = cell(n_records, 1);
  marker_name = cell(n_records, 1);
  marker_value = cell(n_records, 1);

  % find channel number if not marker channel
  if ~strcmpi(import{k}.type, 'marker')
    if import{k}.channel > 0
      channel = import{k}.channel;
    else
      channel = pspm_find_channel(cellstr(labchart.chan_names(:)), import{k}.type);
      if channel < 1, return; end
    end
    if channel > labchart.n_channels
      warning('ID:channel_not_contained_in_file', ...
        'Channel %02.0f not contained in file %s.\n', channel, datafile);
      return;
    end
    lab_chan = labchart.channel_specs(channel);
  end

  % loop through records
  for i_record = 1:n_records

    % add offset
    if (i_record - 1) > 0
      offset = labchart.records(i_record-1).duration + offset;
    end
    if strcmpi(import{k}.type, 'marker')
      comments = labchart.records(i_record);
      if ~isempty(comments.comments)
        rec_data{i_record} = [comments.comments(:).tick_position]'./comments.tick_fs + offset;
        marker_value{i_record} = {comments.comments.id}';
        marker_name{i_record} = {comments.comments.str}';
      else
        rec_data(i_record) = [];
      end
    else
      % get data ---
      rec_data{i_record} = lab_chan.getData(i_record);
    end
  end

  import{k}.data = cell2mat(rec_data);
  if strcmpi(import{k}.type, 'marker')
    import{k}.sr     = 1;
    import{k}.marker = 'timestamps';
    import{k}.markerinfo = struct('name', {vertcat(marker_name{:})}, ...
      'value', {cell2mat(vertcat(marker_value{:}))});
    sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', k, 'Events');
  else
    % get units ---
    import{k}.units = lab_chan.units{1};
    % get sr ---
    import{k}.sr = lab_chan.fs(1);
    sourceinfo.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, ...
      labchart.chan_names{channel});
  end
end

delete(labchart.file_h);
% clear path and return
% -------------------------------------------------------------------------
rmpath(pspm_path('Import','labchart','adi'));
sts = 1;
return
