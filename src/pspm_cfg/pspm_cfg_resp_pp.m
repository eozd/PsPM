function resp_pp = pspm_cfg_resp_pp
% Coversion of continuous respiration data various respiration data types


%% Standard items
datafile         = pspm_cfg_selector_datafile;
channel          = pspm_cfg_selector_channel('respiration');
channel_action   = pspm_cfg_selector_channel_action;

%% Specific items
sr         = cfg_entry;
sr.name    = 'Sample Rate';
sr.tag     = 'sr';
sr.strtype = 'r';
sr.num     = [1 1];
sr.val     = {10};
sr.help    = pspm_cfg_help_format('pspm_resp_pp', 'sr');

stype_bellows      = cfg_const;
stype_bellows.name = 'Bellows';
stype_bellows.tag  = 'bellows';
stype_bellows.val  = {'bellows'};
stype_bellows.help = {''};

stype_cushion      = cfg_const;
stype_cushion.name = 'Cushion';
stype_cushion.tag  = 'cushion';
stype_cushion.val  = {'cushion'};
stype_cushion.help = {''};

systemtype        = cfg_choice;
systemtype.name   = 'System type';
systemtype.tag    = 'systemtype';
systemtype.val    = {stype_bellows};
systemtype.values = {stype_bellows, stype_cushion};
systemtype.help   = pspm_cfg_help_format('pspm_resp_pp', 'options.systemtype');

dtype_rp        = cfg_menu;
dtype_rp.name   = 'Respiration period';
dtype_rp.tag    = 'rp';
dtype_rp.val    = {1};
dtype_rp.labels = {'No', 'Yes'};
dtype_rp.values = {0, 1};
dtype_rp.help   = {'Create a channel with interpolated respiration period.'};

dtype_ra        = cfg_menu;
dtype_ra.name   = 'Respiration amplitude';
dtype_ra.tag    = 'ra';
dtype_ra.val    = {1};
dtype_ra.labels = {'No', 'Yes'};
dtype_ra.values = {0, 1};
dtype_ra.help   = {'Create a channel with interpolated respiration amplitude.'};

dtype_rfr        = cfg_menu;
dtype_rfr.name   = 'Respiratory flow rate';
dtype_rfr.tag    = 'rfr';
dtype_rfr.val    = {1};
dtype_rfr.labels = {'No', 'Yes'};
dtype_rfr.values = {0, 1};
dtype_rfr.help   = {'Create a channel with interpolated respiratory flow rate.'};

dtype_rs        = cfg_menu;
dtype_rs.name   = 'Respiration time stamps';
dtype_rs.tag    = 'rs';
dtype_rs.val    = {1};
dtype_rs.labels = {'No', 'Yes'};
dtype_rs.values = {0, 1};
dtype_rs.help   = {'Create a channel with respiration time stamps.'};

datatype       = cfg_branch;
datatype.name  = 'Data type';
datatype.tag   = 'datatype';
datatype.val   = {dtype_rp, dtype_ra, dtype_rfr, dtype_rs};
datatype.help  = {''};

plot         = cfg_menu;
plot.name    = 'Diagnostic plot';
plot.tag     = 'plot';
plot.val     = {0};
plot.labels  = {'No', 'Yes'};
plot.values  = {0, 1};
plot.help    = pspm_cfg_help_format('pspm_resp_pp', 'options.plot');

options        = cfg_branch;
options.name   = 'Options';
options.tag    = 'options';
options.val    = {systemtype, datatype, plot};
options.help   = {['Choose for each possible process datatype either ', ...
'yes or no (default: yes)']};

% Executable Branch
resp_pp      = cfg_exbranch;
resp_pp.name = 'Respiration data conversion';
resp_pp.tag  = 'resp_pp';
resp_pp.val  = {datafile,sr,channel, channel_action ,options};
resp_pp.prog = @pspm_cfg_run_resp_pp;
resp_pp.vout = @pspm_cfg_vout_outchannel;
resp_pp.help = pspm_cfg_help_format('pspm_resp_pp');



