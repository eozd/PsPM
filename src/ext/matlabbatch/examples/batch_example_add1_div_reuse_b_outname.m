%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 380 $)
%-----------------------------------------------------------------------
matlabbatch{1}.cfg_basicio.cfg_named_input.name = 'a';
matlabbatch{1}.cfg_basicio.cfg_named_input.input = '<UNDEFINED>';
matlabbatch{2}.cfg_basicio.cfg_named_input.name = 'b';
matlabbatch{2}.cfg_basicio.cfg_named_input.input = '<UNDEFINED>';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1) = cfg_dep;
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1).tname = 'Input a';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1).tgt_spec{1}.name = 'class';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1).tgt_spec{1}.value = 'cfg_entry';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1).sname = 'Named Input: a';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.a(1).src_output = substruct('.','input');
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1) = cfg_dep;
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1).tname = 'Input b';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1).tgt_spec{1}.name = 'class';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1).tgt_spec{1}.value = 'cfg_entry';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1).sname = 'Named Input: b';
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1).src_exbranch = substruct('.','val', '{}',{2}, '.','val', '{}',{1});
matlabbatch{3}.cfg_toy{1}.add2{1}.cfg_example_add1.b(1).src_output = substruct('.','input');
matlabbatch{4}.cfg_toy{1}.cfg_example_div.a(1) = cfg_dep;
matlabbatch{4}.cfg_toy{1}.cfg_example_div.a(1).tname = 'Input a';
matlabbatch{4}.cfg_toy{1}.cfg_example_div.a(1).tgt_spec = {};
matlabbatch{4}.cfg_toy{1}.cfg_example_div.a(1).sname = 'Add1: Add1: a + b';
matlabbatch{4}.cfg_toy{1}.cfg_example_div.a(1).src_exbranch = substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{4}.cfg_toy{1}.cfg_example_div.a(1).src_output = substruct('()',{1});
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1) = cfg_dep;
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1).tname = 'Input b';
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1).tgt_spec{1}.name = 'class';
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1).tgt_spec{1}.value = 'cfg_entry';
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1).sname = 'Named Input: b';
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1).src_exbranch = substruct('.','val', '{}',{2}, '.','val', '{}',{1});
matlabbatch{4}.cfg_toy{1}.cfg_example_div.b(1).src_output = substruct('.','input');
matlabbatch{5}.cfg_basicio.cfg_assignin.name = '<UNDEFINED>';
matlabbatch{5}.cfg_basicio.cfg_assignin.output(1) = cfg_dep;
matlabbatch{5}.cfg_basicio.cfg_assignin.output(1).tname = 'Output Item';
matlabbatch{5}.cfg_basicio.cfg_assignin.output(1).tgt_spec = {};
matlabbatch{5}.cfg_basicio.cfg_assignin.output(1).sname = 'div: a div b: mod';
matlabbatch{5}.cfg_basicio.cfg_assignin.output(1).src_exbranch = substruct('.','val', '{}',{4}, '.','val', '{}',{1});
matlabbatch{5}.cfg_basicio.cfg_assignin.output(1).src_output = substruct('.','mod');
