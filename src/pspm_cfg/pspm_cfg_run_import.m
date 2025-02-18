function out = pspm_cfg_run_import(job)
% Updated on 08-01-2024 by Teddy
global settings
if isempty(settings), pspm_init; end
datatype = fieldnames(job.datatype);
datatype = datatype{1};
datafile = job.datatype.(datatype).datafile{1};
% Import
n = size(job.datatype.(datatype).importtype,2); % Nr. of channels
% Check if multioption is off
if ~iscell(job.datatype.(datatype).importtype)
  importtype = job.datatype.(datatype).importtype;
  job.datatype.(datatype).importtype = cell(1);
  job.datatype.(datatype).importtype{1} = importtype;
end
import = cell(1,n);
for i = 1:n
  % Importtype
  type = fieldnames(job.datatype.(datatype).importtype{i});
  import{i}.type = type{1};
  % Channel nr.
  channel = job.datatype.(datatype).importtype{i}.(type{1}).chan_nr;
  if isfield(channel, 'chan_search')
    import{i}.channel = 0;
  elseif isfield(channel, 'chan_nr_def')
    import{i}.channel = channel.chan_nr_def;
  else
    import{i}.channel = channel.chan_nr_spec;
  end
  % Check if sample rate is available
  if isfield(job.datatype.(datatype).importtype{i}.(type{1}), 'sample_rate')
    import{i}.sr = job.datatype.(datatype).importtype{i}.(type{1}).sample_rate;
  end
  % Check if flank option is available
  if isfield(job.datatype.(datatype).importtype{i}.(type{1}), 'flank_option') 
    import{i}.flank = job.datatype.(datatype).importtype{i}.(type{1}).flank_option;
  end
  % Check if transfer function available
  if isfield(job.datatype.(datatype).importtype{i}.(type{1}), 'scr_transfer')
    transfer = fieldnames(job.datatype.(datatype).importtype{i}.(type{1}).scr_transfer);
    transfer = transfer{1};
    switch transfer
      case 'file'
        file = job.datatype.(datatype).importtype{i}.(type{1}).scr_transfer.file;
        file = file{1};
        import{i}.transfer = file;
      case 'input'
        import{i}.transfer.c = ...
          job.datatype.(datatype).importtype{i}.(type{1}).scr_transfer.input.transfer_const;
        import{i}.transfer.Rs = ...
          job.datatype.(datatype).importtype{i}.(type{1}).scr_transfer.input.resistor;
        import{i}.transfer = pspm_update_struct(import{i}.transfer, ...
                                                job.datatype.(datatype).importtype{i}.(type{1}).scr_transfer.input, ...
                                                {'offset', 'recsys'});
      case 'none'
        import{i}.transfer = 'none';
    end
  end
  % Check if eytracker distance is available
  if ~isempty(regexpi(type, 'pupil'))
    if isfield(job.datatype.(datatype), 'eyelink_trackdist')
      transfer = job.datatype.(datatype).eyelink_trackdist;
      distance_unit = job.datatype.(datatype).distance_unit;
      if transfer > 0
        import{i}.eyelink_trackdist = transfer;
        import{i}.distance_unit = distance_unit;
      else
        import{i}.eyelink_trackdist = 'none';
        import{i}.distance_unit = '';
      end
    end
    if isfield(job.datatype.(datatype), 'viewpoint_target_unit')
      import{i}.target_unit = job.datatype.(datatype).viewpoint_target_unit;
    end
    if isfield(job.datatype.(datatype), 'smi_target_unit')
      import{i}.target_unit = job.datatype.(datatype).smi_target_unit;
      import{i}.stimulus_resolution = job.datatype.(datatype).smi_stimulus_resolution;
    end
    if isfield(job.datatype, 'acq_any')
        settings.python_path = job.datatype.(datatype).Bioread.pypath{1};
    end
    import{i} = pspm_update_struct(import{i}, ...
                                   job.datatype.(datatype), ...
                                   {'channel_names_line',...
                                    'delimiter',...
                                    'exclude_columns',...
                                    'header_lines'});
  end
end
options = struct();
options = pspm_update_struct(options, job, 'overwrite');
[sts, out] = pspm_import(datafile, datatype, import, options);
out = {out}; % convert to cell for dependency handling of file names