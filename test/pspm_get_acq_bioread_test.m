classdef pspm_get_acq_bioread_test < pspm_get_superclass
  % ● Description
  % unittest class for the pspm_get_acq_bioread function
  % ● Authorship
  % PsPM TestEnvironment
  % (C) 2016 Tobias Moser (University of Zurich)
  properties
    testcases;
    fhandle = @pspm_get_acq_bioread
  end
  methods
    function define_testcases(this)
      % testcase 1
      this.testcases{1}.pth = 'ImportTestData/acq/Acq_ECG_SCR_Marker_bioread.mat';
      this.testcases{1}.import{1} = struct('type', 'ecg'   , 'channel', 1);
      this.testcases{1}.import{2} = struct('type', 'scr'   , 'channel', 2);
      this.testcases{1}.import{3} = struct('type', 'marker', 'channel', 3);
      % testcase 2 (with channel name search)
      this.testcases{2}.pth = 'ImportTestData/acq/Acq_ECG_SCR_Marker_bioread.mat';
      this.testcases{2}.import{1} = struct('type', 'ecg'   , 'channel', 0);
      this.testcases{2}.import{2} = struct('type', 'scr'   , 'channel', 0);
      this.testcases{2}.import{3} = struct('type', 'marker', 'channel', 0);
      % testcase 3
      this.testcases{3}.pth = 'ImportTestData/acq/calibration2015-12-06T20_22_38_bioread.mat';
      this.testcases{3}.import{1} = struct('type', 'ecg'   , 'channel', 1);
      this.testcases{3}.import{2} = struct('type', 'marker'   , 'channel', 2);
    end
  end
  methods (Test)
    function invalid_datafile(this)
      fn = 'ImportTestData/acq/calibration2015-12-06T20_22_38_bioread.mat';
      import{1} = struct('type', 'scr'   , 'channel', 1);
      import{2} = struct('type', 'marker', 'channel', 2);
      import{2} = struct('type', 'marker', 'channel', 3);
      import = this.assign_chantype_number(import);
      this.verifyWarning(@()pspm_get_acq_bioread(fn, import), 'ID:channel_not_contained_in_file');
    end
  end
end