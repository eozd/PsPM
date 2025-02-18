function out = pspm_cfg_run_glm_ps_fc(job)

% initialise
model = struct();
options = struct();

% set modality
model.modality = 'pupil';
model.modelspec = 'ps_fc';

% basis function
bf = fieldnames(job.bf);
bf = bf{1};
if any(strcmp(bf,{'psrf_fc0', 'psrf_fc1', 'psrf_fc2'}))
  model.bf.fhandle = str2func('pspm_bf_psrf_fc');
  switch bf
    case 'psrf_fc0'
      cs = 1;
      cs_d = 0;
      us = 0;
    case 'psrf_fc1'
      cs = 1;
      cs_d = 1;
      us = 0;
    case 'psrf_fc2'
      cs = 1;
      cs_d = 0;
      us = 1;
    case 'psrf_fc3'
      cs = 0;
      cs_d = 0;
      us = 1;
  end
  model.bf.args = [cs, cs_d, us];
elseif strcmp(bf, 'psrf_erl')
  model.bf.fhandle = str2func('pspm_bf_psrf_erl');
  model.bf.args = [];
end

out = pspm_cfg_run_glm(job, model, options);
