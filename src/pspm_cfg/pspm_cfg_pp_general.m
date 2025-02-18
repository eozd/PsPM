function [cfg] = pspm_cfg_pp_general
% function [cfg] = pspm_cfg_data_preprocessing
%
% Matlabbatch menu for data preprocessing
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)

%% Data preprocessing
cfg        = cfg_repeat;
cfg.name   = 'General Preprocessing';
cfg.tag    = 'general_preprocessing';
cfg.values = {pspm_cfg_filtering, ...
              pspm_cfg_interpolate};
cfg.forcestruct = true;
cfg.help   = {'Help: Data preprocessing'};
