classdef pspm_down_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_down function
  % ● Authorship
  % (C) 2015 Tobias Moser (University of Zurich)
  properties(Constant)
    fn = 'testdatafile89887.mat';
    newsr = 99;
    oldsr = 100;
    wave_channels = {'scr','resp','hr'}
  end
  methods(TestClassSetup)
    function generate_test_data(this)
      channels{1}.chantype = 'scr';
      channels{1}.sr = pspm_down_test.oldsr;
      channels{2}.chantype = 'marker';
      channels{2}.sr = pspm_down_test.oldsr;
      channels{3}.chantype = 'hr';
      channels{3}.sr = pspm_down_test.oldsr;
      channels{4}.chantype = 'hb';
      channels{4}.sr = pspm_down_test.oldsr;
      channels{5}.chantype = 'marker';
      channels{5}.sr = pspm_down_test.oldsr;
      channels{6}.chantype = 'resp';
      channels{6}.sr = pspm_down_test.oldsr;
      channels{7}.chantype = 'scr';
      channels{7}.sr = pspm_down_test.oldsr;
      if exist(pspm_down_test.fn, 'file')
        delete(pspm_down_test.fn);
      end
      pspm_testdata_gen(channels, 10, scr_down_test.fn);
      if ~exist(pspm_down_test.fn, 'file'), warning('the testdata could not be generated'), end
    end
  end
  methods (TestClassTeardown)
    function delete_test_data(this)
      if exist(pspm_down_test.fn, 'file')
        delete(pspm_down_test.fn);
      end
      if exist(['d',pspm_down_test.fn], 'file')
        delete(['d',pspm_down_test.fn]);
      end
    end
  end
  methods(Test)
    function invalid_input(this)
      % no arguments
      this.verifyWarning(@()pspm_down(), 'ID:invalid_input');
      % only datafile
      this.verifyWarning(@()pspm_down(scr_down_test.fn), 'ID:invalid_input');
      % wrong datafile
      this.verifyWarning(@()pspm_down('nonexistent_file', 10), 'ID:nonexistent_file');
      % < 10 Hz
      this.verifyWarning(@()pspm_down('nonexistent_file', 9), 'ID:rate_below_minimum');
      % invalid chan argument
      this.verifyWarning(@()pspm_down(scr_down_test.fn, 10, 'invalid_test'), 'ID:invalid_input');
      this.verifyWarning(@()pspm_down(scr_down_test.fn, 10, -1), 'ID:invalid_input');
      % invalid options should not issue any warning
      this.verifyWarning(@()pspm_down(scr_down_test.fn, 10, 0, NaN), 'ID:invalid_input');
    end
    function valid_input(this)
      [sts,newfile] = this.verifyWarningFree(@()pspm_down(scr_down_test.fn, scr_down_test.newsr, 0));
      [old.sts, old.infos, old.data, old.filestruct] = pspm_load_data(scr_down_test.fn);
      [new.sts, new.infos, new.data, new.filestruct] = pspm_load_data(newfile);
      this.verifyEqual(old.sts, 1);
      this.verifyEqual(new.sts, 1);
      this.verifyEqual(numel(old.data),numel(new.data));
      for i = 1:numel(old.data)
        % check if channel has been downsampled (if is wavechannel)
        if ismember(old.data{i}.header.chantype, pspm_down_test.wave_channels)
          % same duration as in old channel
          dur_old = numel(old.data{i}.data) / old.data{i}.header.sr;
          dur_new = numel(new.data{i}.data) / new.data{i}.header.sr;
          this.verifyEqual(dur_old, dur_new);
          % samplerate equals to newsr
          this.verifyEqual(new.data{i}.header.sr, pspm_down_test.newsr);
        end
      end
    end
  end
end