classdef pspm_gaze_pp_test < pspm_testcase
  % Definition
  % pspm_gaze_pp_test unittest classes for the pspm_gaze_pp function
  % PsPM TestEnvironment
  % (C) 2021 Teddy
  properties
    raw_input_fn = fullfile('ImportTestData', 'eyelink', 'S114_s2.asc');
    pspm_input_fn = '';
  end
  methods(TestClassSetup)
    function backup(this)
      import = {};
      import{end + 1}.type = 'pupil_l';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'pupil_r';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'gaze_x_l';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'gaze_y_l';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'gaze_x_r';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'gaze_y_r';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'marker';
      options = struct();
      options.overwrite = 1; % to always overwrite
      [sts, this.pspm_input_fn] = pspm_import(...
        this.raw_input_fn, 'eyelink', import, options);
    end
  end
  methods(Test)
    function invalid_input(this)
      % the function checks if the input filename and options are valid
      % the input filename is only a number
      this.verifyWarning(@()pspm_gaze_pp(52), 'ID:invalid_input');
      % the input filename refers to a non-existing file
      this.verifyWarning(@()pspm_gaze_pp('abc'), 'ID:nonexistent_file');
      % the input filename is valid, but the channel definition is wrong
      opt.channel = 'scr';
      this.verifyWarning(@()pspm_gaze_pp(this.pspm_input_fn, opt), 'ID:invalid_input');
      % the input filename is valid, but there are only 3 channels
      opt.channel = 1:3;
      this.verifyWarning(@()pspm_gaze_pp(this.pspm_input_fn, opt), 'ID:invalid_input');
      % the input filename is valid, but the channels are of the wrong type
      opt.channel = 1:4;
      this.verifyWarning(@()pspm_gaze_pp(this.pspm_input_fn, opt), 'ID:unexpected_channeltype');
    end
    function preprocessed_channel(this)
      % check if the channel name of the preprocessed file is correct
      opt.channel = 'gaze';
      [~, out_channel] = this.verifyWarningFree(@() ...
          pspm_gaze_pp(this.pspm_input_fn, opt));
      testdata = load(this.pspm_input_fn);
      this.verifyEqual(testdata.data{out_channel(1)}.header.chantype,'gaze_x_c');
      this.verifyEqual(testdata.data{out_channel(2)}.header.chantype,'gaze_y_c');
      opt.channel = [5,3,6,4];
      [~, out_channel] = this.verifyWarningFree(@() ...
          pspm_gaze_pp(this.pspm_input_fn, opt));
      testdata = load(this.pspm_input_fn);
      this.verifyEqual(testdata.data{out_channel(1)}.header.chantype,'gaze_x_c');
      this.verifyEqual(testdata.data{out_channel(2)}.header.chantype,'gaze_y_c');
    end
  end
  methods(TestClassTeardown)
    function restore(this)
      delete(this.pspm_input_fn);
    end
  end
end
