function [out] = pspm_cfg_run_proc_illuminance(job)
% Updated on 08-01-2024 by Teddy
src_file = job.lum_file{1};
out_file = pspm_cfg_selector_outputfile('run', job);
sr = job.sr;
options = struct();
options.fn = out_file;
options.overwrite = job.output.overwrite;
%% basis function
options.bf = struct();
dil_f = fields(job.bf.dilation);
% only check first field
switch dil_f{1}
  case 'ldrf_gm'
    options.bf.dilation.fhandle = @pspm_bf_ldrf_gm;
  case 'ldrf_gu'
    options.bf.dilation.fhandle = @pspm_bf_ldrf_gu;
end
con_f = fields(job.bf.constriction);
switch con_f{1}
  case 'lcrf_gm'
    options.bf.constriction.fhandle = @pspm_bf_lcrf_gm;
end
[~, out] = pspm_process_illuminance(src_file, sr, options);
