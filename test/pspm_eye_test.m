classdef pspm_eye_test < matlab.unittest.TestCase
    % Unit tests for the pspm_eye function

    methods (Test)
        
        function test_lr2c_char(testCase)
            % Test 'lr2c' feature with character inputs

            % Test inputs
            input1 = 'l';
            input2 = 'R';
            input3 = 'lr';
            input4 = 'rL';
            
            % Expected outputs
            expected1 = 'l';
            expected2 = 'r';
            expected3 = 'c';
            expected4 = 'c';
            
            % Verify conversions
            testCase.verifyEqual(pspm_eye(input1, 'lr2c'), expected1);
            testCase.verifyEqual(pspm_eye(input2, 'lr2c'), expected2);
            testCase.verifyEqual(pspm_eye(input3, 'lr2c'), expected3);
            testCase.verifyEqual(pspm_eye(input4, 'lr2c'), expected4);
        end

        function test_lr2c_cell(testCase)
            % Test 'lr2c' feature with cell array inputs

            % Test input
            input = {'L', 'r', 'Lr', 'rl'};
            % Expected output
            expected = {'l', 'r', 'c', 'c'};
            
            % Verify conversion
            result = pspm_eye(input, 'lr2c');
            testCase.verifyEqual(result, expected);
        end
        
        function test_char2cell_single(testCase)
            % Test 'char2cell' feature with single character inputs

            % Test inputs
            input1 = 'l';
            input2 = 'R';
            input3 = 'C';
            input4 = 'lR';  

            % Expected outputs
            expected1 = {'l'};
            expected2 = {'r'};
            expected3 = {'l', 'r'};
            expected4 = {'l', 'r'};

            
            % Verify conversions
            testCase.verifyEqual(pspm_eye(input1, 'char2cell'), expected1);
            testCase.verifyEqual(pspm_eye(input2, 'char2cell'), expected2);
            testCase.verifyEqual(pspm_eye(input3, 'char2cell'), expected3);
            testCase.verifyEqual(pspm_eye(input4, 'char2cell'), expected4);
        end
        
        function test_char2cell_combined(testCase)
            % Test 'char2cell' feature with combined characters
            
            % Test inputs
            input1 = 'lr';
            input2 = 'RL';

            % Expected output
            expected = {'l', 'r'};

            % Verify conversions
            testCase.verifyEqual(pspm_eye(input1, 'char2cell'), expected);
            testCase.verifyEqual(pspm_eye(input2, 'char2cell'), expected);
        end

        function test_channel2lateral_char(testCase)
            % Test 'channel2lateral' feature with single channel name inputs

            % Test inputs
            input1 = 'pupil_l';
            input2 = 'gaze_x_r';
            input3 = 'gaze_y_lr';
            input4 = 'something_y_rl';
            input5 = 'pupil_c';

            % Expected outputs
            expected1 = 'l';
            expected2 = 'r';
            expected3 = 'c';
            expected4 = 'c';
            expected5 = 'c';

            % Verify conversions
            testCase.verifyEqual(pspm_eye(input1, 'channel2lateral'), expected1);
            testCase.verifyEqual(pspm_eye(input2, 'channel2lateral'), expected2);
            testCase.verifyEqual(pspm_eye(input3, 'channel2lateral'), expected3);
            testCase.verifyEqual(pspm_eye(input4, 'channel2lateral'), expected4);
            testCase.verifyEqual(pspm_eye(input5, 'channel2lateral'), expected5);
        end

        function test_channel2lateral_cell(testCase)
            % Test 'channel2lateral' feature with cell array of channel names

            % Test input
            input = {'pupil_r', 'gaze_y_l', 'gaze_x_rl', 'pupil_c', 'gaze_x_lr'};
            
            % Expected output
            expected = {'r', 'l', 'c', 'c', 'c'};
            
            % Verify conversion
            result = pspm_eye(input, 'channel2lateral');
            testCase.verifyEqual(result, expected);
        end

        function test_channel2lateral_char_wrong(testCase)
            % Test 'channel2lateral' feature with single wrong channel name

            input1 = 'pupil_';
            expected1 = {};
            % Verify conversions
            testCase.verifyEqual(pspm_eye(input1, 'channel2lateral'), expected1);
        end

        function test_channel2lateral_cell_wrong(testCase)
            % Test 'channel2lateral' feature with cell array of wrong channel names

            % Test input
            input = {'pupilr', 'gaze_yl', 'gaze_x_r_l', 'pupil_C', 'gaze_x_lR'};
            
            % Expected output
            expected = {{}, {}, 'l', 'c', 'c'};
            
            % Verify conversion
            result = pspm_eye(input, 'channel2lateral');
            testCase.verifyEqual(result, expected);
        end

        function test_channel2lateral_cell_char_UPPERCASE(testCase)
            % Test 'channel2lateral' feature with cell array of channel names

            % Test input
            input1 = {'pupil_x_R', 'gaze_y_LR', 'gaze_x_RL', 'pupil_C', 'gaze_x_L'};
            input2 = 'pupil_x_RL';

            % Expected output
            expected1 = {'r', 'c', 'c', 'c', 'l'};
            expected2 = 'c';

            % Verify conversion

            testCase.verifyEqual(pspm_eye(input1, 'channel2lateral'), expected1);

            result = pspm_eye(input2, 'channel2lateral');
            testCase.verifyEqual(result, expected2);

        end


    end
end
