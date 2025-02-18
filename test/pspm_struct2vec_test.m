classdef pspm_struct2vec_test < matlab.unittest.TestCase
    % unittest class for the pspm_struct2vec function
    % PsPM TestEnvironment
    % ● Authorship
    % (C) 2024 Bernhard Agoué von Raußendorf 

    methods (TestMethodSetup)
        function addFunctionPath(testCase)
            % Add the path to the source directory
            srcPath = fullfile(pwd, '..', 'src');
            addpath(srcPath);
        end
    end

    methods (TestMethodTeardown)
        function removeFunctionPath(testCase)
            % Remove the path to the source directory after each test
            srcPath = fullfile(pwd, '..', 'src');
            rmpath(srcPath);
        end
    end

    methods (Test)
        
        % Test case for basic functionality with scalar fields
        function testBasicFunctionality(testCase)
            S = struct('field', {1, 2, 3});
            actualOutput = pspm_struct2vec(S, 'field', 'generic');
            
            % Expected output
            expectedOutput = [1; 2; 3];
            testCase.verifyEqual(actualOutput, expectedOutput, ...
                'The output vector is incorrect for scalar fields.');
        end

        % Test case for handling multiple elements in a field
        function testMultipleElements(testCase)
            S = struct('field', {[1,2,3], 5, 7});
            actualOutput = pspm_struct2vec(S, 'field', 'generic');
            
            expectedOutput = [1; 5; 7]; % first element of [1,2,3]
            testCase.verifyEqual(actualOutput, expectedOutput, ...
                'The output vector is incorrect when a field contains multiple elements.');
        end

        % Test case for handling empty fields
        function testEmptyFields(testCase)
            S = struct('field', {[], 5, 7});
            actualOutput = pspm_struct2vec(S, 'field', 'generic');
            
            expectedOutput = [NaN; 5; 7];   
            testCase.verifyEqual(actualOutput, expectedOutput, ...
                'The output vector is incorrect for empty fields.');
        end
    end
end
