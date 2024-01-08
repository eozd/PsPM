function out = pspm_cfg_run_artefact_rm(job)
% Reviewed and updated on 18-Dec-2023 by Teddy
options = struct;
options = pspm_update_struct(options, job, {'overwrite'});
filtertype = fieldnames(job.filtertype);
filtertype = filtertype{1};
datafile = job.datafile;
datafile = datafile{1};
channelnumber = job.chan_nr;
switch filtertype
  case 'median'
    n = job.filtertype.(filtertype).nr_time_pt;
    out = pspm_pp(filtertype, datafile, n, channelnumber, options);
  case 'butter'
    freq = job.filtertype.(filtertype).freq;
    out = pspm_pp(filtertype, datafile, freq, channelnumber, options);
  case 'scr_pp'
    scr_job = job.filtertype.(filtertype);
    options = pspm_update_struct(options, scr_job, {'min',...
                                                    'max',...
                                                    'slope',...
                                                    'deflection_threshold',...
                                                    'data_island_threshold',...
                                                    'expand_epochs'})
    if isfield(scr_job.missing_epochs, 'write_to_file')
      if isfield(scr_job.missing_epochs.write_to_file,'filename') && ...
          isfield(scr_job.missing_epochs.write_to_file,'outdir')
        options.missing_epochs_filename = fullfile(...
          scr_job.missing_epochs.write_to_file.outdir{1}, ...
          scr_job.missing_epochs.write_to_file.filename);
      end
    end
    if isfield(scr_job, 'change_data')
      options.channel_action = 'add';
    else
      options.channel_action = 'replace';
    end
    [~, out] = pspm_scr_pp(datafile, options);
end
