classdef pspm_load_data_ui_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for userinteraction parts for the pspm_load_data function
  % ● Authorship
  % (C) 2013 Linus Rüttimann (University of Zurich)
  properties(Constant)
    fn = 'testfile_load_data_ui.mat';
  end
  properties
    event_channels;
    pspm_channels;
  end
  methods (TestClassSetup)
    function gen_testdata(testCase)
      channels{1}.chantype = 'scr';
      channels{2}.chantype = 'marker';
      channels{3}.chantype = 'hr';
      channels{4}.chantype = 'hb';
      channels{5}.chantype = 'marker';
      channels{6}.chantype = 'resp';
      channels{7}.chantype = 'scr';
      testCase.event_channels = [2 4 5];
      testCase.pspm_channels = [1 7];
      if exist(pspm_load_data_test.fn, 'file')
        delete(pspm_load_data_test.fn);
      end
      pspm_testdata_gen(channels,10,scr_load_data_test.fn);
      if ~exist(pspm_load_data_test.fn, 'file')
      warning('the testdata could not be generated')
      end
    end
  end
  methods (TestClassTeardown)
    function del_testdata_file(testCase)
      if exist(pspm_load_data_test.fn, 'file')
        delete(pspm_load_data_test.fn);
      end
    end
  end
  methods (Test)
    % overwrite option
    function overwrite_option_test(testCase)
      fn2 = 'testdata_load_data_ui.mat';
      chan = 0;
      [sts, infos, data] = pspm_load_data(scr_load_data_test.fn, chan); % load
      save.data = data;
      save.infos = infos;
      if exist(fn2), delete(fn2); end
      sts = pspm_load_data(fn2, save);
    end
  end
end
