function [glm] = pspm_cfg_glm(vars)
% function [glm] = pspm_cfg_glm(vars)
%
% Matlabbatch function specifies the basic glm_module.
% Its called by pspm_cfg_glm_<modalities> where modality specific settings
% are set. Then the struct is passed on to the next higher level of the
% matlabbatch configuration set.
%
% vars is a struct with char fields:
%   - modality
%   - modspec
%__________________________________________________________________________
% PsPM 3.0
% (C) 2015 Tobias Moser (University of Zurich)

global settings


%% Standard items
output                   = pspm_cfg_selector_outputfile('Model');
session_rep              = pspm_cfg_selector_data_design('glm', vars);
timeunits                = pspm_cfg_selector_timeunits;
chan                     = pspm_cfg_selector_channel(vars.modality);
modelspec                = strcmpi({settings.glm.modelspec}, vars.modspec);
filter                   = pspm_cfg_selector_filter(settings.glm(modelspec).filter);
normalise                = pspm_cfg_selector_norm;

%settings if Create Stats Exclude = yes
excl_segment_length         = cfg_entry;
excl_segment_length.name    = 'Segment length';
excl_segment_length.tag     = 'segment_length';
excl_segment_length.strtype = 'i';
excl_segment_length.num     = [1 1];
excl_segment_length.help    = {};

excl_cutoff         = cfg_entry;
excl_cutoff.name    = 'Cutoff';
excl_cutoff.tag     = 'cutoff';
excl_cutoff.strtype = 'r';
excl_cutoff.num     = [1 1];
excl_cutoff.help    = {};

exclude_missing_yes      = cfg_branch;
exclude_missing_yes.name = 'Settings for stats exclude';
exclude_missing_yes.tag  = 'exclude_missing_yes';
exclude_missing_yes.val  = {excl_segment_length,excl_cutoff};
exclude_missing_yes.help = {};

%settings if Create Stats Exclude = no
excl_no                  = cfg_const;
excl_no.name             = 'No';
excl_no.tag              = 'excl_no';
excl_no.val              = {'No'};
excl_no.help             = {'No statistics created.'};

%Create Stats Exclude
exclude_missing          = cfg_choice;
exclude_missing.name     = 'Create information on missing data values';
exclude_missing.tag      = 'exclude_missing';
exclude_missing.val      = {excl_no};
exclude_missing.values   = {excl_no, exclude_missing_yes};
exclude_missing.help     = pspm_cfg_help_format('pspm_glm', 'options.exclude_missing');



%% Modality dependent items
% Basis function

%FIR
n         = cfg_entry;
n.name    = 'N: Number of Time Bins';
n.tag     = 'n';
n.strtype = 'i';
n.num     = [1 1];
n.help    = {'Number of time bins.'};

d         = cfg_entry;
d.name    = 'D: Duration of Time Bins';
d.tag     = 'd';
d.strtype = 'r';
d.num     = [1 1];
d.help    = {'Duration of time bins (in seconds).'};

arg        = cfg_branch;
arg.name   = 'Arguments';
arg.tag    = 'arg';
arg.val    = {n, d};
arg.help   = {''};

fir        = cfg_branch;
fir.name   = 'FIR';
fir.tag    = 'fir';
fir.val    = {arg};
fir.help   = {'Uninformed finite impulse response (FIR) model: specify the number and duration of time bins to be estimated.'};

bf        = cfg_choice;
bf.name   = 'Basis Function';
bf.tag    = 'bf';
bf.val    = {fir};
bf.values = {fir};
bf.help   = {};

%% Latency
time_window          = cfg_entry;
time_window.name     = 'Time window';
time_window.tag      = 'time_window';
time_window.strtype  = 'r';
time_window.num      = [1 2];
time_window.help     = pspm_cfg_help_format('pspm_glm', 'model.window');

fixed_latency   = cfg_const;
fixed_latency.name = 'Fixed latency';
fixed_latency.tag = 'fixed';
fixed_latency.val = {'fixed'};
fixed_latency.help = {['']};

free_latency    = cfg_branch;
free_latency.name = 'Free latency';
free_latency.tag = 'free';
free_latency.val = {time_window};
free_latency.help = {['']};

latency         = cfg_choice;
latency.name    = 'Latency';
latency.tag     = 'latency';
latency.val     = {fixed_latency};
latency.values  = {fixed_latency, free_latency};
% is hidden per default
latency.hidden  = true;
latency.help    = pspm_cfg_help_format('pspm_glm', 'model.latency');

%% Executable Branch
glm       = cfg_exbranch;
glm.name  = 'GLM';
glm.tag   = 'glm';
glm.val   = {output, chan, timeunits, session_rep, latency, ...
    bf, normalise, filter, exclude_missing};

%glm_scr.prog  = ;
glm.vout  = @pspm_cfg_vout_outfile;
glm.help  = pspm_cfg_help_format('pspm_glm');

