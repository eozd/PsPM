function glm_hp_e = pspm_cfg_glm_hp_e
% GLM

% Initialise
global settings
if isempty(settings), pspm_init; end;

% set variables

vars = struct();
vars.modality = 'HPR';
vars.modspec = 'hp_e';

% load default settings
glm_hp_e = pspm_cfg_glm(vars);

% set correct name
glm_hp_e.name = 'GLM for HP (evoked)';
glm_hp_e.tag = 'glm_hp_e';

% set callback function
glm_hp_e.prog = @pspm_cfg_run_glm_hp_e;

%% Basis function
% change basis function

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


% HPRF
n_bf         = cfg_entry;
n_bf.name    = 'Number of basis functions';
n_bf.tag     = 'n_bf';
n_bf.strtype = 'i';
n_bf.num     = [1 Inf];
n_bf.val     = {1:6};
n_bf.help    = {''};

hprf_e        = cfg_branch;
hprf_e.name   = 'HPRF_E';
hprf_e.tag    = 'hprf_e';
hprf_e.val    = {n_bf};
hprf_e.help   = {''};

% look for bf and replace
b = cellfun(@(f) strcmpi(f.tag, 'bf'), glm_hp_e.val);
glm_hp_e.val{b}.values = [{hprf_e}, glm_hp_e.val{b}.values];
glm_hp_e.val{b}.val = {hprf_e};
glm_hp_e.val{b}.help = {['Basis functions. Standard is to use a canonical evoked heart period response function ' ...
    '(HPRF_E) with time derivative for later reconstruction of the response peak.']};
