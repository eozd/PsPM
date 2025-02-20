function sts = cfg_conftest(bch)

% sts = function cfg_conftest(bch)
% Run a set of tests for a configuration file. Details of the tests will
% be displayed in the command window.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: cfg_conftest.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

% Load configuration
if isfield(bch.cfg, 'cfgvar')
    c0 = bch.cfg.cfgvar;
else
    fprintf('Loading configuration from file: ''%s''\n', bch.cfg.cfgfile{1});
    [c0, sts] = load_var_from_fun(bch.cfg.cfgfile{1});
    if ~sts
        return;
    end
end
% Try initialisation through defaults, if any
if ~isfield(bch.def, 'none')
    if isfield(bch.def, 'defvar')
        def = bch.def.defvar;
    else
        fprintf('Loading defaults from file: ''%s''\n', bch.def.deffile{1});
        [def, sts] = load_var_from_fun(bch.def.deffile{1});
        if ~sts
            return;
        end
    end
    try 
        ci1 = initialise(c0, def, true);
    catch
        cfg_disp_error(lasterror);
        sts = false;
        return;
    end
else
    ci1 = c0;
end
% Try initialisation through .def fields
fprintf('Initialisation of .def defaults\n');
try 
    ci2 = initialise(ci1, '<DEFAULTS>', true);
catch
    cfg_disp_error(lasterror);
    sts = false;
    return;
end
% Find cfg_exbranch(es)
[exids, stop, cont] = list(c0, cfg_findspec({{'class','cfg_exbranch'}}), ...
                             cfg_tropts({}, 0, Inf, 0, Inf, true), {'level'});
if isempty(exids)
    fprintf(['No cfg_exbranch items found. '...
             'Some tests will be skipped.\n']);
    return;
end
% List cfg_exbranch(es)
fprintf('The following cfg_exbranch items were found:\n');
for k = 1:numel(exids)
    fprintf('Tag: %s Name: ''%s'' Tree level: %d\n', ...
            subsref(c0, [exids{k} substruct('.','tag')]), ...
            subsref(c0, [exids{k} substruct('.','name')]), ...
            cont{1}{k});
end
% Check for nested cfg_exbranch(es)
if numel(exids) > 1
    if isa(c0, 'cfg_exbranch')
        sts = false;
        pexids{1} = exids{1};
        cexids{1} = exids(2:end);
    else
        sts = true;
        pexids = {};
        cexids = {};
        for k = 1:numel(exids)
            [c1exids, stop] = list(subsref(c0, exids{k}), ...
                                  cfg_findspec({{'class','cfg_exbranch'}}), ...
                                  cfg_tropts({}, true, 0, Inf, 0, Inf));
            if numel(c1exids) > 1 % cfg_exbranch itself always
                                  % matches
                sts = false;
                pexids{end+1} = exids{k};
                cexids{end+1} = c1exids(2:end);
            end
        end
    end
    if ~sts
        fprintf(['Nested cfg_exbranch(es) detected - this is currently ' ...
                 'not supported:\n']);
        for k = 1:numel(pexids)
            fprintf('Parent cfg_exbranch: %s\n', ...
                    subsref(c0, [pexids{k} substruct('.','tag')]));
            for l = 1:numel(cexids{k})
                fprintf('Child cfg_exbranch: %s\n', ...
                        subsref(c0, [pexids{k} cexids{k}{l} ...
                                    substruct('.','tag')]));
            end
        end
        return;
    end
