function [out] = pspm_cfg_run_find_sounds(job)
% Updated on 19-12-2023 by Teddy
file = job.datafile{1};
options = struct();
options.channel = pspm_cfg_selector_channel('run', job.chan);
options.channel_action = job.channel_action;
if isfield(job.roi, 'region')
  options.roi = job.roi.region;
end
options = pspm_update_struct(options, job, 'threshold');
if isfield(job.diagnostic, 'diagnostics')
    options.diagnostics = 1;
    d = job.diagnostic.diagnostics;
    if isfield(d.create_corrected_chan, 'yes')
        options.channel_output = 'corrected';
    end
    options.marker_chan_num = pspm_cfg_selector_channel('run', d.chan);
    if d.n_sounds > 0
      options.expectedSoundCount = d.n_sounds;
    end
    options.maxdelay = d.max_delay;
    diag_out = fieldnames(d.diag_output);
    switch diag_out{1}
      case 'hist_plot'
        options.plot = 1;
      case 'text_only'
        options.plot = 0;
    end
end
[~, out, ~] = pspm_find_sounds(file, options);

