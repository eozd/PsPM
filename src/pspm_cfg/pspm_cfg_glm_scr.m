function glm_scr = pspm_cfg_glm_scr
% GLM

% $Id$
% $Rev$

% Initialise
global settings
if isempty(settings), pspm_init; end;

% set variables

vars = struct();
vars.modality = 'SCR';
vars.modspec = 'SCR';

% load default settings
glm_scr = pspm_cfg_glm(vars);

% set callback function
glm_scr.prog = @pspm_cfg_run_glm_scr;

% set correct name
glm_scr.name = 'GLM for SCR';
glm_scr.tag = 'glm_scr';

% BF
for i=1:3
    scrf{i}        = cfg_const;
    scrf{i}.name   = ['SCRF ' num2str(i-1)];
    scrf{i}.tag    = ['scrf' num2str(i-1)];
    scrf{i}.val    = {i-1};
end
scrf{1}.help   = {'SCRF without derivatives.'};
scrf{2}.help   = {'SCRF with time derivative (default).'};
scrf{3}.help   = {'SCRF with time and dispersion derivative.'};
b = cellfun(@(f) strcmpi(f.tag, 'bf'), glm_scr.val);
glm_scr.val{b}.values = [scrf, glm_scr.val{b}.values];
glm_scr.val{b}.val = {scrf{2}};
glm_scr.val{b}.help = {['Basis functions. Standard is to use a canonical skin conductance response function ' ...
    '(SCRF) with time derivative for later reconstruction of the response peak.']};



