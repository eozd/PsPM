function sf = pspm_cfg_sf

%% Initialise
global settings

%% Standard items
datafile            = pspm_cfg_selector_datafile;
channel             = pspm_cfg_selector_channel('SCR');
output              = pspm_cfg_selector_outputfile('Model');
filter              = pspm_cfg_selector_filter(settings.dcm{2});
epochfile           = pspm_cfg_selector_datafile('epochs');
missing             = pspm_cfg_selector_missing_epochs(); 

% (see below for timeunits, requires specification of epochs item first)

%% Specific items
%% Method
method         = cfg_menu;
method.name    = 'Method';
method.tag     = 'method';
method.labels  = {'AUC', 'SCL', 'DCM', 'MP', 'all'};
method.values  = {'auc', 'scl', 'dcm', 'mp', 'all'};
method.help    = {};


%% Epochs
epochentry         = cfg_entry;
epochentry.name    = 'Enter Epochs Manually';
epochentry.tag     = 'epochentry';
epochentry.strtype = 'r';
epochentry.num     = [Inf 2];
epochentry.help    = {''};

epochs        = cfg_choice;
epochs.name   = 'Epochs';
epochs.tag    = 'epochs';
epochs.values = {epochfile, epochentry};
epochs.help   = {''};

timeunits           = pspm_cfg_selector_timeunits('sf', epochs);

%% Additional options for individual methods (hidden in GUI)
threshold         = cfg_entry;
threshold.name    = 'Threshold';
threshold.tag     = 'threshold';
threshold.strtype = 'r';
threshold.val     = {0.1};
threshold.help    = pspm_cfg_help_format('pspm_sf', 'options.threshold');

theta         = cfg_entry;
theta.name    = 'Theta';
theta.tag     = 'theta';
theta.strtype = 'r';
theta.val     = {[]};
theta.help    = pspm_cfg_help_format('pspm_sf', 'options.theta');
theta.hidden  = true;

fresp         = cfg_entry;
fresp.name    = 'Response frequency';
fresp.tag     = 'fresp';
fresp.strtype = 'r';
fresp.val     = {[]};
fresp.help    = pspm_cfg_help_format('pspm_sf', 'options.fresp');

fresp.hidden  = true;

% Show figures
dispwin         = cfg_menu;
dispwin.name    = 'Display Progress Window';
dispwin.tag     = 'dispwin';
dispwin.labels  = {'Yes', 'No'};
dispwin.val     = {1};
dispwin.values  = {1,0};
dispwin.help    = pspm_cfg_help_format('pspm_sf', 'options.dispwin');

dispsmallwin         = cfg_menu;
dispsmallwin.name    = 'Display Intermediate Windows';
dispsmallwin.tag     = 'dispsmallwin';
dispsmallwin.labels  = {'No', 'Yes'};
dispsmallwin.val     = {0};
dispsmallwin.values  = {0,1};
dispsmallwin.help    = pspm_cfg_help_format('pspm_sf', 'options.dispsmallwin');

%% Executable branch
sf      = cfg_exbranch;
sf.name = 'SF';
sf.tag  = 'sf';
sf.val  = {datafile, output, method, timeunits, filter, channel, threshold, missing, theta, fresp, dispwin, dispsmallwin};
sf.prog = @pspm_cfg_run_sf;
sf.vout = @pspm_cfg_vout_outfile;
sf.help = pspm_cfg_help_format('pspm_sf');