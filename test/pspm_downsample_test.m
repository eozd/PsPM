classdef pspm_downsample_test < matlab.unittest.TestCase
% Unit test class for the pspm_downsample function
% ● Authorship
% (C) 2024 Bernhard Agoué von Raußendorf
%
% 

properties
    OriginalSignalSetting % Property to store the original settings.signal value
end

methods (TestMethodSetup)
    function saveSettings(testCase)
        global settings
        
        if isempty(settings)
          pspm_init;
        end
        % Store the original settings.signal value in the property
        if isfield(settings, 'signal')
            testCase.OriginalSignalSetting = settings.signal;
        else
            % Save as empty if it doesn't exist 
            testCase.OriginalSignalSetting = []; 
            warrning("Problem with settings.signal")
        end
    end
end

methods (TestMethodTeardown)
    function loadOriginalSettings(testCase)
        global settings;
        % Restore the original settings.signal value
        if isempty(testCase.OriginalSignalSetting)
            if isfield(settings, 'signal')
                settings = rmfield(settings, 'signal'); % Remove field if it didn’t originally exist
            end
        else
            settings.signal = testCase.OriginalSignalSetting; % Restore original value
        end
    end
end




methods (Test)
    function testIntegerFrequencyRatio(testCase)
        % Test case for integer frequency ratio downsampling

        sr = 1000;               % Original sampling rate
        sr_down = 500;           % Target sampling rate
        duration = 1;            % Signal duration (in seconds)
        t = 0:1/sr:duration-1/sr; % Time vector
        data = sin(2 * pi * 5 * t); % Sample sine wave signal

        
        expectedData = resample(data, sr_down, sr);


        % Perform downsampling
        [sts, actualData] = pspm_downsample(data, sr, sr_down);

        % Verify output
        testCase.verifyEqual(sts, 1, 'Status should be 1 for integer frequency ratio.');
        testCase.verifyEqual(actualData, expectedData, 'Downsampled data does not match expected data.');
    end

    function testNonIntegerFrequencyRatioWithSignalProcessing(testCase)
        % Test case for non-integer frequency ratio downsampling with signal processing available

        global settings
        settings.signal = true;   % Can I do that like this?
        sr = 1000;                % Original sampling rate
        sr_down = 333;            % Target sampling rate (non-integer ratio)
        duration = 1;             %  (in seconds)
        t = 0:1/sr:duration-1/sr;  % Time vector
        data = sin(2 * pi * 5 * t); % Sample sine wave signal

        % Expected downsampling result using MATLAB's resample function
        expectedData = resample(data, sr_down, sr);

        % Perform downsampling
        [sts, actualData] = pspm_downsample(data, sr, sr_down);

        % Verify output
        testCase.verifyEqual(sts, 1);
        testCase.verifyEqual(actualData,expectedData)

    end

    function testNonIntegerFrequencyRatioWithoutSignalProcessing(testCase)
        % Test case for non-integer frequency ratio downsampling without signal processing
        global settings;
        settings.signal = false; % Signal processing not available
        sr = 1000;               % Original sampling rate
        sr_down = 333;           % Target sampling rate (non-integer ratio)
        duration = 1;            % Signal duration (in seconds)
        t = 0:1/sr:duration-1/sr; % Time vector
        data = sin(2 * pi * 5 * t); % Sample sine wave signal

        % Perform downsampling
        [sts, actualData] = pspm_downsample(data, sr, sr_down);

        % Verify output
        testCase.verifyEqual(sts, -1);
        testCase.verifyEqual(actualData,data)
    end
    function testIntegerFrequencyRatioWithoutSignalProcessing(testCase)
        % Test case for non-integer frequency ratio downsampling without signal processing
        global settings;
        settings.signal = false; % Signal processing not available
        sr = 1000;               % Original sampling rate
        sr_down = 500;           % Target sampling rate (non-integer ratio)
        duration = 1;            % Signal duration (in seconds)
        t = 0:1/sr:duration-1/sr; % Time vector
        data = sin(2 * pi * 5 * t); % Sample sine wave signal

        % Expected frequency ratio and downsampled data
        freqratio = sr / sr_down;
        expectedData = data(freqratio:freqratio:end);

        % Perform downsampling
        [sts, actualData] = pspm_downsample(data, sr, sr_down);

        % Verify output
        testCase.verifyEqual(sts, 1);
        testCase.verifyEqual(actualData,expectedData) 
    end


end
end
