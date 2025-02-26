classdef pspm_load1_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_load1 function
  % ● Authorship
  % (C) 2015 Tobias Moser (University of Zurich)
  properties (Constant)
    % define testfile name
    fn = 'testdata_load1.mat';
  end
  properties
    modelfiles = {};
    dummyfiles = {};
    dummy_fn = '';
    defaults;
  end
  methods(TestClassSetup)
    function generate_testdata(this)
      % ensure pspm_init values are set
      global settings;
      if isempty(settings), pspm_init; end
      this.defaults = settings;
      % generate aquisition data
      c{1}.chantype = 'scr';
      c{2}.chantype = 'hb';
      pspm_testdata_gen(c, 100, this.fn);
      % generate model data
      model.datafile = this.fn;
      model.timeunits = 'seconds';
      for i = 1:length(settings.first)
        if ~strcmpi(settings.first{i},'tam')
          mbn = ['model_', settings.first{i}];
          fn_ok = false;
          j = 0;
          while fn_ok == false
            mfn = [mbn, num2str(j), '.mat'];
            if exist(mfn, 'file') == false, fn_ok = true; end
            j = j+1;
          end
          j = j-1;
          dfn = ['dummy_',settings.first{i}, num2str(j), '.mat'];
          switch settings.first{i}
            case 'glm'
              model.timing{1}.names = {'a';'b';'c'};
              model.timing{1}.onsets = {[10, 20, 30], ...
                [15, 25, 35], [18, 28, 38]};
            otherwise
              model.timing{1} = [10,20; 23,38; 40,70;];
              model.condition{1}.name = {'a';'b'};
              model.condition{1}.index = [1;2];
          end
          model.modelfile = mfn;
          this.modelfiles{i} = mfn;
          this.dummyfiles{i} = dfn;
          fh = str2func(['pspm_', settings.first{i}]);
          fh(model, struct());
          if ~exist(mfn), keyboard; end
          copyfile(this.modelfiles{i}, this.dummyfiles{i});
        end
      end
    end
  end
  methods(TestClassTeardown)
    function remove_testdata(this)
      % Remove Testdata
      if exist(pspm_load1_test.fn, 'file')
        delete(pspm_load1_test.fn);
      end
      for i=1:numel(this.modelfiles)
        if exist(this.modelfiles{i}, 'file'), delete(this.modelfiles{i}); end
      end
      for i=1:numel(this.dummyfiles)
        if exist(this.dummyfiles{i}, 'file'), delete(this.dummyfiles{i}); end
      end
    end
  end
  methods
    function basic_function_test(this, f, sts, mdltype)
      mdl = load(f);
      mdltypes = this.defaults.first;
      mdt = find(ismember(mdltypes, fieldnames(mdl)));
      mdt = mdltypes{mdt};
      this.verifyEqual(mdl.(mdt).modeltype, mdltype, 'The returned modeltype does not match the modeltype set in the model structure.');
      this.verifyEqual(sts, 1, 'Function did not complete without error.');
    end
  end
  methods(Test)
    function invalid_inputargs(this)
      this.verifyWarning(@()pspm_load1(), 'ID:invalid_input');
      this.verifyWarning(@()pspm_load1('some_file'), 'ID:invalid_input');
      f = this.modelfiles{1};
      this.verifyWarning(@()pspm_load1(f, 'unknown_action'), 'ID:unknown_action');
      this.verifyWarning(@()pspm_load1(f, 'save'), 'ID:missing_data');
      this.verifyWarning(@()pspm_load1(f, 'savecon'), 'ID:missing_data');
    end
    function invalid_model_structure_general(this)
      % test with defect structure
      % in general
      dfn = this.dummyfiles{1};
      dummy = load(dfn);
      dummy_backup = dummy;
      mdltypes = this.defaults.first;
      mdltype = find(ismember(mdltypes, fieldnames(dummy)));
      mdltype = mdltypes{mdltype};
      % test missing field with model content (glm/dcm/sf)
      empty = struct();
      save(dfn, '-struct', 'empty');
      this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
      % test missing fields in model data
      dummy = dummy_backup;
      dummy.(mdltype) = rmfield(dummy.(mdltype), 'modelfile');
      dummy.(mdltype) = rmfield(dummy.(mdltype), 'modeltype');
      dummy.(mdltype) = rmfield(dummy.(mdltype), 'modality');
      dummy.(mdltype) = rmfield(dummy.(mdltype), 'stats');
      dummy.(mdltype) = rmfield(dummy.(mdltype), 'names');
      save(dfn, '-struct', 'dummy', mdltype);
      % order is important (because of if / else statements)
      % modelfile
      this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
      dummy.(mdltype).modelfile = dummy_backup.(mdltype).modelfile;
      save(dfn, '-struct', 'dummy', mdltype);
      % modeltype
      this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
      dummy.(mdltype).modeltype = dummy_backup.(mdltype).modeltype;
      save(dfn, '-struct', 'dummy', mdltype);
      % modality
      this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
      dummy.(mdltype).modality = dummy_backup.(mdltype).modality;
      save(dfn, '-struct', 'dummy', mdltype);
      % stats
      this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
      dummy.(mdltype).stats = dummy_backup.(mdltype).stats;
      save(dfn, '-struct', 'dummy', mdltype);
      % names
      this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
      dummy.(mdltype).names = dummy_backup.(mdltype).names;
      % restore in order to use the dummy file for the specific
      % structure tests
      save(dfn, '-struct', 'dummy', mdltype);
      this.verifyWarningFree(@()pspm_load1(dfn, 'none'));
    end
    function invalid_model_structure_specific(this)
      % specific structure tests
      for i=1:numel(this.dummyfiles)
        dfn = this.dummyfiles{i};
        dummy = load(dfn);
        dummy_backup = dummy;
        mdltypes = this.defaults.first;
        mdltype = find(ismember(mdltypes, fieldnames(dummy)));
        mdltype = mdltypes{mdltype};
        switch mdltype
          case 'glm'
            % try out glm data structure size constraints
            dummy.glm.stats = [dummy.glm.stats, dummy.glm.stats];
            save(dfn, '-struct', 'dummy', 'glm');
            this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
            dummy.glm.stats = [dummy.glm.stats(:,1); dummy.glm.stats(:,2)];
            save(dfn, '-struct', 'dummy', 'glm');
            this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
            dummy = dummy_backup;
            save(dfn, '-struct', 'dummy', 'glm');
            options.zscored = 1;
            this.verifyWarning(@()pspm_load1(dfn, 'cond', {}, options), 'ID:invalid_input');
          otherwise
            dummy.(mdltype).trlnames = 1:size(dummy.(mdltype).stats,1)+1;
            save(dfn, '-struct', 'dummy', mdltype);
            this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
            dummy.(mdltype) = rmfield(dummy.(mdltype), 'trlnames');
            save(dfn, '-struct', 'dummy', mdltype);
            this.verifyWarning(@()pspm_load1(dfn, 'none'), 'ID:invalid_data_structure');
            dummy = dummy_backup;
            dummy.(mdltype).names = 1:size(dummy.(mdltype).stats,2)+1;
            save(dfn, '-struct', 'dummy', mdltype);
            dummy = dummy_backup;
            save(dfn, '-struct', 'dummy', mdltype);
            this.verifyWarning(@()pspm_load1(dfn, 'recon'), 'ID:invalid_input');
        end
        options.zscored = 1;
        if strcmpi(mdltype, 'dcm')
          this.verifyWarning(@()pspm_load1(dfn, 'none', {}, options), 'ID:invalid_input');
          this.verifyWarningFree(@()pspm_load1(dfn, 'cond', {}, options));
          this.verifyWarningFree(@()pspm_load1(dfn, 'stats', {}, options));
        else
          this.verifyWarning(@()pspm_load1(dfn, 'cond', {}, options), 'ID:invalid_input');
        end
      end
    end
    function test_action_none(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'none'));
        this.basic_function_test(f, sts, mdltype);
        this.verifyEmpty(data, 'Returned data is not empty.');
      end
    end
    function test_action_stats(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'stats'));
        this.basic_function_test(f, sts, mdltype);
        % check for fields
        this.verifyTrue(isfield(data, 'stats'), 'No ''stats'' returned.');
        this.verifyTrue(isfield(data, 'names'), 'No ''names'' returned.');
        if ~strcmpi(mdltype, 'glm')
          this.verifyTrue(isfield(data, 'trlnames'), 'No ''trlnames'' returned.');
          this.verifyTrue(isfield(data, 'condnames'), 'No ''condnames'' returned.');
        end
      end
    end
    function test_action_cond(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'cond'));
        this.basic_function_test(f, sts, mdltype);
        this.verifyTrue(isfield(data, 'stats'), 'No ''stats'' returned.');
        this.verifyTrue(isfield(data, 'names'), 'No ''names'' returned.');
        switch mdltype
          case 'glm'
          otherwise
            this.verifyTrue(isfield(data, 'trlnames'), 'No ''trlnames'' returned.');
            this.verifyTrue(isfield(data, 'condnames'), 'No ''condnames'' returned.');
        end
      end
    end
    function test_action_recon(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        mdl = load(f);
        mdltypes = this.defaults.first;
        mdltype = find(ismember(mdltypes, fieldnames(mdl)));
        mdltype = mdltypes{mdltype};
        if strcmpi(mdltype, 'glm')
          [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'recon'));
          this.basic_function_test(f, sts, mdltype);
          this.verifyTrue(isfield(data, 'stats'), 'No ''stats'' returned.');
          this.verifyTrue(isfield(data, 'names'), 'No ''names'' returned.');
        end
        % non-linear alternative already checked in specific
        % structure test
      end
    end
    % run before con in order to create a con field
    function test_action_savecon(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        x = rand(1);
        savecon = struct('test', x, 'con', 0);
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'savecon', savecon, struct()));
        this.basic_function_test(f, sts, mdltype);
        % check for fields
        % just check if it was written, do not check for structure
        % this should be done by pspm_con1_test
        mdl = load(f);
        this.verifyTrue(isfield(mdl.(mdltype), 'con'), 'No field ''con'' in model.');
        this.verifyTrue(isfield(mdl.(mdltype).con, 'test'), 'No field ''con.test'' in model.');
        this.verifyEqual(mdl.(mdltype).con.test, x, 'Test field does not contain the expected value.');
      end
    end
    function test_action_con(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        mdl = load(f);
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'con'));
        this.basic_function_test(f, sts, mdltype);
        % check for fields
        if isfield(mdl.(mdltype), 'con')
          this.verifyTrue(isfield(data, 'test'), 'No ''con'' returned.');
        end
      end
    end
    function test_action_all(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'stats'));
        this.basic_function_test(f, sts, mdltype);
        % check for fields
        this.verifyNotEmpty(data, 'Returned data is empty.');
      end
    end
    function test_action_save(this)
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        x = rand(1);
        mdl = load(f);
        mdltypes = this.defaults.first;
        mdltype = find(ismember(mdltypes, fieldnames(mdl)));
        mdltype = mdltypes{mdltype};
        mdl.(mdltype).test = x;
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'save', mdl, struct('overwrite', 1)));
        this.basic_function_test(f, sts, mdltype);
        % check for fields
        mdl = load(f);
        this.verifyTrue(isfield(mdl.(mdltype), 'test'), 'No field ''test'' in model.');
        this.verifyEqual(mdl.(mdltype).test, x, 'Test field does not contain the expected value.');
      end
    end
    function test_options(this)
      options = struct();
      for i=1:numel(this.modelfiles)
        f = this.modelfiles{i};
        x = rand(1);
        mdl = load(f);
        mdltypes = this.defaults.first;
        mdltype = find(ismember(mdltypes, fieldnames(mdl)));
        mdltype = mdltypes{mdltype};
        mdl.(mdltype).test = x;
        % do overwrite
        mdl.(mdltype).test = x;
        [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'save', mdl, struct('overwrite', 1)));
        mdl = load(f);
        this.verifyEqual(mdl.(mdltype).test, x);
        % test zscored
        if strcmpi(mdltype, 'dcm')
          % zscore stats of model to compare with 'stats'
          % should be equal
          stats = zscore(mdl.(mdltype).stats);
          options.zscored = 0;
          [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'stats', mdl, options));
          this.basic_function_test(f, sts, mdltype);
          this.verifyNotEqual(data.stats, stats, 'Not zscoring did not yield the expected value!');
          options.zscored = 1;
          [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'stats', mdl, options));
          this.basic_function_test(f, sts, mdltype);
          this.verifyEqual(data.stats, stats, 'Zscore did not yield the expected value!');
          % test for 'cond'
          options.zscored = 0;
          [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'cond', mdl, options));
          this.basic_function_test(f, sts, mdltype);
          cond_stats = data.stats;
          options.zscored = 1;
          [sts, data, mdltype] = this.verifyWarningFree(@()pspm_load1(f, 'cond', mdl, options));
          this.basic_function_test(f, sts, mdltype);
          % ensure data is not zscored if not specified
          this.verifyNotEqual(data.stats, cond_stats, 'Zscore seems to be done even if not specified so.');
        end
      end
    end
  end
end
