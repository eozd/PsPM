classdef pspm_find_sounds_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_find_sounds function
  % ● Authorship
  % (C) 2015 Tobias Moser (University of Zurich)
  %     2022 Teddy
  properties
    testdata_fn = 'find_sounds_test';
  end
  properties (TestParameter)
    channel_output = {'all', 'corrected'};
    max_delay = {0.01, 3, 100};
    min_delay = {0.001, .01};
    threshold = {0,0.1,0.5,1};
    resample = {1, 50, 1000};
    channel_action = {'add', 'replace'};
  end
  methods(Test)
    function invalid_input(this) % file does not exist
      this.verifyWarning(@() pspm_find_sounds(''), 'ID:nonexistent_file');
      % create empty file
      fn = pspm_find_free_fn(this.testdata_fn, '.mat');
      fclose(fopen(fn, 'w'));
      % test with invalid pspm file
      this.verifyWarning(@() pspm_find_sounds(fn), 'ID:invalid_file_type');
      % test with data without a snd channel
      c{1}.chantype = 'scr';
      pspm_testdata_gen(c, 10, fn);
      this.verifyWarning(@() pspm_find_sounds(fn), 'ID:non_existing_chantype');
      c{1}.chantype = 'snd';
      c{1}.noise = 1;
      pspm_testdata_gen(c, 10, fn);
      % invalid values for positive integer fields
      invalid_values = {'noise', 1.5, -1};
      pos_int_fields = {'resample','channel', 'marker_chan_num', 'expectedSoundCount'};
      warning_IDs = {'ID:invalid_input', 'ID:invalid_input', 'ID:invalid_input'; ...
                     'ID:invalid_chantype', 'ID:invalid_input', 'ID:invalid_input'; ...
                     'ID:invalid_chantype', 'ID:invalid_input', 'ID:invalid_input'; ...,
                     'ID:invalid_input', 'ID:invalid_input', 'ID:invalid_input'};
      for i=1:numel(pos_int_fields)
          for j=1:numel(invalid_values)
              o = struct(pos_int_fields{i}, invalid_values{j}, 'diagnostics', 1);
              this.verifyWarning(@() pspm_find_sounds(fn, o), warning_IDs{i, j});
          end
      end
      % invalid values for positive numeric fields
      invalid_values = {'a', -1};
      pos_num_fields = {'maxdelay', 'threshold', 'mindelay'};
      for i=1:numel(invalid_values)
        for j=1:numel(pos_num_fields)
          o = struct(pos_num_fields{j}, invalid_values{i});
          this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
        end
      end
      % invalid values for logic fields
      log_fields = {'diagnostics', 'plot'};
      for j=1:numel(log_fields)
        o = struct(log_fields{j}, 'a');
        this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
      end
      o = struct('channel_output', 'a');
      this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
      % invalid channel ids out of range
      channel_fields = {'channel', 'marker_chan_num'};
      for i=1:numel(channel_fields)
        o = struct(channel_fields{i}, 5, 'diagnostics', 1);
        this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
      end
      % test with diagnostics and no marker channel in data
      o = struct('diagnostics', 1);
      this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:non_existing_chantype');
      % test with invalid channel_action
      inv_val = {'a', 1};
      for i=1:length(inv_val)
        o = struct('channel_action',inv_val{i});
        this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
      end
      % test with invalid roi
      inv_val = {'a', 1, [-1 1]};
      for i=1:length(inv_val)
        o = struct('roi',inv_val{i});
        this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
      end
      o = struct('mindelay', 1, 'maxdelay', .5);
      this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:invalid_input');
      % remove test file
      delete(fn)
    end
  end
  methods (Test)
    function test_add_channel(this, channel_output, max_delay, min_delay, resample, channel_action)
      dur = 10;
      % sound channel
      c{1}.chantype = 'snd';
      c{1}.noise = 1;
      % marker
      c{2}.chantype = 'marker';
      c{2}.eventdist = 'max';
      fn = pspm_find_free_fn(this.testdata_fn, '.mat');
      pspm_testdata_gen(c, dur, fn);
      [~, ~, ref_data] = pspm_load_data(fn);
      n_ref_marker = numel(ref_data{2}.data);
      % define options
      o = struct('diagnostics', 1, ...
        'channel_output', channel_output, 'maxdelay', max_delay, ...
        'mindelay', min_delay, 'resample', resample, 'channel_action', channel_action);
      if max_delay == this.max_delay{1} && strcmpi(channel_output, 'corrected') ...
          && ~strcmpi(channel_action, 'none')
        % warning by pspm_load_data because channel will be empty
        [~, channel, out_infos] = this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:missing_data');
        [sts, ~, d_data] = this.verifyWarning(@() pspm_load_data(fn), 'ID:missing_data');
      else
        [~, channel, out_infos] = this.verifyWarningFree(@() pspm_find_sounds(fn, o));
        [sts, ~, d_data] = this.verifyWarningFree(@() pspm_load_data(fn));
      end
      this.verifyEqual(sts, 1);
      this.verifyTrue(isfield(out_infos, 'delays'));
      this.verifyTrue(isfield(out_infos, 'snd_markers'));
      % are there 3 channels
      if strcmpi(channel_action, 'replace')
          this.verifyEqual(channel, 2);
      else
          this.verifyEqual(channel, 3);
      end
      this.verifyEqual(numel(out_infos.delays), numel(out_infos.snd_markers));
      if (max_delay == this.max_delay{1}) && strcmpi(channel_output, 'corrected')
          % no markers should be detected
          this.verifyEqual(numel(d_data{channel}.data),0);
      else
          if strcmpi(channel_output, 'all')
              % #3 should contain any data and should contain more
              % than #2
              this.verifyTrue(numel(d_data{channel}.data)>=1 ...
                  && numel(d_data{channel}.data) > n_ref_marker);
          elseif strcmpi(channel_output, 'corrected')
              % #3 should contain any data and should contain the same
              % amount of markers as #2
              this.verifyTrue(numel(d_data{channel}.data)>=1);
              % allow relative tolerance of +/- 1 data point
              this.verifyEqual(numel(d_data{channel}.data), n_ref_marker, ...
                  'RelTol', 1/n_ref_marker);
              this.verifyEqual(numel(d_data{channel}.data), numel(out_infos.snd_markers));
          end
      end
      delete(fn);
    end
    function test_region_count(this)
      % this test only works because generated data is 'symmetric'
      % and events occur always with same distance
      dur = 10;
      % sound channel
      c{1}.chantype = 'snd';
      c{1}.noise = 1;
      % marker
      c{2}.chantype = 'marker';
      c{2}.eventdist = 'max';
      fn = pspm_find_free_fn(this.testdata_fn, '.mat');
      pspm_testdata_gen(c, dur, fn);
      [~, ~, ref_data] = pspm_load_data(fn);
      n_ref_marker = numel(ref_data{2}.data);
      o = struct('roi', [], 'expectedSoundCount', n_ref_marker);
      this.verifyWarningFree(@() pspm_find_sounds(fn, o));
      o = struct('roi', [], 'expectedSoundCount', n_ref_marker, 'threshold', 1);
      this.verifyWarning(@() pspm_find_sounds(fn, o), 'ID:bad_data');
      o = struct('roi', [0,5], 'expectedSoundCount', n_ref_marker*(5/dur));
      this.verifyWarningFree(@() pspm_find_sounds(fn, o));
      delete(fn);
    end
    function test_threshold(this, threshold)
      dur = 10;
      % sound channel
      c{1}.chantype = 'snd';
      c{1}.noise = 1;
      % marker
      c{2}.chantype = 'marker';
      c{2}.eventdist = 'max';
      fn = pspm_find_free_fn(this.testdata_fn, '.mat');
      pspm_testdata_gen(c, dur, fn);
      % define options
      o = struct('diagnostics', 1, 'threshold', threshold);
      % the next line could lead to warnings if no sounds are found due to
      % a high threshold
      [sts, channel, out_infos] = pspm_find_sounds(fn, o);
      this.verifyEqual(sts, 1);
      this.verifyTrue(isfield(out_infos, 'delays'));
      this.verifyTrue(isfield(out_infos, 'snd_markers'));
      this.verifyEqual(numel(out_infos.delays), numel(out_infos.snd_markers));
      if threshold == 0 || threshold == 1
        this.verifyEqual(numel(out_infos.snd_markers), 0);
      else
        this.verifyTrue(numel(out_infos.snd_markers) >= 1);
      end
      delete(fn);
    end
    function test_plot(this)
      dur = 10;
      % sound channel
      c{1}.chantype = 'snd';
      c{1}.noise = 1;
      % marker
      c{2}.chantype = 'marker';
      c{2}.eventdist = 'max';
      fn = pspm_find_free_fn(this.testdata_fn, '.mat');
      pspm_testdata_gen(c, dur, fn);
      % define options
      o = struct('diagnostics', 1, 'plot', 1);
      [sts, channel, out_infos] = this.verifyWarningFree(@() pspm_find_sounds(fn, o));
      this.verifyEqual(sts, 1);
      this.verifyTrue(isfield(out_infos, 'delays'));
      this.verifyTrue(isfield(out_infos, 'snd_markers'));
      this.verifyEqual(numel(out_infos.delays), numel(out_infos.snd_markers));
      delete(fn);
    end
  end
end
