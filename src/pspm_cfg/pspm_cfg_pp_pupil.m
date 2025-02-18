function [cfg] = pspm_cfg_pp_pupil
% function [cfg] = pspm_cfg_pp_pupil
%
% Matlabbatch menu for data preprocessing
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)

% $Id$
% $Rev$

%% Data preprocessing
cfg        = cfg_repeat;
cfg.name   = 'Pupil & Eye tracking';
cfg.tag    = 'pp_pupil';
cfg.values = {pspm_cfg_pupil_size_convert, ...
              pspm_cfg_pupil_preprocess, ...
              pspm_cfg_find_valid_fixations, ...
              pspm_cfg_pupil_correct, ...
              pspm_cfg_gaze_convert, ...
              pspm_cfg_gaze_pp, ...
              pspm_cfg_process_illuminance};
cfg.forcestruct = true;
cfg.help   = {'Help: Pupil & Eye tracking preprocessing'};
 