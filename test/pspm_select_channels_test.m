classdef pspm_select_channels_test < matlab.unittest.TestCase
    % Unit tests for the pspm_select_channels function

methods (Test)
    function TestNumericChannelSelection(testCase)
        % Test selecting channels using numeric indices

        % Create test data with multiple channels
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.units = 'bpm';
        channels{3}.chantype = 'resp';
        channels{3}.units = 'arbitrary';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Select channels 1 and 3
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 2);

        % Verify the status
        testCase.verifyEqual(sts, 1);
        % Verify that the correct channel nad units are selected
        testCase.verifyEqual(pos_of_channels, 2);
        testCase.verifyEqual(selected_data{1}.header.chantype, 'hr');
        testCase.verifyEqual(selected_data{1}.header.units, 'bpm');

    end
    function TestNumericChannelSelectionVector(testCase)
        % Test selecting channels using numeric indices

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.units = 'bpm';
        channels{3}.chantype = 'resp';
        channels{3}.units = 'arbitrary';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Select channels 1 and 3
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, [1, 3]);

        % Verify the status
        testCase.verifyEqual(sts, 1);
        % Verify that the correct channels are selected
        testCase.verifyEqual(pos_of_channels, [1, 3]);
        testCase.verifyEqual(selected_data{1}.header.chantype, 'scr');
        testCase.verifyEqual(selected_data{2}.header.chantype, 'resp');
    end
    function TestValidChannelType(testCase)
        % Test selecting channels by specifying a valid channel type

        % Create test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{2}.chantype = 'scr';
        channels{3}.chantype = 'hr';
        channels{4}.chantype = 'hr';
        channels{5}.chantype = 'hr';
        % Units unkown
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Select 'scr' channels
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 'scr');

        % Verify the status
        testCase.verifyEqual(sts, 1);
        % Verify that both 'scr' channels are selected
        testCase.verifyEqual(numel(selected_data), 2);
        testCase.verifyEqual(selected_data{1}.header.chantype, 'scr');
        testCase.verifyEqual(selected_data{2}.header.chantype, 'scr');
    end
    function TestChannelWithUnits(testCase)
        % Test selecting channels by specifying channel type and units

        % Create test data with specific units
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'scr';
        channels{2}.units = 'unknown';
        channels{3}.chantype = 'hr';
        channels{3}.units = 'bpm';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Select 'scr' channels with units 'microsiemens'
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 'scr', 'microsiemens');

        % Verify the status
        testCase.verifyEqual(sts, 1);
        % Verify that only the correct channel is selected
        testCase.verifyEqual(numel(selected_data), 1);
        testCase.verifyEqual(selected_data{1}.header.units, 'microsiemens');
    end
    function TestNumericChannelSelectionError(testCase)
        % Test handling of invalid channel numbers

        % Create test data with two channels
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{2}.chantype = 'hr';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Attempt to select a non-existent channel number
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 5);

        testCase.verifyEqual(sts, -1);
        % All the data will be selected
        testCase.verifyEqual(numel(data), numel(selected_data));
        testCase.verifyEqual(5,pos_of_channels )
        
    end
    function TestNumericChannelSelectionVectorOneValedOneInvaledError(testCase)
        % Test handling of one valid and one invalid channel numbers
        % (vector)

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.units = 'bpm';
        channels{3}.chantype = 'resp';
        channels{3}.units = 'arbitrary';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        selction = [1,5];
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, selction);

        testCase.verifyEqual(sts, -1);
        % All the data will passed through!
        testCase.verifyEqual(numel(data), numel(selected_data));
        testCase.verifyEqual(selction,pos_of_channels )
        
    end
    function TestNumericChannelSelectionVectorMultipleInvaledError(testCase)
        % Test handling of invalid channel numbers

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.units = 'bpm';
        channels{3}.chantype = 'resp';
        channels{3}.units = 'arbitrary';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        selction = [5,6,9];
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, selction);

        testCase.verifyEqual(sts, -1);
        % All the data will passed through!
        testCase.verifyEqual(numel(data), numel(selected_data));
        testCase.verifyEqual(selction,pos_of_channels )
        
    end
    function TestInvalidChannelTypeError(testCase)
        % Test handling of invalid channel type

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{2}.chantype = 'hr';
        channels{3}.chantype = 'hr';

        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Attempt to select an invalid channel type
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 'invalid_type');

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);
        % All the data will be selected
        testCase.verifyEqual(numel(data), numel(selected_data));
        % No channel selected
        testCase.verifyFalse(any(pos_of_channels))

    end
    function TestNoMatchingChannelsError(testCase)
        % Test behavior when no channels match the criteria

        % Create test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{2}.chantype = 'scr';
        channels{3}.chantype = 'scr';
        channels{4}.chantype = 'scr';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Attempt to select a channel type that doesn't exist
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 'hr');

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);
        % All the data will be selected
        testCase.verifyEqual(numel(data), numel(selected_data));
        % No channel selected
        testCase.verifyFalse(any(pos_of_channels))
    end
    function TestUnitsMismatchError(testCase)
        % Test behavior when units do not match any channel

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Attempt to select 'scr' channels with units 'unknown'
        [sts, selected_data, pos_of_channels] = pspm_select_channels(data, 'scr', 'unknown');

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);
        % All the data will be selected
        testCase.verifyEqual(numel(data), numel(selected_data));
        % No channel selected
        testCase.verifyFalse(any(pos_of_channels))
    end
    function TestNegativeChannelNumberError(testCase)
        % Test handling of negative channel numbers

        % Create test data
        duration = 10;
        channels{1}.chantype = 'scr';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        % Attempt to select a negative channel number
        [sts,selected_data, pos_of_channels] = pspm_select_channels(data, -1);

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);
        % All the data will be selected
        testCase.verifyEqual(numel(data), numel(selected_data));
        % No channel selected
        testCase.verifyFalse(any(pos_of_channels))
    end
    function TestNegativeChannelNumberVectorError(testCase)
        % Test handling of negative channel numbers

        % Create test data
        duration = 10;
        channels{1}.chantype = 'scr';
        dataStruct = pspm_testdata_gen(channels, duration);
        data = dataStruct.data;

        selction = [-21,-2,-3];
        [sts,selected_data, pos_of_channels] = pspm_select_channels(data, selction);

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);

     
    end


end
end
