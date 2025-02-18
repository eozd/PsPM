classdef pspm_time2index_test < matlab.unittest.TestCase
    % Unit tests for the pspm_time2index function

methods (Test)
    function TestBasicTimeConversion(testCase)
        % Verify basic time to index conversion with default parameters

        time = [0, 0.1, 0.2, 0.3, 0.4];
        sr = 10;

        expected_indices = [1, 2, 3, 4, 5];
        index = pspm_time2index(time, sr);

        testCase.verifyEqual(index, expected_indices);
    end
    function TestWithDataLength(testCase)
        % Ensure indices are capped at the specified data length

        time = [0, 0.1, 0.2, 0.3, 0.4, 0.5];
        sr = 10;
        data_length = 4; 

        expected_indices = [1, 2, 3, 4, 4, 4];

        index = pspm_time2index(time, sr, data_length);

        testCase.verifyEqual(index, expected_indices);
    end
    function TestDurationConversion(testCase)
        % Test conversion when is_duration is set to 1

        time = [0.05, 0.15, 0.25];
        sr = 20;
        is_duration = 1;
        data_length = inf;

        expected_indices = [1, 3, 5];

        duration = pspm_time2index(time, sr, data_length, is_duration);

        % Verify the duration in (samples)
        testCase.verifyEqual(duration, expected_indices);
    end
    function TestTimeBeyondDataLength(testCase)
        % Test times that result in indices beyond the data length

        time = [0.2, 0.4, 0.6, 0.8, 1.0];
        sr = 5;
        data_length = 3;

        % Expected indices (capped at data_length)
        expected_indices = [2, 3, 3, 3, 3];

        index = pspm_time2index(time, sr, data_length);

        testCase.verifyEqual(index, expected_indices);
    end
    function TestMatrixInput(testCase)
        % Test function with matrix inputs for time

        time = [0.1, 0.2; 0.3, 0.4];
        sr = 10;

        expected_indices = [2, 3; 4, 5];

        index = pspm_time2index(time, sr);

        testCase.verifyEqual(index, expected_indices);
    end

end
end