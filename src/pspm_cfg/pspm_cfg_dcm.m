function dcm = pspm_cfg_dcm
global settings
%% Standard items
datafile            = pspm_cfg_selector_datafile('PsPM');
chan                = pspm_cfg_selector_channel('SCR');
modelfile           = pspm_cfg_selector_outputfile('Model');
filter              = pspm_cfg_selector_filter(settings.dcm{1,1}.filter);
norm                = pspm_cfg_selector_norm;
epochfile           = pspm_cfg_selector_datafile('epochs');
rf_file             = pspm_cfg_selector_datafile('response function');

%% Specific items
% Parameter estimation
timingfile         = cfg_files;
timingfile.name    = 'Timing File';
timingfile.tag     = 'timingfile';
timingfile.num     = [1 1];
timingfile.filter  = '.*\.(mat|MAT)$';
timingfile.help    = {'See general DCM help for more information on how to specify timings'};


name         = cfg_entry;
name.name    = 'Name';
name.tag     = 'name';
name.strtype = 's';
name.val     = {''};
name.help    = {settings.help.pspm_dcm.Arguments.options.trlnames};

onsets         = cfg_entry;
onsets.name    = 'Onsets';
onsets.tag     = 'onsets';
onsets.strtype = 'r';
onsets.num     = [Inf Inf];
onsets.help    = {settings.help.pspm_dcm.Arguments.model.timing};

timing_man       = cfg_branch;
timing_man.name  = 'Event';
timing_man.tag   = 'timing_man';
timing_man.val   = {name, onsets};
timing_man.help  = {''};

timing_man_rep        = cfg_repeat;
timing_man_rep.name   = 'Enter Timing Manually (discouraged, will be removed in future releases)';
timing_man_rep.tag    = 'timing_man_rep';
timing_man_rep.values = {timing_man};
timing_man_rep.num   = [1 Inf];
timing_man_rep.help   = {'See general DCM help for more information on how to specify timings'};


timing        = cfg_choice;
timing.name   = 'Design';
timing.tag    = 'timing';
timing.values = {timingfile, timing_man_rep};
timing.help   = {};

% Condition name
condname         = cfg_entry;
condname.name    = 'Name';
condname.tag     = 'name';
condname.strtype = 's';
condname.help    = {'Specify the name of the condition.'};

% Condition index
condindex         = cfg_entry;
condindex.name    = 'Index';
condindex.tag     = 'index';
condindex.strtype = 'i';
condindex.num     = [1 Inf];
condindex.help    = {['Specify a vector of trial indices between 1 and n. The length of the vector ' ...
    'corresponds to the number of events included in this condition.']};

% Conditions
condition         = cfg_branch;
condition.name    = 'Condition';
condition.tag     = 'condition';
condition.val     = {condname, condindex};
condition.help    = {''};

condition_rep         = cfg_repeat;
condition_rep.name    = 'Condition names';
condition_rep.tag     = 'condition_rep';
condition_rep.values  = {condition};
condition_rep.num     = [0 Inf];
condition_rep.check   = @pspm_cfg_dcm_check_conditions;
condition_rep.help    = {settings.help.pspm_dcm.Arguments.options.trlnames};

% Missing epochs
no_epochs         = cfg_const;
no_epochs.name    = 'No Missing Epochs';
no_epochs.tag     = 'no_epochs';
no_epochs.val     = {0};
no_epochs.help    = {};


epochentry         = cfg_entry;
epochentry.name    = 'Enter Missing Epochs Manually (discouraged)';
epochentry.tag     = 'epochentry';
epochentry.strtype = 'i';
epochentry.num     = [Inf 2];
epochentry.help    = {settings.help.pspm_dcm.Arguments.model.missing};

epochs        = cfg_choice;
epochs.name   = 'Define Missing Epochs';
epochs.tag    = 'epochs';
epochs.values = {epochfile, epochentry};
epochs.help   = {};

missing        = cfg_choice;
missing.name   = 'Missing Epochs';
missing.tag    = 'missing';
missing.val    = {no_epochs};
missing.values = {no_epochs, epochs};
missing.help   = pspm_cfg_help_format('pspm_dcm', 'model.missing');

% Sessions
session        = cfg_branch;
session.name   = 'Session';
session.tag    = 'session';
session.val    = {datafile, timing, condition_rep, missing};
session.help   = {''};

