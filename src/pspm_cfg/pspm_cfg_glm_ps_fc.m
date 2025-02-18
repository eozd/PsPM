function [glm_ps_fc] = pspm_cfg_glm_ps_fc
% GLM PS FC

% $Id$
% $Rev$

% Initialise
global settings
if isempty(settings), pspm_init; end

% set variables

vars = struct();
vars.modality = 'pupil';
vars.modspec = 'ps_fc';

% load default settings
glm_ps_fc = pspm_cfg_glm(vars);

% set correct name
glm_ps_fc.name = 'GLM for PS (fear-conditioning)';
glm_ps_fc.tag = 'glm_ps_fc';

% set callback function
glm_ps_fc.prog = @pspm_cfg_run_glm_ps_fc;

%% Basis function
% PSRF
psrf_fc = cell(1, 5);
for i=1:4
    psrf_fc{i}        = cfg_const;
    psrf_fc{i}.name   = ['PSRF_FC ' num2str(i-1)];
    psrf_fc{i}.tag    = ['psrf_fc' num2str(i-1)];
    psrf_fc{i}.val    = {i-1};
end
psrf_fc{1}.help   = {'PSRF_FC: CS-evoked response only and without derivatives (default).'};
psrf_fc{2}.help   = {'PSRF_FC: CS-evoked response and time derivative.'};
psrf_fc{3}.help    = {['PSRF_FC: CS- and US-evoked response (3.5 s SOA) without derivatives. ', ... 
    'For other SOAs, specify the basis function outside the GUI.']};
psrf_fc{4}.help    = {['PSRF_FC: US-evoked response only (3.5 s SOA) and without derivatives. ', ...
    'For other SOAs, specify the basis function outside the GUI. Specify CS onset rather than US onset in your timings.']};

% add erlang response function
psrf_fc{5} = cfg_const;
psrf_fc{5}.name = 'PSRF_ERL';
psrf_fc{5}.tag = 'psrf_erl';
psrf_fc{5}.val = {4};
psrf_fc{5}.help = {['PSRF_ERL use a Erlang response funcation according to', ...
    'Hoeks, B., & Levelt, W.J.M. (1993). Pupillary Dilation as a Measure ', ...
    'of Attention - a Quantitative System-Analysis. Behavior Research ', ...
    'Methods Instruments & Computers, 25, 16-26.']};

bf        = cfg_choice;
bf.name   = 'Basis Function';
bf.tag    = 'bf';
bf.val    = {psrf_fc{1}};
bf.values = {psrf_fc{:}};
bf.help   = {['Basis functions. Standard is to use a canonical pupil size response function ' ...
    'for fear conditioning (PSRF_FC) without time derivative. ', ...
    'For help on the options, click on the basis function in the window above. NOTE: These basis functions were developed with pupil size data ', ...
    'recorded in diameter values. Therefore pupil size data analyzed ', ...
    'using these models should also be in diameter.']};

% look for bf and replace
b = cellfun(@(f) strcmpi(f.tag, 'bf'), glm_ps_fc.val);
glm_ps_fc.val{b} = bf;

