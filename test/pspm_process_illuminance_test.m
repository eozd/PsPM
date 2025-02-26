classdef pspm_process_illuminance_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_process_illuminance function
  % ● Authorship
  % (C) 2016 Tobias Moser (University of Zurich)
  properties
    testfile_prefix = 'testdata_process_illuminance';
    datafiles = {};
  end
  properties (TestParameter)
    % one file
    bf_dur = {0.1 10 100};
    bf_offset = {0.1 10 100};
    dur = {0.1 10 100};
    sr = {0.1 10 100};
    % multiple files
    n_times = {1, 8}
    mode = {'file', 'data', 'mixed'};
  end
  methods(TestMethodTeardown)
    %% Cleanup function
    function cleanup(this)
      for i=1:length(this.datafiles)
        d = this.datafiles{i};
        if ~isempty(d) && exist(d, 'file')
          delete(d);
        end
      end
      this.datafiles = {''};
    end
  end
  methods
    %% Generate data
    function [data_list, sr_list] = generate_lx(this, sr, dur, n_times, mode)
      if strcmpi(mode, 'mixed')
        data_list = repmat({'file'; 'data'}, fix(n_times/2), 1);
        if mod(n_times, 2) == 1
          data_list{end+1} = 'file';
        end
      else
        data_list = repmat({mode}, n_times, 1);
      end
      sr_list = cell(n_times,1);
      for i=1:n_times
        sr_list{i} = sr;
        t = linspace(0,dur-sr, dur*sr)';
        Lx = (square(t/5) + sin(t-5) + sin(t/2));
        % create simple sine function
        switch data_list{i}
          case 'file'
            file_name = pspm_find_free_fn(this.testfile_prefix, '.mat');
            this.datafiles{end+1} = file_name;
            data_list{i} = file_name;
            save(file_name, 'Lx');
          case 'data'
            data_list{i} = Lx;
        end
      end
    end
  end
  methods (Test)
    %% test options
    function test_options(this, sr, dur, bf_dur, bf_offset)
      [d_list, sr_list] = this.generate_lx(sr, dur, 1, 'data');
      d_list = d_list{1};
      sr_list = sr_list{1};
      o = struct();
      o.bf.duration = bf_dur;
      o.bf.offset = bf_offset;
      if sr*dur < 1
        expect_warning = 'ID:missing_data';
      elseif sr*bf_dur < 1
        expect_warning = 'ID:invalid_input';
      else
        expect_warning = '';
      end
      if ~isempty(expect_warning)
        [sts, ~] = this.verifyWarning(@()pspm_process_illuminance(d_list, sr_list, o), expect_warning);
        this.verifyEqual(sts, -1);
      else
        [sts, out] = this.verifyWarningFree(@()pspm_process_illuminance(d_list, sr_list, o));
        this.verifyEqual(sts, 1);
        this.verifyEqual(size(out,1), size(d_list,1));
      end
    end
    %% test multi
    function test_multi(this, n_times, mode)
      [data, sr_list] = this.generate_lx(10, 100, n_times, mode);
      [sts, out] = this.verifyWarningFree(@()pspm_process_illuminance(data, sr_list));
      this.verifyEqual(sts, 1);
      if n_times == 1
        % sr*dur
        this.verifyEqual(size(out,1), 10*100);
      else
        this.verifyEqual(size(out), size(data));
      end
    end
    %% test overwrite
    function test_overwrite(this)
      [fn_list, sr_list] = this.generate_lx(10, 100, 1, 'file');
      fn = fn_list{1};
      sr = sr_list{1};
      o = struct();
      o.fn = fn;
      o.overwrite = 1;
      [sts, out] = this.verifyWarningFree(@()pspm_process_illuminance(fn, sr, o));
      this.verifyEqual(sts, 1);
      d = load(fn);
        % if overwrite
      this.verifyTrue(ischar(out));
      this.verifyTrue(isfield(d, 'R'));
      this.verifyEqual(size(d.R, 2), 2);
        % else
        %   this.verifyTrue(isnumeric(out));
        %   this.verifyTrue(isfield(d, 'Lx'));
        %   this.verifyEqual(size(d.Lx, 2), 1);
        % end
    end
  end
  methods (Test)
    %% test for invalid input
    function invalid_input(this)
      % no input
      this.verifyWarning(@() pspm_process_illuminance(), 'ID:invalid_input');
      % empty data
      this.verifyWarning(@() pspm_process_illuminance([]), 'ID:missing_data');
      % no sample rate
      this.verifyWarning(@() pspm_process_illuminance(1:10), 'ID:invalid_input');
      % wrong sample rate
      this.verifyWarning(@() pspm_process_illuminance(1:10,'a'), 'ID:invalid_input');
      % wrong combinations of cell and not cell
      this.verifyWarning(@() pspm_process_illuminance({1:10}, 1), 'ID:invalid_input');
      this.verifyWarning(@() pspm_process_illuminance(1:10, {1}), 'ID:invalid_input');
      % different size of cells
      this.verifyWarning(@() pspm_process_illuminance({1:10, 1:10}, {1}), 'ID:invalid_input');
      % variable format in cells
      this.verifyWarning(@() pspm_process_illuminance({1:10, 'a'}, {1, 2}), 'ID:non_existent_file');
      this.verifyWarning(@() pspm_process_illuminance({1:10, 1:10}, {1, 'a'}), 'ID:invalid_input');
      % wrong options
      this.verifyWarning(@() pspm_process_illuminance({1:10}, {1}, 'o'), 'ID:invalid_input');
      % wrong transfer
      opt = struct();
      opt.transfer = 'a';
      this.verifyWarning(@() pspm_process_illuminance({1:10}, {1}, opt), 'ID:invalid_input');
      % wrong duration
      opt.transfer = [32.5630666816594,-1.02577520996545,-0.475357710693852];
      opt.bf = struct();
      opt.bf.duration = '20';
      this.verifyWarning(@() pspm_process_illuminance({1:10}, {1}, opt), 'ID:invalid_input');
      % wrong offset
      opt.bf.duration = 20;
      opt.bf.offset = '0.2';
      this.verifyWarning(@() pspm_process_illuminance({1:10}, {1}, opt), 'ID:invalid_input');
      % wrong fn
      opt.bf.offset = 0.2;
      opt.fn = 1;
      this.verifyWarning(@() pspm_process_illuminance({1:10}, {1}, opt), 'ID:invalid_input');
      % fn not same format as ldata
      opt.fn = 'a';
      this.verifyWarning(@() pspm_process_illuminance({1:10}, {1}, opt), 'ID:invalid_input');
    end
  end
end