session_rep         = cfg_repeat;
session_rep.name    = 'Data & design';
session_rep.tag     = 'session_rep';
session_rep.values  = {session};
session_rep.num     = [1 Inf];
session_rep.help    = {'Add the number of sessions here.'};


%% Data options
substhresh          = cfg_entry;
substhresh.name     = 'Subsession threshold';
substhresh.tag      = 'substhresh';
substhresh.val      = {2};
substhresh.strtype  = 'r';
substhresh.num      = [1 1];
substhresh.help     = pspm_cfg_help_format('pspm_dcm', 'model.substhresh');

lasttrialfiltering      = cfg_entry;
lasttrialfiltering.name = 'Last trial cutoff';
lasttrialfiltering.tag  = 'lasttrialcutoff';
lasttrialfiltering.val  = {7};
lasttrialfiltering.strtype  = 'r';
lasttrialfiltering.num      = [1 1];
lasttrialfiltering.help = pspm_cfg_help_format('pspm_dcm', 'model.lasttrialcutoff');
% constrained model
constrained_model       = cfg_entry;
constrained_model.name  ='Constrained model';
constrained_model.tag   ='constr_model';
constrained_model.val   = {0};
constrained_model.strtype = 'i';
constrained_model.num   = [1 1];
constrained_model.help = pspm_cfg_help_format('pspm_dcm', 'model.constrained');


data_options         = cfg_branch;
data_options.name    = 'Data Options';
data_options.tag     = 'data_options';
data_options.val     = {norm, filter, substhresh, lasttrialfiltering, constrained_model};
data_options.help    = {''};


%% Response function options
% CRF update
crfupdate         = cfg_menu;
crfupdate.name    = 'CRF Update';
crfupdate.tag     = 'crfupdate';
crfupdate.labels  = {'Use pre-estimated parameters', 'Update CRF parameters to observed canonical SCRF'};
crfupdate.val     = {0};
crfupdate.values  = {0,1};
crfupdate.help    = pspm_cfg_help_format('pspm_dcm', 'options.crfupdate');
crfupdate.hidden = true;

% Estimate the response function from the data
indrf         = cfg_menu;
indrf.name    = 'Estimate the Response Function from The Data';
indrf.tag     = 'indrf';
indrf.labels  = {'No', 'Yes'};
indrf.val     = {0};
indrf.values  = {0,1};
indrf.help    = pspm_cfg_help_format('pspm_dcm', 'options.indrf');

% Only estimate RF
getrf         = cfg_menu;
getrf.name    = 'Only Estimate RF (Do Not Do Trial-Wise DCM)';
getrf.tag     = 'getrf';
getrf.labels  = {'No', 'Yes'};
getrf.val     = {0};
getrf.values  = {0,1};
getrf.help    = pspm_cfg_help_format('pspm_dcm', 'options.getrf');

% Call External File to Provide Response Function
rf_disabled         = cfg_const;
rf_disabled.name    = 'RF disabled';
rf_disabled.tag     = 'disabled';
rf_disabled.val     = {0};
rf_disabled.help   = {};

rf         = cfg_choice;
rf.name    = 'Use External File to Provide Response Function';
rf.tag     = 'rf';
rf.val     = {rf_disabled};
rf.values  = {rf_disabled,rf_file};
rf.help    = pspm_cfg_help_format('pspm_dcm', 'options.rf');

resp_options         = cfg_branch;
resp_options.name    = 'Response Function Options';
resp_options.tag     = 'resp_options';
resp_options.val     = {crfupdate, indrf, getrf, rf};
resp_options.help    = {''};


%% Inversion options
% No of trials to invert at the same time
depth         = cfg_entry;
depth.name    = 'Number of Trials to Invert at The Same Time';
depth.tag     = 'depth';
depth.strtype = 'i';
depth.num     = [1 1];
depth.val     = {2};
depth.help    = pspm_cfg_help_format('pspm_dcm', 'options.depth');


% SF-free window before first event
sfpre         = cfg_entry;
sfpre.name    = 'SF-Free Window Before First Event [s]';
sfpre.tag     = 'sfpre';
sfpre.strtype = 'r';
sfpre.num     = [1 1];
sfpre.val     = {2};
sfpre.help    = pspm_cfg_help_format('pspm_dcm', 'options.sfpre');


