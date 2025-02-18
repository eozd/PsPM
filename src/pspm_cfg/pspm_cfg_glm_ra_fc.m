function [glm_ra_fc] = pspm_cfg_glm_ra_fc
% GLM RA FC

% $Id$
% $Rev$

% Initialise
global settings
if isempty(settings), pspm_init; end;

% set variables

vars = struct();
vars.modality = 'RAR';
vars.modspec = 'ra_fc';

% load default settings
glm_ra_fc = pspm_cfg_glm(vars);

% set correct name
glm_ra_fc.name = 'GLM for RA (fear-conditioning)';
glm_ra_fc.tag = 'glm_ra_fc';

% set callback function
glm_ra_fc.prog = @pspm_cfg_run_glm_ra_fc;

%% Basis function
% PSRF
rarf_fc = cell(1, 2);
for i=1:2
    rarf_fc{i}        = cfg_const;
    rarf_fc{i}.name   = ['RARF_FC ' num2str(i-1)];
    rarf_fc{i}.tag    = ['rarf_fc' num2str(i-1)];
    rarf_fc{i}.val    = {i};
end
rarf_fc{1}.help   = {'RARF_FC early and late response (default).'};
rarf_fc{2}.help   = {'RARF_FC early response with derivative (recommended for longer SOAs).'};


bf        = cfg_choice;
bf.name   = 'Basis Function';
bf.tag    = 'bf';
bf.val    = {rarf_fc{1}};
bf.values = {rarf_fc{:}};
bf.help   = {['Basis functions. Standard is to use a canonical respiration amplitude response function ' ...
    ' for fear conditioning (RARF_FC) with early and late response for later reconstruction.']};

% look for bf and replace
b = cellfun(@(f) strcmpi(f.tag, 'bf'), glm_ra_fc.val);
glm_ra_fc.val{b} = bf;
