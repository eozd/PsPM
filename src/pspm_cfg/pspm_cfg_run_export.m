function out = pspm_cfg_run_export(job)
% Updated on 19-12-2023 by Teddy
options = struct();
modelfile = job.datafile;
if isfield(job.target, 'screen')
  target = 'screen';
else
  target = pspm_cfg_selector_outputfile('run', job.target, 'tsv');
  options.overwrite = job.target.output.overwrite;
end
delimfield = fieldnames(job.delim);
delim = job.delim.(delimfield{1});
options.delim     = delim;
options.target    = target;
options.statstype = job.datatype;
options = pspm_update_struct(options, job, 'exclude_missing');
% exclude conditions with too many NaN
pspm_export(modelfile, options);
out = target;
