classdef pspm_expand_epochs_test < pspm_testcase
    % ● Description
    %   Unit test class for the pspm_expand_epochs function.
    % ● Authorship
    %   (C) 2024 Bernhard Agoué von Raußendorf

    properties(Constant)
        % Define test data filenames
        epochs_filename = 'test_epochs.mat';
        data_filename = 'test_data.mat';
        backup_data_filename = 'test_data_backup.mat';
        NoNaN_data_filename  = 'test_data_NoNaN.mat';
        backup_NoNaN_data_filename  = 'test_data_NoNaN_backup.mat';

        expansion = [1, 1]; % Expand epochs by 1 second before and after
        options = struct('overwrite', 1);
    end

    methods(TestClassSetup)
        function generate_test_data(this)
            % Generate test epochs file
            epochs = [5, 10; 15, 20];
            save(this.epochs_filename, 'epochs');

            % Generate test data file with missing data in a channel
            channels{1}.chantype = 'scr' ;           
            channels{1}.sr = 100;

            duration = 25; % seconds
            outfile = pspm_testdata_gen(channels, duration, this.data_filename);

            copyfile(this.data_filename, this.NoNaN_data_filename);

        % Introduce missing data (NaNs) between 12 and 18 seconds
            sr = channels{1}.sr;
            data_length = duration * sr;
            data = outfile.data{1}.data;
            missing_indices = (12*sr):(18*sr);
            data(missing_indices) = NaN;
    
            % Use pspm_write_channel to save the modified data
            newdata = struct('header', outfile.data{1}.header, 'data', data);
            options = struct('channel', 1);
            [wsts, out] = pspm_write_channel(this.data_filename, {newdata}, 'replace', options);
            if wsts < 1
                error('Failed to write modified channel data');
            end
    
            % Backup the data file
            copyfile(this.data_filename, this.backup_data_filename);
        end
    end

    methods(Test)
        function InValidInputError(this)
            % no input
            this.verifyWarning(@()pspm_expand_epochs(), 'ID:invalid_input');
            % invalid input
            this.verifyWarning(@()pspm_expand_epochs('invalid input'), 'ID:invalid_input');
            % Invalid expansion vector
            epochs = [5, 10; 15, 20];
            invalid_expansion = [1]; % Should be a 2-element vector
            this.verifyWarning(@()pspm_expand_epochs(epochs, invalid_expansion), 'ID:invalid_input');
        end

        function InValidInputEpochfileError(this)

            expansion = this.expansion;
            options = this.options;
            fn = 'nofile.mat';
            
            this.verifyWarning(@()pspm_expand_epochs(fn, expansion, options)  , 'ID:invalid_input');
        end

        function InValidInputDataFileError(this)

            expansion = this.expansion;
            options = this.options;
            epoch = [1 , 1];
            fn = 'nofile.mat';
            this.verifyWarning(@()pspm_expand_epochs(fn, expansion, options)  , 'ID:invalid_input');
        end

        function InValidEpochsFormatError(this)
            options = this.options;

            % Test single column epochs
            invalid_epochs = [1; 2; 3];
            [sts , ~] = pspm_expand_epochs(invalid_epochs, this.expansion,options);
            this.verifyLessThan(sts,1)
            % Test non-numeric epochs
            cell_epochs = {[1,2]; [3,4]};
            [sts , ~] = pspm_expand_epochs(invalid_epochs, this.expansion,options);
            this.verifyLessThan(sts,1)

        end
        
        function InValidInputDataFileChannelError(this)
            % Tests the error handeling of the loading of the channel

            channel1 = 99; 
            channel2 = -99;
            channel3 = 'not a channel';

            Exp = this.expansion;
            options = struct('channel_action', 'replace','overwrite',1);
            fn = this.data_filename;
     
            this.verifyWarning(@()pspm_expand_epochs(fn, channel1, Exp, options), 'ID:invalid_input' )
            this.verifyWarning(@()pspm_expand_epochs(fn, channel2, Exp, options), 'ID:invalid_input' )
            this.verifyWarning(@()pspm_expand_epochs(fn, channel3, Exp, options), 'ID:invalid_chantype' )

            % Restors the datafile
            copyfile(this.backup_data_filename, this.data_filename);
        end
        
        function InValidInputDataFileChannelActionError(this)
            % Tests the error handeling of the loading of the channel

            channel1 = 1; 
            Exp = this.expansion;
            options = struct('channel_action', 'no_action','overwrite', 1);
            fn = this.data_filename;
     
            this.verifyWarning(@()pspm_expand_epochs(fn, channel1, Exp, options), 'ID:invalid_input' )

            % Restors the datafile
            copyfile(this.backup_data_filename, this.data_filename);


        end

        function NoNaNDataFileEpochReplaceTest(this)
            % Tests the error handeling of the loading of the channel

            channel1 = 1; 
            Exp = this.expansion;
            options = struct('channel_action', 'replace','overwrite', 1);
         
            fn = this.NoNaN_data_filename;
            [~, ~, ~, filestruct] = pspm_load_data(fn, 'none');
            
            numofchanbefor =  filestruct.numofchan;

            [sts, expanded_epochs] = pspm_expand_epochs(fn, channel1, Exp, options);
            this.verifyEqual(sts,1)
            
            % checks if the number of channel stays the same
            [~, ~, ~, filestruct2] = pspm_load_data(fn, 'none');
            numofchanafter =  filestruct2.numofchan;

            this.verifyEqual(numofchanbefor,numofchanafter)
        end
        
        function NoNaNDataFileEpochAddTest(this)
            % Tests the error handeling of the loading of the channel

            channel1 = 1; 
            Exp = this.expansion;
            options = struct('channel_action', 'add','overwrite',1);
         
            fn = this.NoNaN_data_filename;

            % makes a backup
            copyfile(fn,this.backup_NoNaN_data_filename)

            % count the channels
            [~, ~, ~, filestruct] = pspm_load_data(fn, 'none');     
            numofchanbefor =  filestruct.numofchan;

            [sts, expanded_epochs] = pspm_expand_epochs(fn, channel1, Exp, options);
            this.verifyEqual(sts,1)
            
            % checks if the number of channel increases
            [~, ~, ~, filestruct2] = pspm_load_data(fn, 'none');
            numofchanafter =  filestruct2.numofchan;

            this.verifyEqual(numofchanbefor+1,numofchanafter)

            movefile(this.backup_NoNaN_data_filename,fn)
            
        end


        % function NoNaNDataFileNoEpochOverwriteError(this)  
        %     % Tests the error handeling of the loading of the channel
        % 
        %     channel1 = 1; 
        %     Exp = this.expansion;
        %     options = struct('channel_action', 'replace','overwrite', 1); % 
        % 
        %     fn = this.NoNaN_data_filename;
        % 
        %     [pathstr, name, ext] = fileparts(fn);
        %     fn_out = fullfile(pathstr, ['e', name, ext]);
        %     copyfile(fn,fn_out)
        % 
        %     this.verifyWarning(@()pspm_expand_epochs(fn, channel1, Exp, options), 'ID:empty_channel')
        % 
        %     % add pspm_get_timing
        %     this.verifyTrue(exist(fn_out,'file'),'False')
        % 
        % end
        
        function EpandEpochsWithEpochsTest(this)
            % Test expanding epochs given an epoch matrix
            import matlab.unittest.constraints.IsEqualTo

            epochs = [5, 10; 15, 20];
            expansion = this.expansion;
            [sts, expanded_epochs] = pspm_expand_epochs(epochs, expansion);

            % Expected expanded epochs
            expected_epochs = [4, 11; 14, 21];

            this.verifyEqual(sts, 1);
            this.verifyThat(expanded_epochs, IsEqualTo(expected_epochs));
        end

        function ExpandEpochsWithEpochsFileTest(this)


            expansion = this.expansion;
            options = this.options;
            fn = this.epochs_filename;
            [sts, output_file] = pspm_expand_epochs(fn, expansion, options);

            % Load the expanded epochs
            loaded_epochs = load(output_file);
            expanded_epochs = loaded_epochs.epochs;

            % Expected expanded epochs
            expected_epochs = [4, 11; 14, 21];


            this.verifyEqual(sts, 1);
            this.verifyEqual(expanded_epochs,expected_epochs)
        end

        function ExpandEpochsWithDataFileReplaceTest(this)
            % Test expanding epochs given a data file

            channel = 1; % Assuming the missing data is in channel 1
            Exp = [1,1]; %this.expansion;
            options = struct('channel_action', 'replace','overwrite',1);
            fn = this.data_filename;

            % Run the function
            [sts, channel_index] = pspm_expand_epochs(fn, channel, Exp, options);

            % Load the data and check that missing data has been expanded
            [sts, ~, data,~] = pspm_load_data(this.data_filename);
            this.verifyEqual(sts, 1);

            sr = data{channel_index}.header.sr;
            data_values = data{channel_index}.data;

            % Expected missing data indices
            original_missing_indices = (12*sr):(18*sr);
            expanded_missing_indices = ((12-Exp(1))*sr):((18+Exp(2))*sr); 

            % Verify that data is NaN in the expected expanded intervals
            % makes a logical array of the real missing values: NaN -> 1
            missing_indices = isnan(data_values);
            % makes a logical array of expacted missing values: NaN -> 1
            expected_missing_logical = false(size(data_values)); 
            expected_missing_logical(expanded_missing_indices) = true;

            this.verifyEqual(sts, 1)
            this.verifyEqual(missing_indices,expected_missing_logical);

            % Restors the datafile
            copyfile(this.backup_data_filename, this.data_filename);
        end

        function ExpandEpochsWithDataFileAddTest(this)
            % Test expanding epochs given a data file with 'add' option

            channel = 1;
            Exp = [5,2]; % different expansion then above
            options = struct('channel_action', 'add','overwrite',1);
            fn = this.data_filename;

            % Run the function
            [sts, channel_index] = pspm_expand_epochs(fn, channel, Exp, options);

            % Load the data and check that missing data has been expanded
            [sts, ~, data, filestruct] = pspm_load_data(this.data_filename);
            this.verifyEqual(sts, 1);

            sr = data{channel_index}.header.sr;
            data_values = data{channel_index}.data;

            % Expected missing data indices
            original_missing_indices = (12*sr):(18*sr);
            expanded_missing_indices = ((12-Exp(1))*sr):((18+Exp(2))*sr); 
            

            % Verify that data is NaN in the expected expanded intervals
            missing_indices = isnan(data_values);
            %
            expected_missing_logical = false(size(data_values));
            %expected_missing_logical(original_missing_indices) = true;
            expected_missing_logical(expanded_missing_indices) = true;
            
            this.verifyEqual(sts,1)
            this.verifyEqual(filestruct.numofchan , 2)  % checks if the channel was added?
            this.verifyEqual(missing_indices, expected_missing_logical);
            
             
            % Restors the datafile
            copyfile(this.backup_data_filename, this.data_filename);
            
        end

    end

    methods(TestClassTeardown)
        function cleanup(this)
            % Restore the original data file
            movefile(this.backup_data_filename, this.data_filename);

            % Delete the test files
            delete(this.epochs_filename);
           
            if isfile(['e', this.epochs_filename])
                delete(['e', this.epochs_filename]);
            end


            delete(this.data_filename);
            delete(this.NoNaN_data_filename);
        end
    end
end