% SF-free window after last event
sfpost         = cfg_entry;
sfpost.name    = 'SF-Free Window After Last Event [s]';
sfpost.tag     = 'sfpost';
sfpost.strtype = 'r';
sfpost.num     = [1 1];
sfpost.val     = {5};
sfpost.help    = pspm_cfg_help_format('pspm_dcm', 'options.sfpost');


% Maximum frequency of SF in ITIs
sffreq         = cfg_entry;
sffreq.name    = 'Maximum Frequency of SF in ITIs [Hz]';
sffreq.tag     = 'sffreq';
sffreq.strtype = 'r';
sffreq.num     = [1 1];
sffreq.val     = {0.5};
sffreq.help    = pspm_cfg_help_format('pspm_dcm', 'options.sffreq');


% SCL-change-free window before first event
sclpre         = cfg_entry;
sclpre.name    = 'SCL-Change-Free Window Before First Event [s]';
sclpre.tag     = 'sclpre';
sclpre.strtype = 'r';
sclpre.num     = [1 1];
sclpre.val     = {2};
sclpre.help    = pspm_cfg_help_format('pspm_dcm', 'options.sclpre');

% SCL-change-free window after last event
sclpost         = cfg_entry;
sclpost.name    = 'SCL-Change-Free Window After Last Event [s]';
sclpost.tag     = 'sclpost';
sclpost.strtype = 'r';
sclpost.num     = [1 1];
sclpost.val     = {5};
sclpost.help    = pspm_cfg_help_format('pspm_dcm', 'options.sclpost');

% minimum dispersion (standard deviation) for flexible responses
ascr_sigma_offset         = cfg_entry;
ascr_sigma_offset.name    = 'Minimum Dispersion (Standard Deviation) for Flexible Responses [s]';
ascr_sigma_offset.tag     = 'ascr_sigma_offset';
ascr_sigma_offset.strtype = 'r';
ascr_sigma_offset.num     = [1 1];
ascr_sigma_offset.val     = {0.1};
ascr_sigma_offset.help    = pspm_cfg_help_format('pspm_dcm', 'options.aSCR_sigma_offset');
ascr_sigma_offset.hidden = true;

inv_options         = cfg_branch;
inv_options.name    = 'Inversion Options';
inv_options.tag     = 'inv_options';
inv_options.val     = {depth, sfpre, sfpost, sffreq, sclpre, sclpost, ascr_sigma_offset};
inv_options.help    = {''};


%% Display options

% Display proress window
dispwin         = cfg_menu;
dispwin.name    = 'Display Progress Window';
dispwin.tag     = 'dispwin';
dispwin.labels  = {'Yes', 'No'};
dispwin.val     = {1};
dispwin.values  = {1,0};
dispwin.help    = pspm_cfg_help_format('pspm_dcm', 'options.dispwin');


% Display intermediate windows
dispsmallwin         = cfg_menu;
dispsmallwin.name    = 'Display Intermediate Windows';
dispsmallwin.tag     = 'dispsmallwin';
dispsmallwin.labels  = {'No', 'Yes'};
dispsmallwin.val     = {0};
dispsmallwin.values  = {0,1};
dispsmallwin.help    = pspm_cfg_help_format('pspm_dcm', 'options.dispsmallwin');

disp_options         = cfg_branch;
disp_options.name    = 'Display Options';
disp_options.tag     = 'disp_options';
disp_options.val     = {dispwin, dispsmallwin};
disp_options.help    = {''};


%% Executable branch
dcm      = cfg_exbranch;
dcm.name = 'Non-Linear Model';
dcm.tag  = 'dcm';
dcm.val  = {modelfile, chan, session_rep, data_options, resp_options, inv_options, disp_options};
dcm.prog = @pspm_cfg_run_dcm;
dcm.vout = @pspm_cfg_vout_outfile;
dcm.help = pspm_cfg_help_format('pspm_dcm');


function [sts, val] = pspm_cfg_dcm_check_conditions(val)
sts = [];
nrCond = size(val,2);
testVec = [];
for iCond=1:nrCond
    indexLength = length(val(1,iCond).index);
    testVec(end+1:end+indexLength) = val(1,iCond).index;
end
if length(testVec) ~= length(unique(testVec))
    sts = sprintf('At least one index is used more than once.\nPlease use each index only once.');
end
if ~isempty(sts) uiwait(msgbox(sts,'Index Error')); end
