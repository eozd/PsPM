function [cfg] = pspm_cfg_data_preprocessing
% function [cfg] = pspm_cfg_data_preprocessing
%
% Matlabbatch menu for data preprocessing
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)

%% Data preprocessing
cfg        = cfg_repeat;
cfg.name   = 'Data Preprocessing';
cfg.tag    = 'data_preprocessing';
cfg.values = {pspm_cfg_scr_pp,...
    pspm_cfg_pp_pupil, ...
    pspm_cfg_pp_cardiac, ...
    pspm_cfg_resp_pp, ...    
    pspm_cfg_pp_emg, ...
    pspm_cfg_combine_markerchannels, ...
    pspm_cfg_pp_general};
cfg.forcestruct = true;
cfg.help   = {'Help: Data preprocessing'};