end
% Checks for .vouts
%for k = 1:numel(exids)
%    sts = local_test_all_leafs(ci2, exids{k});
%end
% Checks for sample batches
for k = 1:numel(bch.jobs)
    fprintf('Running test batch #%d\n', k);
    if isfield(bch.jobs{k}, 'jobvar')
        job = bch.jobs{k}.jobvar;
    else
        job = cfg_load_jobs(bch.jobs{k}.jobfile);
        job = job{1};
        if isempty(job)
            fprintf('Failed to load batch ''%s''.\n', bch.jobs{k}.jobfile{1});
        end
    end
    cj = [];
    if ~isempty(job)
        try
            cj = initialise(ci2, job, false);
        catch
            cj = [];
            fprintf('Failed to initialise configuration with job #%d\n', ...
                    k);
        end
    end
    if ~isempty(cj)
        % Test each cfg_exbranch:
        % harvest (if all_leafs, this also runs .vout)
        % all_set   -> run, set .jout, test .sout
        for l = 1:numel(exids)
            fprintf('Testing module %s with job #%d\n', cm.tag, k);
            if isempty(exids{l})
                cm = cj;
            else
                cm = subsref(cj, exids{l});
            end
            try
                [un, hjob, un1, dep, chk, cj] = harvest(cm, cj, false, true);
                hsts = true;
            catch
                hsts = false;
                sts = false;
                fprintf('Failed to harvest configuration\n');
                cfg_disp_error(lasterror);
            end
            if hsts
                if ~isempty(dep)
                    fprintf('Module has unresolved dependencies\n'),
                end
                if ~chk
                    fprintf('Validity checks failed\n');
                end
                if ~all_set(cm)
                    fprintf('Module does not have all inputs set\n');
                end
                if isempty(dep) && chk && all_set(cm)
                    fprintf('Running module\n');
                    try
                        cm = cfg_run_cm(cm, job);
                        fprintf('''%s'' done\n', cm.name);
                        rsts = true;
                    catch
                        fprintf('''%s'' failed\n', cm.name);
                        cfg_disp_error(lasterror);
                        rsts = false;
                        sts = false;
                    end
                    if rsts
                        cj = subsasgn(cj, exids{l}, cm);
                        for m = 1:numel(cm.sout)
                            % Job should have returned outputs
                            try
                                out = subsref(cm, [substruct('.','jout') cm.sout(m).src_output]);
                                fprintf(['Successfully referenced output ' ...
                                         '''%s''\n'], cm.sout(m).sname);
                            catch
                                fprintf(['Failed to reference output ' ...
                                         '''%s''\n'], cm.sout(m).sname);
                                cfg_disp_error(lasterror);
                                sts = false;
                            end
                        end
                    end
                end
            end
        end
    end
end

function [val, sts] = load_var_from_fun(fname)
val = [];
sts = false;
if ~exist(fname,'file')
    fprintf('File does not exist: ''%s''\m', fname);
    return;
end
[p, n, e] = fileparts(fname);
if ~strcmpi(e, '.m')
    fprintf('File does not have MATLAB ''.m'' extension.');
    return;
end
cfgs = which(n, '-all');
if numel(cfgs) > 1
    fprintf('Multiple instances of function/variable on MATLAB path:\n');
    fprintf('   %s\n', cfgs{:});
    fprintf('Trying the one specified in file: ''%s''\n', fname);
end
opwd = pwd;
if ~isempty(p)
    try
        cd(p);
    catch
        fprintf('Can not change to directory ''%s''.\n', p);
        return;
    end
end
try
    val = feval(n);
    sts = true;
catch
    fprintf('Failed to run ''val = feval(''%s'');\n', n);
    cfg_disp_error(lasterror);
end
cd(opwd);

% Here, it would be necessary to collect a number for how many
% configurations are there to produce suitable vectors for fillval

% function [sts jfailed] = local_test_all_leafs(c, exsubs, subs)
% % c      - full configuration tree
% % exsubs - subscript into c for cfg_exbranch tested
% % subs   - subscript into c for node to be evaluated

% sts = true;
% jfailed = {};

% if isempty(exsubs)
%     exitem = c;
% else
%     exitem = subsref(c,exsubs);
% end
% if isempty(item.vout)
%     fprintf('No .vout callback defined - no tests performed.\n');
%     return;
% end
% if isempty(subs)
%     citem = c;
% else
%     citem = subsref(c,subs);
% end

% if isa(citem, 'cfg_leaf')
%     if all_leafs(exitem)
%         [sts jfailed] = local_test_exitem(exitem, cj);
%     end
% else
%     switch class(citem)
%         case {'cfg_branch', 'cfg_exbranch'},
%             % cycle through all choosen .val items, do not change any contents
%             % here
%             for k = 1:numel(citem.val)
%                 csubs = [subs substruct('.','val','{}',{k})];
%                 [sts jfailed1] = local_test_all_leafs(c, exsubs, csubs);
%                 jfailed = {jfailed{:} jfailed1{:}};
%             end
%         case 'cfg_choice',
%             csubs = [subs substruct('.','val','{}',{1})];
%             for l = 1:numel(citem.values)
%                 [sts jfailed1] = local_test_all_leafs(...
%                     subsasgn(c, csubs, subsref(c, [subs ...
%                                     substruct('.','values', '{}',{l})])), ...
%                     exsubs, csubs);
%                 jfailed = {jfailed{:} jfailed1{:}};
%             end
%         case 'cfg_repeat',
%             % only test for minimum required number of repeats, or zero
%             % and one if no minimum specified
%             if citem.num(1) == 0
%                 c1 = subsasgn(c, [subs substruct('.','val')], {});
%                 if isempty(exsubs)
%                     exitem = c1;
%                 else
%                     exitem = subsref(c1,exsubs);
%                 end
%                 if all_leafs(exitem)
%                     [sts jfailed] = local_test_exitem(exitem, c1);
%                 end
%                 nval = 1;
%             else
%                 nval = citem.num(1);
%             end
%             % create index array - this can grow large!
%             nvalues = numel(citem.values);
%             nind    = zeros(nval, nvalues^nval);
%             valvec  = 1:nvalues;
%             for k = 1:nval
%                 nind(k,:) = repmat(kron(valvec, ones(1,nvalues^(k-1))), ...
%                                    1, nvalues^(nval-k));
%             end
%             for k = 1:nvalues^nval
%                 cval = subsref(c, [subs ...
%                                    substruct('.','values', ...
%                                              '()',{nind(:,k)})]);
%                 c = subsasgn(c, [subs substruct('.','val')], cval);
%     end
% end                
% function [sts jf] = local_test_exitem(exitem, c)
% sts = true;
% jf = {};
% % should try twice - once with '<UNDEFINED>', once with cfg_deps
% [u j] = harvest(exitem, c, false, false);
% try
%     sout = feval(exitem.vout, j);
% catch
%     sts = false;
%     jf{end+1} = j;
% end
