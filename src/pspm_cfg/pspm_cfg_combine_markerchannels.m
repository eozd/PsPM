function combine_markerchannels = pspm_cfg_combine_markerchannels
% ● Description
%   function [combine_markerchannels] = pspm_cfg_combine_markerchannels(job)
%   Matlab UI function for pspm_combine_markerchannels
% ● History
%   PsPM 6.2
%   Written in 2023 by Teddy

%% Standard items
datafile         = pspm_cfg_selector_datafile;
marker_chan      = pspm_cfg_selector_channel('many');
channel_action   = pspm_cfg_selector_channel_action;

%% Specific items
marker_chan.help    = pspm_cfg_help_format('pspm_combine_markerchannels', 'options.marker_chan_num');

%% Executable branch
combine_markerchannels        = cfg_exbranch;
combine_markerchannels.name   = 'Combine marker channels';
combine_markerchannels.tag    = 'combine_markerchannels';
combine_markerchannels.val    = {datafile, channel_action, marker_chan};
combine_markerchannels.prog   = @pspm_cfg_run_combine_markerchannels;
combine_markerchannels.vout   = @pspm_cfg_vout_outchannel;
combine_markerchannels.help   = pspm_cfg_help_format('pspm_combine_markerchannels');




