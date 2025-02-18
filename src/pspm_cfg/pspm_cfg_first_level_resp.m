function cfg = pspm_cfg_first_level_resp

% $Id$
% $Rev$


%% First Level
cfg        = cfg_repeat;
cfg.name   = 'Respiration';
cfg.tag    = 'resp';
cfg.values = {pspm_cfg_glm_ra_fc, pspm_cfg_glm_ra_e, pspm_cfg_glm_rfr_e, ...
    pspm_cfg_glm_rp_e}; % Values in a cfg_repeat can be any cfg_item objects
cfg.forcestruct = true;
cfg.help   = {''};
