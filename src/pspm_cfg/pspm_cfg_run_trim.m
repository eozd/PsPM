function out = pspm_cfg_run_trim(job)
% Updated on 19-12-2023 by Teddy
options = struct();
options = pspm_update_struct(options, job, {'overwrite'});
from = job.from;
to = job.to;
if isfield(job.ref,'ref_file')
  ref = 'file';
elseif isfield(job.ref,'ref_mrk')
  ref = 'marker';
  options.marker_chan_num = pspm_cfg_selector_channel('run', job.ref.ref_mrk.chan);
elseif isfield(job.ref,'ref_any_mrk')
  ref = job.ref.ref_any_mrk.mrkno;
  options.marker_chan_num = pspm_cfg_selector_channel('run', job.ref.ref_any_mrk.chan);  
elseif isfield(job.ref,'ref_mrk_vals')
  ref = {job.ref.ref_mrk_vals.mrkval_from,...
    job.ref.ref_mrk_vals.mrkval_to};
  options.marker_chan_num = pspm_cfg_selector_channel('run', job.ref.ref_mrk_vals.chan);  
else
  error('Reference invalid');
end
[sts, out] = pspm_trim(job.datafile{1}, from, to, ref, options);
out = {out}; % convert to cell for dependency handling of file names
