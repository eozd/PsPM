classdef pspm_load_channel_test < matlab.unittest.TestCase
% ● Description
%   unittest class for pspm_load_channel, PsPM TestEnvironment
% ● History
%   Written in 2024 by Bernhard Agoué von Raußendorf
% ● Developer's notes

% pspm_load_channel_test overwrite if file already exist or clean up??

methods (Test)

    function TestValidNumericChannel(testCase)
        % Test loading a channel by valid numeric index

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.sr = 200;
        channels{2}.units = 'bpm';
        dataStruct = pspm_testdata_gen(channels, duration);

        fn = 'temp_test.mat';
        save(fn, '-struct', 'dataStruct');

        % Load channel by numeric index
        [sts, data_struct, infos, pos_of_channel] = pspm_load_channel(fn, 2);

        % Verifing
        testCase.verifyEqual(sts, 1);
        testCase.verifyEqual(pos_of_channel, 2);
        testCase.verifyEqual(data_struct.header.chantype, 'hr');

        % Clean up
        delete([fn]);
    end
    function TestValidChannelType(testCase)
        % Test loading a channel by channel type string

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.sr = 200;
        channels{2}.units = 'bpm';
        dataStruct = pspm_testdata_gen(channels, duration);

        fn = 'temp_test2.mat';
        save(fn, '-struct', 'dataStruct');

        % Load channel by channel type
        [sts, data_struct, infos, pos_of_channel] = pspm_load_channel(fn, 'hr');
        
        % Verify the status
        testCase.verifyEqual(sts, 1);
        testCase.verifyEqual(data_struct.header.chantype, 'hr');

        % Clean up
        delete([fn ]);
    end
    function TestChannelWithUnits(testCase)
        % Test loading a channel specifying both channel type and units

        % Create test data with specific units
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'scr';
        channels{2}.sr = 100;
        channels{2}.units = 'unknown';
        dataStruct = pspm_testdata_gen(channels, duration);

        % Save dataStruct to a temporary file
        fn = 'temp_test.mat';
        save(fn, '-struct', 'dataStruct');

        % Define channel as struct with units
        channel.channel = 'scr';
        channel.units = 'microsiemens';

        % Load channel
        [sts, data_struct, infos, pos_of_channel] = pspm_load_channel(fn, channel);

        % Verify the status
        testCase.verifyEqual(sts, 1);
        % Verify the correct channel is loaded
        testCase.verifyEqual(data_struct.header.units, 'microsiemens');

        % Clean up
        delete([fn]);
    end
    function TestInvalidChannelNumberError(testCase)
        % Test error handling when an invalid channel number is provided

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        dataStruct = pspm_testdata_gen(channels, duration);

        % Save dataStruct to a temporary file
        fn = 'temp.mat';
        save(fn, '-struct', 'dataStruct');

        % Attempt to load a non-existent channel
        [sts, ~ , ~ , ~ ] = pspm_load_channel(fn, 5);

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);

        % Clean up
        delete([fn]);
    end
    function TestInvalidChannelTypeError(testCase)
        % Test error handling when an invalid channel type is provided

        duration = 10;
        channels{1}.chantype = 'scr';
        dataStruct = pspm_testdata_gen(channels, duration);

        fn =  'temp.mat';
        save(fn, '-struct', 'dataStruct');

        [sts, ~, ~, ~] = pspm_load_channel(fn, 'invalid_type');

        testCase.verifyEqual(sts, -1);
        delete([fn]);

    end


    function TestMultipleChannels(testCase)
        % Test loading when multiple channels of the same type exist

        % Create test data with multiple 'scr' channels
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'scr';
        channels{2}.sr = 100;
        channels{2}.units = 'microsiemens';
        channels{3}.chantype = 'scr';
        channels{3}.sr = 100;
        channels{3}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        fn = 'temp.mat';
        save(fn, '-struct', 'dataStruct');

        [sts, data_struct, infos, pos_of_channel] = pspm_load_channel(fn, 'scr');

        % Verify the status
        testCase.verifyEqual(sts, 1);
        testCase.verifyEqual(pos_of_channel, 3);

        % Clean up
        delete([fn]);
    end
    function TestNoChannelsAvailableError(testCase)
        % Test behavior when no channels are available in the data

        dataStruct.infos.duration = 10;
        dataStruct.infos.durationinfo = 'Duration in seconds';
        dataStruct.data = {};

        % Save dataStruct to a temporary file
        fn = 'temp.mat';
        save(fn, '-struct', 'dataStruct');

        [sts, ~, ~, ~] = pspm_load_channel(fn, 1);

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);

        % Clean up
        delete([fn]);
    end

    function TestUnitsMismatchError(testCase)
        % Test behavior when units do not match any channel

        % Create test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        % Save dataStruct to a temporary file
        fn = 'temp.mat';
        save(fn, '-struct', 'dataStruct');

        % Define channel with units that do not match
        channel.channel = 'scr';
        channel.units = 'unknown_units';

        % Attempt to load the channel
        [sts, ~, ~, ~] = pspm_load_channel(fn, channel);

        % Verify the status indicates failure
        testCase.verifyEqual(sts, -1);

        % Clean up
        delete([fn '.mat']);
    end

end
end
