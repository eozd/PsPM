function [prod_illu] = pspm_cfg_process_illuminance(~)
% ● Description
%   GUI script for "prepare illuminance GLM".
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Updated in 2024 by Teddy

%% Standard items
output                 = pspm_cfg_selector_outputfile('Nuisance regressors');

%% Select file
lum_file        = cfg_files;
lum_file.name   = 'Illuminance file';
lum_file.filter  = '.*\.(mat|MAT)$';
lum_file.tag    = 'lum_file';
lum_file.num    = [1 1];
lum_file.help   = pspm_cfg_help_format('pspm_process_illuminance', 'ldata');
%% Sample rate
sr              = cfg_entry;
sr.name         = 'Sample rate';
sr.tag          = 'sr';
sr.strtype      = 'i';
sr.num          = [1 1];
sr.help         = pspm_cfg_help_format('pspm_process_illuminance', 'sr');
%% LDRF_GM
ldrf_gm         = cfg_const;
ldrf_gm.name    = 'pspm_bf_ldrf_gm';
ldrf_gm.tag     = 'ldrf_gm';
ldrf_gm.val     = {true};
ldrf_gm.help    = {'Gamma probability density function.'};
%% LDRF_GU
ldrf_gu         = cfg_const;
ldrf_gu.name    = 'pspm_bf_ldrf_gu';
ldrf_gu.tag     = 'ldrf_gu';
ldrf_gu.val     = {true};
ldrf_gu.help    = {'Smoothed Gaussian.'};
%% Dilation
dilation        = cfg_choice;
dilation.name   = 'Dilation';
dilation.tag    = 'dilation';
dilation.values = {ldrf_gm, ldrf_gu};
dilation.val    = {ldrf_gm};
dilation.help   = pspm_cfg_help_format('pspm_process_illuminance', 'options.bf.dilation');
%% LCRF_GM
lcrf_gm         = cfg_const;
lcrf_gm.name    = 'pspm_bf_lcrf_gm';
lcrf_gm.tag     = 'lcrf_gm';
lcrf_gm.val     = {true};
lcrf_gm.help    = {};
%% Constriction
constrict       = cfg_choice;
constrict.name  = 'Constriction';
constrict.tag   = 'constriction';
constrict.val   = {lcrf_gm};
constrict.values= {lcrf_gm};
constrict.help  = pspm_cfg_help_format('pspm_process_illuminance', 'options.bf.constriction');
%% Basis function options
bf              = cfg_branch;
bf.name         = 'Basis function options';
bf.tag          = 'bf';
bf.val          = {dilation, constrict};
bf.help         = {'Specify options for the basis functions.'};

%% Executable branch
prod_illu       = cfg_exbranch;
prod_illu.name  = 'Prepare illuminance GLM';
prod_illu.tag   = 'process_illuminance';
prod_illu.val   = {lum_file, sr, bf, output};
prod_illu.prog  = @pspm_cfg_run_proc_illuminance;
prod_illu.vout  = @pspm_cfg_vout_outfile;
prod_illu.help  = pspm_cfg_help_format('pspm_process_illuminance');
