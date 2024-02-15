%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 380 $)
%-----------------------------------------------------------------------
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.type = 'cfg_entry';
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.name = 'Output Filename';
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.tag = 'name';
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.strtype = 's';
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.extras = [];
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.num = [1 Inf];
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.check = [];
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.help = {'Output filename without any directory names.'};
matlabbatch{1}.menu_cfg{1}.menu_entry{1}.conf_entry.def = [];
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.type = 'cfg_files';
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.name = 'Output Directory';
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.tag = 'outdir';
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.filter = 'dir';
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.ufilter = '.*';
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.dir = '';
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.num = [1 1];
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.check = [];
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.help = {'Directory where the file will be saved. Any directory components in the output filename will be stripped off and only this directory determines the path to the file.'};
matlabbatch{2}.menu_cfg{1}.menu_entry{1}.conf_files.def = [];
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.type = 'cfg_entry';
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.name = 'Variable Name';
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.tag = 'vname';
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.strtype = 's';
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.extras = [];
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.num = [1 Inf];
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.check = @cfg_check_assignin;
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.help = {'Name for the variable in output file/struct. This must be a valid MATLAB variable name.'};
matlabbatch{3}.menu_cfg{1}.menu_entry{1}.conf_entry.def = [];
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.type = 'cfg_entry';
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.name = 'Variable Contents';
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.tag = 'vcont';
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.strtype = 'e';
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.extras = [];
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.num = [];
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.check = [];
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.help = {'Contents to be saved. This can be any MATLAB variable or an output from another module, passed as dependency.'};
matlabbatch{4}.menu_cfg{1}.menu_entry{1}.conf_entry.def = [];
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.type = 'cfg_branch';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.name = 'Variable';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.tag = 'vars';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{1}(1) = cfg_dep;
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{1}(1).tname = 'Val Item';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{1}(1).tgt_spec = {};
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{1}(1).sname = 'Variable Name (cfg_entry)';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{1}(1).src_exbranch = substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{1}(1).src_output = substruct('()',{1});
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{2}(1) = cfg_dep;
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{2}(1).tname = 'Val Item';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{2}(1).tgt_spec = {};
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{2}(1).sname = 'Variable Contents (cfg_entry)';
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{2}(1).src_exbranch = substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.val{2}(1).src_output = substruct('()',{1});
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.check = [];
matlabbatch{5}.menu_cfg{1}.menu_struct{1}.conf_branch.help = {'For each variable, a name and its contents has to be specified.'};
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.type = 'cfg_repeat';
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.name = 'Variables';
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.tag = 'vars';
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.values{1}(1) = cfg_dep;
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.values{1}(1).tname = 'Values Item';
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.values{1}(1).tgt_spec = {};
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.values{1}(1).sname = 'Variable (cfg_branch)';
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.values{1}(1).src_exbranch = substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.values{1}(1).src_output = substruct('()',{1});
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.num = [1 Inf];
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.forcestruct = false;
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.check = [];
matlabbatch{6}.menu_cfg{1}.menu_struct{1}.conf_repeat.help = {'Any number of variables can be saved in this file together.'};
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.type = 'cfg_menu';
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.name = 'Save as';
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.tag = 'saveasstruct';
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.labels = {
                                                             'Individual Variables'
                                                             'Struct Variable'
                                                             }';
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.values = {
                                                             false
                                                             true
                                                             }';
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.check = [];
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.help = {'Variables can be saved into the file individually or as a single struct variable, with the names of the variables used as fieldnames.'};
matlabbatch{7}.menu_cfg{1}.menu_entry{1}.conf_menu.def = [];
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.type = 'cfg_exbranch';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.name = 'Save Variables';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.tag = 'cfg_save_vars';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{1}(1) = cfg_dep;
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{1}(1).tname = 'Val Item';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{1}(1).tgt_spec = {};
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{1}(1).sname = 'Output Filename (cfg_entry)';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{1}(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{1}(1).src_output = substruct('()',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{2}(1) = cfg_dep;
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{2}(1).tname = 'Val Item';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{2}(1).tgt_spec = {};
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{2}(1).sname = 'Output Directory (cfg_files)';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{2}(1).src_exbranch = substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{2}(1).src_output = substruct('()',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{3}(1) = cfg_dep;
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{3}(1).tname = 'Val Item';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{3}(1).tgt_spec = {};
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{3}(1).sname = 'Variables (cfg_repeat)';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{3}(1).src_exbranch = substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{3}(1).src_output = substruct('()',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{4}(1) = cfg_dep;
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{4}(1).tname = 'Val Item';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{4}(1).tgt_spec = {};
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{4}(1).sname = 'Save as (cfg_menu)';
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{4}(1).src_exbranch = substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.val{4}(1).src_output = substruct('()',{1});
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.prog = @cfg_run_save_vars;
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.vout = @cfg_vout_save_vars;
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.check = [];
matlabbatch{8}.menu_cfg{1}.menu_struct{1}.conf_exbranch.help = {'Save a collection of variables to a .mat file.'};
