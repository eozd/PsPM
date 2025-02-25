classdef pspm_exp_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_exp function
  % ● Authorship
  % (C) 2015 Tobias Moser (University of Zurich)
  properties(Constant)
    func_params = struct('statstypes', {{'param'}}, ...
      'targets', {{'screen', 'fn'}}, ...
      'delim', {{'\t','\n',';'}});
    %         func_params = struct('statstypes', {{'param', 'recon', 'cond'}}, ...
    %             'targets', {{'screen', 'fn'}}, ...
    %             'delim', {{'\t','\n',';'}});
  end
  properties
    usedFilenames = {};
    model = {};
  end
  methods(TestMethodTeardown)
    % clean up produced "mess"
    function cleanUpusedFiles(this)
      n = numel(this.usedFilenames);
      for i=linspace(n,1,n)
        this.removeFile(this.usedFilenames{i});
      end
    end
  end
  methods(TestMethodSetup)
    function prepareClass(this)
      % generate a model which can be used for several tests
      this.model = this.generateModel;
    end
  end
  methods(Test)
    function invalid_input(this)
      %             this.verifyWarning(@()pspm_exp(), 'ID:invalid_input');
      %             this.verifyWarning(@()pspm_exp('nonexistent_file'), 'ID:invalid_input');
      %             this.verifyWarning(@()pspm_exp(), 'ID:invalid_input');
      %             this.verifyWarning(@()pspm_exp(), 'ID:invalid_input');
      %             this.verifyWarning(@()pspm_exp(), 'ID:invalid_input');
      %             this.verifyWarning(@()pspm_exp(), 'ID:invalid_input');
    end
    function valid_input(this)
      % go through each param type and delimiter type and do
      % screen output with fileoutput
      for i = 1:numel(this.func_params.delim)
        d = this.func_params.delim{i};
        for j = 1:numel(this.func_params.statstypes)
          s = this.func_params.statstypes{j};
          % struct for output storage
          for k = 1:numel(this.func_params.targets)
            t = this.func_params.targets{k};
            % function parameter should be a filename
            if strcmpi(t, 'fn')
              target = this.freeTestFilename();
            else
              target = t;
            end
            this.verifyWarningFree(@()pspm_exp(this.model, target, s, d));
          end
        end
      end
    end
  end
  methods
    function [taken] = filenameTaken(this, filename)
      % returns 1 if file exists or filename is in
      % usedFilenames list
      taken = 1;
      if ~exist(filename, 'file')
        m = strcmpi(this.usedFilenames, filename);
        taken = numel(find(m)) > 0;
      end
    end
    function removeFile(this, filename)
      if this.filenameTaken(filename)
        m = strcmpi(this.usedFilenames, filename);
        this.usedFilenames(m) = [];
        delete(filename);
      end
    end
    function [filename] = freeTestFilename(this, prefix, suffix)
      % returns a filename which is not existing and not yet taken
      % by this function
      % set default values
      if nargin < 2 || ~ischar(prefix)
        prefix = 'testdatafile';
      end
      if nargin < 3 || ~ischar(suffix)
        suffix = '.mat';
      end
      % start with a number
      n = 10000;
      filename = strcat(prefix, num2str(n), suffix);
      while this.filenameTaken(filename)
        filename = strcat(prefix, num2str(n), suffix);
        n = n+1;
      end
      % add filename to list
      this.usedFilenames{end+1} = filename;
    end
    function [model] = generateModel(this)
      % generate a simple glm model
      sr = 100;
      duration = 10;
      model.modelfile = this.freeTestFilename();
      model.datafile = this.freeTestFilename();
      model.timeunits = 'seconds';
      model.filter = struct('lpfreq', 'none', 'lporder', 1,  ...
        'hpfreq', 'none', 'hporder', 1, ...
        'down', sr, ...
        'direction', 'uni');
      model.timing.names{1} = 'condition a';
      model.timing.onsets{1} = [1 2 3 5 7]';
      % generate signal and file
      signal = this.testdata_gen(model.timing.onsets{1}, 1, 0, 0, sr, duration);
      this.save_datafile(signal, sr, duration, model.datafile, model.timing.onsets{1});
      % generate model
      glm = pspm_glm(model, struct());
      model = glm.modelfile;
    end
    % saves a datavector to a file copied from pspm_glm_test
    function save_datafile(this, Y, sr, duration, fn, onsets)
      infos.duration = duration;
      data{1}.data = Y;
      data{1}.header.sr = sr;
      data{1}.header.chantype = 'scr';
      data{1}.header.units = 'unknown';
      if nargin > 4
        data{2}.data = onsets;
        data{2}.header.sr = 1;
        data{2}.header.chantype = 'marker';
        data{2}.header.units = 'events';
      end
      save(fn, 'data', 'infos');
    end
    function [signal] = testdata_gen(this, onsets, scal, offset,  onsets_duration, sr, duration)
      % generate signal copied from pspm_glm_test
      % with signal(onsets) = scal + offset
      % default values
      if nargin < 6, duration = 10; end
      if nargin < 5, sr = 100; end
      if nargin < 4
        onsets_duration = zeros(size(onsets));
      elseif isscalar(onsets_duration)
        onsets_duration = onsets_duration .* ones(size(onsets));
      end
      if nargin < 3, offset = 0; end
      if nargin < 2
        scal = ones(size(onsets));
      elseif isscalar(scal)
        scal = scal .* ones(size(onsets));
      end
      signal = zeros(sr*duration,1);
      for i = 1:length(onsets)
        signal(floor(onsets(i)*sr):floor((onsets(i)+onsets_duration(i))*sr)) = scal(i);
      end
      signal = signal + offset;
    end
  end
end
