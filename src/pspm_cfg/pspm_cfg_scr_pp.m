function [pp_scr] = pspm_cfg_scr_pp
% function for pre processing (PP) skin conductance response (SCR)

%% Standard items
datafile               = pspm_cfg_selector_datafile;
chan                   = pspm_cfg_selector_channel('SCR');
channel_action         = pspm_cfg_selector_channel_action;
missing_epochs_file    = pspm_cfg_selector_outputfile('Missing epochs');

%% simple SCR quality correction
scr_min          = cfg_entry;
scr_min.name     = 'Minimum value';
scr_min.tag      = 'min';
scr_min.strtype  = 'r';
scr_min.num      = [1 1];
scr_min.val      = {0.05};
scr_min.help     = pspm_cfg_help_format('pspm_scr_pp', 'options.min');

scr_max          = cfg_entry;
scr_max.name     = 'Maximum value';
scr_max.tag      = 'max';
scr_max.strtype  = 'r';
scr_max.num      = [1 1];
scr_max.val      = {60};
scr_max.help     = pspm_cfg_help_format('pspm_scr_pp', 'options.max');

scr_slope          = cfg_entry;
scr_slope.name     = 'Maximum slope';
scr_slope.tag      = 'slope';
scr_slope.strtype  = 'r';
scr_slope.num      = [1 1];
scr_slope.val      = {10};
scr_slope.help     = pspm_cfg_help_format('pspm_scr_pp', 'options.slope');

% Options
scr_deflection_threshold         = cfg_entry;
scr_deflection_threshold.name    = 'Deflection threshold';
scr_deflection_threshold.tag     = 'deflection_threshold';
scr_deflection_threshold.strtype = 'r';
scr_deflection_threshold.num     = [1 1];
scr_deflection_threshold.val     = {0.1};
scr_deflection_threshold.help    = pspm_cfg_help_format('pspm_scr_pp', 'options.deflection_threshold');

scr_data_island_threshold         = cfg_entry;
scr_data_island_threshold.name    = 'Data island threshold';
scr_data_island_threshold.tag     = 'data_island_threshold';
scr_data_island_threshold.strtype = 'r';
scr_data_island_threshold.num     = [1 1];
scr_data_island_threshold.val     = {0};
scr_data_island_threshold.help    = pspm_cfg_help_format('pspm_scr_pp', 'options.data_island_threshold');

scr_expand_epochs         = cfg_entry;
scr_expand_epochs.name    = 'Expand epochs';
scr_expand_epochs.tag     = 'expand_epochs';
scr_expand_epochs.strtype = 'r';
scr_expand_epochs.num     = [1 1];
scr_expand_epochs.val     = {0.5};
scr_expand_epochs.help    = pspm_cfg_help_format('pspm_scr_pp', 'options.expand_epochs');

% Step size for clipping detection
clipping_step_size                   = cfg_entry;
clipping_step_size.name              = 'Step size for clipping detection';
clipping_step_size.tag               = 'clipping_step_size';
clipping_step_size.strtype           = 'r';
clipping_step_size.num               = [1 1];
clipping_step_size.val               = {2};
clipping_step_size.help              = pspm_cfg_help_format('pspm_scr_pp', 'options.clipping_step_size');

% Threshold for clipping detection
clipping_threshold                   = cfg_entry;
clipping_threshold.name              = 'Threshold for clipping detection';
clipping_threshold.tag               = 'clipping_threshold';
clipping_threshold.strtype           = 'r';
clipping_threshold.num               = [1 1];
clipping_threshold.val               = {0.1};
clipping_threshold.help              = pspm_cfg_help_format('pspm_scr_pp', 'options.clipping_threshold');

clipping_detection         = cfg_exbranch;
clipping_detection.name    = 'Clipping detection';
clipping_detection.tag     = 'clipping_detection';
clipping_detection.val     = {clipping_step_size, clipping_threshold};
clipping_detection.help    = {'Specify parameters for clipping detection.'};

% Output
output         = cfg_choice;
output.name    = 'Output';
output.tag     = 'outputtype';
output.val     = {missing_epochs_file};
output.values  = {channel_action, missing_epochs_file};
output.help    = pspm_cfg_help_format('pspm_scr_pp', 'options.missing_epochs_filename');

% Option
options             = cfg_branch;
options.name        = 'Options';
options.tag         = 'options';
options.val         = {scr_min, ...
                        scr_max, ...
                        scr_slope, ...
                        scr_deflection_threshold, ...
                        scr_data_island_threshold, ...
                        scr_expand_epochs, ...
                        clipping_detection};
options.help        = {};

% Executable Branch
pp_scr              = cfg_exbranch;
pp_scr.name         = 'SCR preprocessing';
pp_scr.tag          = 'pp_scr';
pp_scr.val          = {datafile, ...
                        chan, ...
                        output,...
                        options};
pp_scr.prog         = @pspm_cfg_run_scr_pp;
pp_scr.vout         = @pspm_cfg_vout_pp_scr;
pp_scr.help         = pspm_cfg_help_format('pspm_scr_pp');
end

function vout = pspm_cfg_vout_pp_scr(job)
if isfield(job.outputtype, 'channel_action')
    vout = pspm_cfg_vout_outchannel(job);
else
    vout = pspm_cfg_vout_outfile(job);
end

end
