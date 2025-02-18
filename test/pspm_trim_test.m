classdef pspm_trim_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_trim_test function
  % testEnvironment for PsPM version 6.0
  % ● Authorship
  % (C) 2013 Linus Rüttimann (University of Zurich)
  %     2022 Teddy Chao
  %     2024 Bernhard von Raußendorf
  
  properties(Constant)
    fn = 'trim_test.mat';
    missing_epochs_fn = 'missing_epochs.mat';  % 
  end
  properties
    numof_markertests = 3;
    numof_filetests = 3;
    numof_numtests = 4;
    event_channels;
    cont_channels;
    sr;
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
      testCase.cont_channels = [1 3 6 7];
      testCase.sr = 100;

       epochs = [2, 4; 6, 8]; % Example missing epochs

      save(testCase.missing_epochs_fn, 'epochs');  % 



      if exist(testCase.fn, 'file')
        delete(testCase.fn);
      end
      pspm_testdata_gen(channels,10,testCase.fn);
      if ~exist(testCase.fn, 'file')
        warning('the testdata could not be generated');
      end
    end
  end
  methods (TestClassTeardown)
    function del_testdata_file(testCase)
      if exist(testCase.fn, 'file')
        delete(testCase.fn);
      end
      if exist(testCase.missing_epochs_fn, 'file')
          delete(testCase.missing_epochs_fn);
      end
    end
  end
  methods (Test)
    %% Missing epochs test
    function missing_epoch_trim_inside_both_test(testCase)
        from = 3;  
        to = 7;     
        reference = 'file';  
        % epochs = [2, 4; 6, 8];
        options.missing = testCase.missing_epochs_fn; % Specify the missing epochs file
        
        
        [sts, newdatafile, newepochfile] = pspm_trim(testCase.fn, from, to, reference, options);
       
        load(newepochfile, 'epochs');

        % Expected result
        expected_epochs = [0, 1; 3, 4];

        
        testCase.verifyEqual(epochs, expected_epochs, 'Missing epochs trimming failed.');


        delete(newdatafile);
        delete(newepochfile);
    end

    function missing_epoch_one_outside_trim_touching_first_one_test(testCase)
        from = 4;
        to = 9;
        reference = 'file';

        % epochs = [2, 4; 6, 8];
        options.missing = testCase.missing_epochs_fn;

        [sts, newdatafile, newepochfile] = pspm_trim(testCase.fn, from, to, reference, options);

        load(newepochfile, 'epochs');

        % Expected result after trimming
        expected_epochs = [2,4]; % not [0, 0 ; 2, 4];

        testCase.verifyEqual(epochs, expected_epochs, 'One missing epoch outside trimmed data failed.');


        delete(newdatafile);
        delete(newepochfile);
    end

    function missing_epoch_one_outside_trim_test(testCase)
        from = 5;
        to = 9;
        reference = 'file';

        % epochs = [2, 4; 6, 8];
        options.missing = testCase.missing_epochs_fn;

        [sts, newdatafile, newepochfile] = pspm_trim(testCase.fn, from, to, reference, options);

        load(newepochfile, 'epochs');

        % Expected result after trimming
        expected_epochs = [1, 3];

        testCase.verifyEqual(epochs, expected_epochs, 'One missing epoch outside trimmed data failed.');


        delete(newdatafile);
        delete(newepochfile);
    end
   
    function missing_epoch_both_inside_trim_test(testCase)
        from = 1;
        to = 9;
        reference = 'file';

        % epochs = [2, 4; 6, 8];
        options.missing = testCase.missing_epochs_fn;

        [sts, newdatafile, newepochfile] = pspm_trim(testCase.fn, from, to, reference, options);

        load(newepochfile, 'epochs');

        % Expected result after trimming
        expected_epochs = [1, 3; 5, 7];

        testCase.verifyEqual(epochs, expected_epochs, 'One missing epoch outside trimmed data failed.');


        delete(newdatafile);
        delete(newepochfile);
    end    

    function missing_epoch_one_to_the_end_test(testCase)
        from = 1;
        to = 3;
        reference = 'file';

        % epochs = [2, 4; 6, 8];
        options.missing = testCase.missing_epochs_fn;

        [sts, newdatafile, newepochfile] = pspm_trim(testCase.fn, from, to, reference, options);

        load(newepochfile, 'epochs');

        % Expected result after trimming
        expected_epochs = [1, 2];

        testCase.verifyEqual(epochs, expected_epochs, 'One missing epoch outside trimmed data failed.');


        delete(newdatafile);
        delete(newepochfile);
    end   
    
    function between_missing_epoch_test2(testCase)
        from = 4;
        to = 6;
        reference = 'file';

        % epochs = [2, 4; 6, 8];
        options.missing = testCase.missing_epochs_fn;

        [sts, newdatafile, newepochfile] = pspm_trim(testCase.fn, from, to, reference, options);

        load(newepochfile, 'epochs');

        % Expected result after trimming
        expected_epochs =  zeros(0,2); % not [0, 0; 2, 2] but  0×2 empty double matrix

        testCase.verifyEqual(epochs, expected_epochs, 'One missing epoch outside trimmed data failed.');


        delete(newdatafile);
        delete(newepochfile);
    end   


    %% Invalid input arguments
    function invalid_inputargs(testCase)
      testCase.verifyWarning(@()pspm_trim(testCase.fn, [1 2], 5, 'marker'),...
        'ID:invalid_input', 'invalid_inputargs test 1');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, 'bla', 'marker'),...
        'ID:invalid_input', 'invalid_inputargs test 2');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, [], 'marker'),...
        'ID:invalid_input', 'invalid_inputargs test 3');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, 5),...
        'ID:invalid_input', 'invalid_inputargs test 4');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, 5, 6),...
        'ID:invalid_input', 'invalid_inputargs test 5');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, 5, 'bla'),...
        'ID:invalid_input', 'invalid_inputargs test 6');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, 5, [-1 5]),...
        'ID:invalid_input', 'invalid_inputargs test 7');
      testCase.verifyWarning(@()pspm_trim(testCase.fn, 0, 5, [5 4]),...
        'ID:invalid_input', 'invalid_inputargs test 8');
    end
    %% Testing 'marker' as reference
    function marker_tests(testCase)
      for k=1:testCase.numof_markertests
        trimtest(testCase, testCase.fn, 'marker', k, 2);
      end
    end
    %% Testing 'file' as reference
    function file_tests(testCase)
      for k=1:testCase.numof_filetests
        trimtest(testCase, testCase.fn, 'file', k, 2);
      end
    end
    %% Numeric reference tests
    function num_tests(testCase)
      for k=1:testCase.numof_numtests
        trimtest(testCase, testCase.fn, 'num', k, 2);
      end
    end
    %% Option tests (marker channel number option)
    function marker_chan_num_option_test(testCase)
      options.marker_chan_num = 3;
      [sts, newdatafile] = testCase.verifyWarning(@() ...
        pspm_trim(testCase.fn,'none','none','marker', options), ...
        'ID:unexpected_channeltype', 'marker_chan_num_option_test test 1');
      delete(newdatafile);
      struct = load(testCase.fn);
      struct.data{5}.data = struct.data{5}.data(2:end);
      save(testCase.fn,'-struct', 'struct');
      options.marker_chan_num = 5;
      [sts, newdatafile] = pspm_trim(testCase.fn,'none','none',[2,length(struct.data{2}.data)]);
      [~, exp_val.infos, exp_val.data] = pspm_load_data(newdatafile, 0);
      delete(newdatafile);
      [sts, newdatafile] = pspm_trim(testCase.fn,'none','none', 'marker', options);
      [~, act_val.infos, act_val.data] = pspm_load_data(newdatafile, 0);
      delete(newdatafile);
      import matlab.unittest.constraints.IsEqualTo;
      testCase.verifyThat(act_val, IsEqualTo(exp_val), 'marker_chan_num_option_test test 2');
    end
  end
  methods
    function trimtest(testCase, datafile, reference, testnum, markerchan)
      switch reference
        case 'marker'
          fhandle = str2func(['markertest_' num2str(testnum)]);
          [from, to, exp_val, warningID, testmsg] = feval(fhandle, testCase, markerchan);
        case 'file'
          fhandle = str2func(['filetest_' num2str(testnum)]);
          [from, to, exp_val, warningID, testmsg] = feval(fhandle, testCase);
        case 'num'
          fhandle = str2func(['numtest_' num2str(testnum)]);
          [from, to, exp_val, warningID, testmsg, num] = feval(fhandle, testCase);
          reference = num;
      end
      if strcmpi(warningID, 'none')
        [sts, newdatafile]=pspm_trim(datafile, from, to, reference);
      else
        [sts, newdatafile] = testCase.verifyWarning(@()...
          pspm_trim(datafile, from, to, reference),...
          warningID, [testmsg ' (invalid warning)']);
      end
      [~, act_val.infos, act_val.data] = pspm_load_data(newdatafile,0);
      exp_val.infos.trimdate = date;
      exp_val.infos.trimfile = newdatafile;
      import matlab.unittest.constraints.IsEqualTo;
      testCase.verifyThat(act_val, IsEqualTo(exp_val), testmsg);
      delete(newdatafile);
    end
    %% marker/file/num-testcases
    % REMARK: the properties numof_markertests, numof_filetests and
    %         numof_numtests must be updated if testcases are being
    %         added.
    % reference = 'marker' tests
    function [from, to, exp_val, warningID, testmsg] = markertest_1(testCase, markerchan)
      testmsg = 'markertest 1';
      warningID = 'ID:marker_out_of_range';
      [~, exp_val.infos, exp_val.data] = pspm_load_data(testCase.fn,0);
      from = -20;
      to = 20;
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
    end
    function [from, to, exp_val, warningID, testmsg] = markertest_2(testCase, markerchan)
      testmsg = 'markertest 2';
      warningID = 'none';
      [~, exp_val.infos, exp_val.data, filestruct] = pspm_load_data(testCase.fn,0);
      from = -1 * exp_val.data{filestruct.posofmarker}.data(1);
      to = exp_val.infos.duration - exp_val.data{filestruct.posofmarker}.data(end);
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
    end
    function [from, to, exp_val, warningID, testmsg] = markertest_3(testCase, markerchan)
      testmsg = 'markertest 3';
      warningID = 'none';
      [~, exp_val.infos, exp_val.data, filestruct] = pspm_load_data(testCase.fn,0);
      from = 1;
      to = -2;
      nfrom = exp_val.data{filestruct.posofmarker}.data(1)+from;
      nto = exp_val.data{filestruct.posofmarker}.data(end)+to;
      startpoint = ceil(testCase.sr * nfrom)+1;
      endpoint = floor(testCase.sr * nto);
      for k = 1:length(testCase.cont_channels)
        exp_val.data{testCase.cont_channels(k)}.data = ...
          exp_val.data{testCase.cont_channels(k)}.data(startpoint:endpoint);
      end
      for k = 1:length(testCase.event_channels)
        exp_val.data{testCase.event_channels(k)}.data(exp_val.data{testCase.event_channels(k)}.data > nto) = [];
        exp_val.data{testCase.event_channels(k)}.data = exp_val.data{testCase.event_channels(k)}.data - nfrom;
        exp_val.data{testCase.event_channels(k)}.data(exp_val.data{testCase.event_channels(k)}.data < 0) = [];
      end
      exp_val.infos.trimpoints = [nfrom nto];
      exp_val.infos.duration = nto - nfrom;
    end

    function [from, to, exp_val, warningID, testmsg] = filetest_1(testCase)
      % reference = 'file' tests
      testmsg = 'filetest 1';
      warningID = 'ID:marker_out_of_range';
      [~, exp_val.infos, exp_val.data] = pspm_load_data(testCase.fn,0);
      from = -12.5;
      to = 50;
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
    end
    function [from, to, exp_val, warningID, testmsg] = filetest_2(testCase)
      testmsg = 'filetest 2';
      warningID = 'none';
      [~, exp_val.infos, exp_val.data] = pspm_load_data(testCase.fn,0);
      from = 0;
      to = exp_val.infos.duration;
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
    end
    function [from, to, exp_val, warningID, testmsg] = filetest_3(testCase)
      testmsg = 'filetest 3';
      warningID = 'none';
      [~, exp_val.infos, exp_val.data] = pspm_load_data(testCase.fn,0);
      from = 2.1;
      to = exp_val.infos.duration - 2.5;
      startpoint = ceil(testCase.sr * from)+1;
      endpoint = floor(testCase.sr * to);
      for k=1:length(testCase.cont_channels)
        exp_val.data{testCase.cont_channels(k)}.data = ...
          exp_val.data{testCase.cont_channels(k)}.data(startpoint:endpoint);
      end
      for k=1:length(testCase.event_channels)
        exp_val.data{testCase.event_channels(k)}.data(exp_val.data{testCase.event_channels(k)}.data > to) = [];
        exp_val.data{testCase.event_channels(k)}.data = exp_val.data{testCase.event_channels(k)}.data - from;
        exp_val.data{testCase.event_channels(k)}.data(exp_val.data{testCase.event_channels(k)}.data < 0) = [];
      end
      exp_val.infos.trimpoints = [from to];
      exp_val.infos.duration = to - from;
    end
    function [from, to, exp_val, warningID, testmsg, num] = numtest_1(testCase)
      % reference = [a b] (numeric) tests
      testmsg = 'numtest 1';
      warningID = 'ID:marker_out_of_range';
      [~, exp_val.infos, exp_val.data] = pspm_load_data(testCase.fn,0);
      from = -20;
      to = 20;
      num = [2 14];
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
    end
    function [from, to, exp_val, warningID, testmsg, num] = numtest_2(testCase)
      testmsg = 'numtest 2';
      warningID = 'none';
      [~, exp_val.infos, exp_val.data, filestruct] = pspm_load_data(testCase.fn,0);
      num = [3 8];
      from = -1 * exp_val.data{filestruct.posofmarker}.data(num(1));
      to = exp_val.infos.duration - exp_val.data{filestruct.posofmarker}.data(num(2));
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
    end
    function [from, to, exp_val, warningID, testmsg, num] = numtest_3(testCase)
      testmsg = 'numtest 3';
      warningID = 'none';
      [~, exp_val.infos, exp_val.data, filestruct] = pspm_load_data(testCase.fn,0);
      num = [2 7];
      from = -1.5;
      to = 2;
      nfrom = exp_val.data{filestruct.posofmarker}.data(num(1))+from;
      nto = exp_val.data{filestruct.posofmarker}.data(num(2))+to;
      startpoint = ceil(testCase.sr * nfrom)+1;
      endpoint = floor(testCase.sr * nto);
      for k = 1:length(testCase.cont_channels)
        exp_val.data{testCase.cont_channels(k)}.data = ...
          exp_val.data{testCase.cont_channels(k)}.data(startpoint:endpoint);
      end
      for k=1:length(testCase.event_channels)
        exp_val.data{testCase.event_channels(k)}.data(exp_val.data{testCase.event_channels(k)}.data > nto) = [];
        exp_val.data{testCase.event_channels(k)}.data = exp_val.data{testCase.event_channels(k)}.data - nfrom;
        exp_val.data{testCase.event_channels(k)}.data(exp_val.data{testCase.event_channels(k)}.data < 0) = [];
      end
      exp_val.infos.trimpoints = [nfrom nto];
      exp_val.infos.duration = nto - nfrom;
    end
    function [from, to, exp_val, warningID, testmsg, num] = numtest_4(testCase)
      testmsg = 'numtest 4';
      warningID = 'ID:marker_out_of_range';
      [~, exp_val.infos, exp_val.data, filestruct] = pspm_load_data(testCase.fn,0);
      from = 'none';
      to = 0;
      exp_val.infos.trimpoints = [0 exp_val.infos.duration];
      num = [1 (numel(exp_val.data{filestruct.posofmarker}.data) + 1)];
    end
  end
end