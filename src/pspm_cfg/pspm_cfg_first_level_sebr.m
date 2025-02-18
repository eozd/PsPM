function cfg = pspm_cfg_first_level_sebr

% $Id$
% $Rev$


%% First Level
cfg        = cfg_repeat;
cfg.name   = 'Startle eyeblink';
cfg.tag    = 'sebr';
cfg.values = {pspm_cfg_glm_sebr};
cfg.forcestruct = true;
cfg.help   = {''};
