classdef pspm_convert_ecg2hb_test < pspm_testcase
  % ● Description
  % unittest class for the pspm_convert_ecg2hb function
  % ● Authorship
  % (C) 2015 Tobias Moser (University of Zurich)
  properties
    testdata = {...
      struct(...
      'filename', ['ImportTestData' filesep 'ecg2hb' filesep 'test_ecg_outlier_data.mat'],...
      'chan_struct', struct('nr', 1, 'name', 'ecg'),...
      'num_channels', 1 ...
      ),...
      struct(...
      'filename', ['ImportTestData' filesep 'ecg2hb' filesep 'tpspm_s102_s1.mat'],...
      'chan_struct', struct('nr', 3, 'name', 'ecg'),...
      'num_channels', 5 ...
      )...
      };
    backup_suffix = '_backup';
    options = struct('semi', 0); % disable semi automatic mode
  end
  methods(TestClassSetup)
    function backup_all(this)
      for i=1:length(this.testdata)
        filename = this.testdata{i}.filename;
        backup_name = this.backup_datafile(filename);
        this.testdata{i}.backup_name = backup_name;
      end
    end
  end
  methods
    function backup_name = get_backup_name(this, filename)
      [pathstr, name, ext] = fileparts(filename);
      backup_name = [name, this.backup_suffix];
      i = 0;
      new_filename = [pathstr, filesep, backup_name, num2str(i), ext];
      while exist(new_filename, 'file') && i < 100
        i = i+1;
        new_filename = [pathstr, filesep, backup_name, num2str(i), ext];
      end
      backup_name = new_filename;
    end
    function saved_backup_name = backup_datafile(this, filename)
      if exist(filename, 'file')
        backup_name = this.get_backup_name(filename);
        sts = copyfile(filename, backup_name);
        if sts == 1
          saved_backup_name = backup_name;
        else
          warning('Creating backup file of data file failed');
          saved_backup_name = '';
        end
      end
    end
    function test_added_data(this, filename, original_num_channels)
      if exist(filename, 'file')
        [nsts, infos, data] = pspm_load_data(filename);
        if nsts == -1
          warning('unable to load the test data file');
          return;
        end
        if numel(data) > original_num_channels
          for i=original_num_channels+1:numel(data)
            % check if channel header is correct
            hdr = data{i}.header;
            if hdr.sr ~= 1, warning('Wrong sampling rate in header'); end
            if ~strcmpi(hdr.units, 'events'), warning('Wrong unit in header'); end
            if ~strcmpi(hdr.chantype, 'hb'), warning('Wrong chantype in header'); end
            % check if channel has data
            d = data{i}.data;
            if numel(d) < 1, warning('Less than 1 data points'); end
            % check if hb time indices are increasing
            if ~isempty(find(diff(d) < 0))
              warning('Heartbeat seconds are not monotonically increasing');
            end
            % check if there are too many heartbeats at the same second
            max_beats_per_minute = 300;
            max_beats_per_second = max_beats_per_minute / 60;
            if max_beats_in_k_seconds(d, 1) >= max_beats_per_second
              warning(sprintf('Beats per minute is at least %d. Either data is problematic or the algorithm is incorrect.', max_beats_per_minute))
            end
            % check if data is equally distributed
            % for a heartbeat it should be less than 2s
            % otherwise there is something odd
            if std(diff(d)) > 2,
              warning('Abnormal high standard deviation (more than 2s) of time between heartbeats');
            end
            % check if last data point also corresponds to the
            % length of the recordings
            % shouldn't be more than 60s either
            if (infos.duration - d(end)) > 60
              warning('Heartbeat data ends 60s earlier than data recording');
            end
          end
        else
          warning('No channel has been added to testfile');
          return;
        end
      else
        warning('test data file does not exist');
      end
    end
    function cleanup_backup(this, filename, backup_name)
      if exist(backup_name, 'file')
        copyfile(backup_name, filename);
        delete(backup_name);
      else
        warning('Could not clean up data file because no backup file was found');
      end
    end
    function invalid_input(this, filename, chan_struct)
      % no arguments
      this.verifyWarning(@()pspm_convert_ecg2hb(), 'ID:invalid_input');
      % invalid file
      this.verifyWarning(@()pspm_convert_ecg2hb(1), 'ID:invalid_input');
      % invalid channel (text)
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, 'bla'), 'ID:invalid_input');
      if chan_struct.nr ~= 1
        % invalid channel
        this.verifyWarning(@()pspm_convert_ecg2hb(filename, struct('channel', 1)), 'ID:unexpected_channeltype');
      end
      % invalid twthresh (text)
      o = struct('twthresh', 'bla');
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, o), 'ID:invalid_input');
      % invalid minHR (> default_maxHR)
      o = struct('minHR', 202);
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, o), 'ID:invalid_input');
      % invalid minHR and maxHR (> given maxHR)
      o.maxHR = 19;
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, o), 'ID:invalid_input');
      % invalid maxHR (< default_minHR)
      o = rmfield(o, 'minHR');
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, o), 'ID:invalid_input');
      % invalid debugmode (not in [0,1])
      o = struct('debugmode', 5);
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, o), 'ID:invalid_input');
      % invalid semi (not in [0,1])
      o = struct('semi', 5);
      this.verifyWarning(@()pspm_convert_ecg2hb(filename, o), 'ID:invalid_input');
    end
    function valid_input(this, filename, chan_struct, num_channels)
        % call function and vary arguments
        options = this.options;
        options.channel = chan_struct.nr;
        this.verifyWarningFree(@()pspm_convert_ecg2hb(filename, options));
        options.channel = chan_struct.name;
        this.verifyWarningFree(@()pspm_convert_ecg2hb(filename, options));
        % test added data
        this.verifyWarningFree(@()this.test_added_data(filename, num_channels));
    end
  end
  methods(TestClassTeardown)
    function cleanup_all(this)
      for i=1:length(this.testdata)
        filename = this.testdata{i}.filename;
        backup_name = this.testdata{i}.backup_name;
        this.cleanup_backup(filename, backup_name)
      end
    end
  end
  methods(Test)
    function invalid_input_all(this)
      for i=1:length(this.testdata)
        filename = this.testdata{i}.filename;
        chan_struct = this.testdata{i}.chan_struct;
        this.invalid_input(filename, chan_struct);
      end
    end
    function valid_input_all(this)
      for i=1:length(this.testdata)
        filename = this.testdata{i}.filename;
        chan_struct = this.testdata{i}.chan_struct;
        num_channels = this.testdata{i}.num_channels;
        this.valid_input(filename, chan_struct, num_channels);
      end
    end
  end
end
function max_num = max_beats_in_k_seconds(seconds, k)
max_num = 0;
for i=1:length(seconds)
  for j=i+1:length(seconds)
    if seconds(j) - seconds(i) > k
      max_num = max(max_num, j - i);
      break
    end
  end
end
end
