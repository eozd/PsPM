classdef pspm_check_data_test < matlab.unittest.TestCase
% ● Description
%   unittest class for pspm_check_data, PsPM TestEnvironment
% ● History
%   Written in 2024 by Bernhard Agoué von Raußendorf
% ● Developer's notes



methods (Test)
    function testValidDataTest(testCase)
        % Test pspm_check_data with valid data and infos structures.

        % Generate valid test data
        duration = 10; % seconds
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; % sampling rate
        channels{1}.units = 'microsiemens'; 
        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        [sts, dataOut] = pspm_check_data(data, infos);

        testCase.verifyEqual(sts, 1);
        testCase.verifyNotEmpty(dataOut);
    end
    function channeltype2chantypeTest(testCase)
        % Test pspm_check_data  channeltype to chantype

        % Generate valid test data
        duration = 10; 
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; % sampling rate
        channels{1}.units = 'microsiemens'; 
        dataStruct = pspm_testdata_gen(channels, duration);
       
        % change chantype to channeltype
        dataStruct.data{1, 1}.header.channeltype = dataStruct.data{1, 1}.header.chantype;
        dataStruct.data{1, 1}.header = rmfield(dataStruct.data{1, 1}.header, 'chantype');
        
        data  = dataStruct.data;    
        infos = dataStruct.infos;

        [~ , dataOut] = pspm_check_data(data, infos);

        %dataOut{1, 1}.header
        testCase.verifyTrue(isfield(dataOut{1, 1}.header,"chantype"))
    end
    function MissingHeaderFieldsTest(testCase)
        % Test pspm_check_data with missing required fields in the header.

        % Generate valid test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        % Remove the 'chantype' field from the header
        data{1}.header = rmfield(data{1}.header, 'chantype');

        [sts, dataOut] = pspm_check_data(data, infos);

        % Verify that the status indicates an error (-1)
        testCase.verifyEqual(sts, -1);
        % Optionally, verify that an appropriate warning was issued
        % (requires capturing warnings)
    end
    function UnknownChannelTypeTest(testCase)
        % Test pspm_check_data with an unknown channel type.

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; 
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        dataStruct.data{1, 1}.header.chantype = 'unknow channeltype';
       
        data = dataStruct.data;
        infos = dataStruct.infos;

        [sts, ~ ] = pspm_check_data(data, infos);
      
        
        testCase.verifyEqual(sts, -1); % maybe check over warrning ID?
    end
    function EmptyDataTest(testCase)
        % Test pspm_check_data with empty data field.

        % Generate valid test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; 
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        data{1,1}.data = [];

        [sts, dataOut] = pspm_check_data(data, infos);

        testCase.verifyEqual(sts, -1);  % maybe check over warrning ID?
    end
    function IncorrectDataOrientationTest(testCase)
        % Test pspm_check_data with data in incorrect orientation.

        % Generate valid test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; 
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        % Data converted into a row vector 
        data{1}.data = data{1}.data';

        [sts, dataOut] = pspm_check_data(data, infos);

        % Verify pspm_check_data transposed the data back and sts remains 1
        testCase.verifyEqual(size(dataOut{1}.data, 1), length(data{1}.data));
        testCase.verifyEqual(size(dataOut{1}.data, 2), 1);
        testCase.verifyEqual(sts, 1);
    end
    function DataOutOfRangeTest(testCase)
        % Test pspm_check_data with data exceeding infos.duration.
       

        % Generate valid test data
        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100;
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        % Extend the data beyond the expected duration
        extraSamples = 50; % number of extra samples
        data{1}.data = [data{1}.data; zeros(extraSamples, 1)];

        [sts, DataOut ] = pspm_check_data(data, infos);
        
        
        % Data was not changed
        testCase.verifyEqual(size(data{1}.data,1), size(DataOut{1}.data,1)) 
        testCase.verifyEqual(sts, -1);
    end
    function InvalidDataTypesTest(testCase)
        % Test pspm_check_data with invalid data types in the data field.

        duration = 10; 
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; 
        channels{1}.units = 'microsiemens';
        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        % Set data field to a non-numeric type string
        data{1}.data = 'invalid data';

        [sts, ~] = pspm_check_data(data, infos);
        testCase.verifyEqual(sts, -1);

    end

    function MultipleChannelsTest(testCase)
    % Test pspm_check_data with multiple channels.
    % This checks if the function can handle and process multiple channels correctly.

        duration = 10;
        channels{1}.chantype = 'scr';
        channels{1}.sr = 100; 
        channels{1}.units = 'microsiemens';
        channels{2}.chantype = 'hr';
        channels{2}.sr = 200; 
        channels{2}.units = 'mV'; 

        dataStruct = pspm_testdata_gen(channels, duration);

        data = dataStruct.data;
        infos = dataStruct.infos;

        [sts, dataOut] = pspm_check_data(data, infos);

        % Verify that sts is 1, indicating successful validation of multiple channels
        testCase.verifyEqual(sts, 1);
        % Verify that both channels are present in the output
        testCase.verifyEqual(numel(dataOut), 2);
        % Verify that each channel has the correct sampling rate and units
        testCase.verifyEqual(dataOut{1}.header.sr, 100);
        testCase.verifyEqual(dataOut{1}.header.units, 'microsiemens');
        testCase.verifyEqual(dataOut{2}.header.sr, 200);
        testCase.verifyEqual(dataOut{2}.header.units, 'mV');
    end

end
end
