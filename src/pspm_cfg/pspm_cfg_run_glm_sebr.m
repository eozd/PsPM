function out = pspm_cfg_run_glm_sebr(job)

% initialise
model = struct();
options = struct();

% set modality
model.modality = 'emg_pp';
model.modelspec = 'sebr';

% basis function
rf = fieldnames(job.bf.rf);
rf = rf{1};
if any(strcmp(rf,{'sebrf0', 'sebrf1'}))
  model.bf.fhandle = str2func('pspm_bf_sebrf');
  if strcmp(rf, 'sebrf0')
    model.bf.args = [];
  elseif strcmp(rf, 'sebrf1')
    model.bf.args = 1;
  end
end


out = pspm_cfg_run_glm(job, model, options);
