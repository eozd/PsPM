classdef pspm_find_valid_fixations_test < matlab.unittest.TestCase
    % ● Description
    %   unittest class for pspm_find_valid_fixations
    % ● History
    %   PsPM TestEnvironment
    %   (C) 2016 Tobias Moser (University of Zurich)
    %   Updated in 2021 by Teddy
    %   Updated for fitting logic in 2024 by Dominik R Bach (Uni Bonn)

    properties
        datafiles = {};
        testfile_prefix = 'datafile';
    end
    properties(TestParameter)
        % gaze validation settings
        distance = {75};
        unit ={'cm'};
        resolution = {[1 1], [1280 1024], [1920 1080]};
        % eyes
        eyes = {'l', 'r'};
        % others
        channel_action = {'add', 'replace'};
        newfile = {0, 1};
        missing = {0, 1};
        % channels
        work_chans = {'pupil_r', 'pupil_l', 'pupil', 'both'};
    end
    methods
        function [degrees,bitmaps] = generate_fixation_data(this, fn, dist, eyes)
            this.datafiles{end+1} = fn;
            % set default values
            sr = 500; % 500 Hz
            duration = 5*60; % 5 minutes
            % create time series
            t = transpose(0:sr^-1:duration-sr^-1);
            % screen settings in cm
            screen_width = 50;
            screen_height = 40;
            % generate gaze info
            % radius in cm
            radius = 5;
            % variance in cm
            variance = .25;
            % fixpoint
            fixpoint = [1/4 3/4];
            % range values through testing
            all_deg = 2*tan((radius*5/4)/dist)*180/pi; % all is missing
            some_deg = 2*tan(radius/dist)*180/pi; % some is missing
            none_deg = 2*tan((radius*5/12)/dist)*180/pi; % none is missing
            l_sh  = ceil(0.5 * screen_height);
            m_sh  = floor(0.25 * screen_height);
            n_sh  = ceil(0.75 * screen_height);
            l_sw  = ceil(0.5 * screen_width);
            m_sw  = floor(0.25 * screen_width);
            n_sw  = ceil(0.75 * screen_width);
            all_bit = zeros(screen_height,screen_width);
            all_bit(1:l_sh,1:l_sw) =1;
            some_bit = zeros(screen_height,screen_width);
            some_bit(m_sh:n_sh,m_sw:n_sw)=1;
            none_bit  = zeros(screen_height,screen_width);
            none_bit(l_sh:screen_height,l_sw:screen_width)=1;
            degrees = {struct('deg', all_deg, 'expect', 0, 'name', 'all'), ...
                struct('deg', none_deg, 'expect', 1, 'name', 'none'), ...
                struct('deg', some_deg, 'expect', -1, 'name', 'some')};
            % invert bitmaps to eyetracker coordinate system
            bitmaps = {struct('deg', all_bit(end:-1:1, :), 'expect', 0, 'name', 'all'), ...
                struct('deg', none_bit(end:-1:1, :), 'expect', 1, 'name', 'none'), ...
                struct('deg', some_bit(end:-1:1, :), 'expect', -1, 'name', 'some')};
            infos.duration = duration;
            if strcmp(eyes, 'lr') || strcmp(eyes, 'rl')
                eye_individuals = {'l', 'r'};
            else
                eye_individuals = {eyes};
            end
            infos.source.eyesObserved = upper(eyes);
            n_chans = 3; % will create 3 channels
            data = cell(n_chans*length(eye_individuals), 1);
            for i = 1:length(eye_individuals)
                e = lower(eye_individuals{i});
                % generate gaze data
                gaze_x = fixpoint(1)*screen_width + radius*sin(t) + ...
                    rand(numel(t),1)*variance-variance/2;
                gaze_y = fixpoint(2)*screen_height + radius*cos(t) + ...
                    rand(numel(t),1)*variance-variance/2;
                % generate pupil data (range from 2 to 8 mm)
                % unit micrometer
                pupil = sin(t/10)*3000+5000;
                data{1 + n_chans*(i-1)}.data = gaze_x;
                data{1 + n_chans*(i-1)}.header.chantype = ['gaze_x_', e];
                data{1 + n_chans*(i-1)}.header.units = 'cm';
                data{1 + n_chans*(i-1)}.header.sr = sr;
                data{1 + n_chans*(i-1)}.header.range = [0 screen_width];
                data{2 + n_chans*(i-1)}.data = gaze_y;
                data{2 + n_chans*(i-1)}.header.chantype = ['gaze_y_', e];
                data{2 + n_chans*(i-1)}.header.units = 'cm';
                data{2 + n_chans*(i-1)}.header.sr = sr;
                data{2 + n_chans*(i-1)}.header.range = [0 screen_height];
                data{3 + n_chans*(i-1)}.data = pupil;
                data{3 + n_chans*(i-1)}.header.chantype = ['pupil_', e];
                data{3 + n_chans*(i-1)}.header.units = 'diameter';
                data{3 + n_chans*(i-1)}.header.sr = sr;
            end
            save(fn, 'infos', 'data');
        end
    end
    methods(TestMethodTeardown)
        function cleanup(this)
            for i=1:length(this.datafiles)
                f = this.datafiles{i};
                if exist(f, 'file')
                    delete(f);
                end
            end
        end
    end
    methods(Test)
        function test_work_chans(this, work_chans)
            % generate data
            fn = pspm_find_free_fn(this.testfile_prefix, '.mat');
            % generate bilateral data
            [degs,~] = this.generate_fixation_data(fn, this.distance{1}, 'lr');
            % this is to generate channel_l and channel_r, not channel_lr!
            options = struct();
            d = vertcat(degs{:});
            circle_degree = d(strcmpi({d.name}, 'some')).deg;
            dist = this.distance{1};
            dist_unit = this.unit{1};
            options.resolution = [1280 1024];
            options.fixation_point = [1280/4 1024*3/4];
            options.channel_action = 'add';
            [~,~, o_data] = pspm_load_data(fn);
            options.channel = work_chans;
            [sts, ~] = this.verifyWarningFree(@() ...
                pspm_find_valid_fixations(fn, circle_degree, dist,dist_unit,options));
            this.verifyEqual(sts, 1);
            [~,~, n_data] = pspm_load_data(fn);
            n_new_chans = numel(n_data);
            n_old_chans = numel(o_data);
            chantypes = cellfun(@(x) x.header.chantype, ...
                n_data((n_old_chans+1):n_new_chans), 'UniformOutput', 0);
            if strcmpi(work_chans, 'both')
                chans = {'pupil_r', 'pupil_l'}; % order in the function
            elseif strcmpi(work_chans, 'pupil')
                chans = {'pupil_r'}; % right is lat
            else
                chans = {work_chans};
            end
            this.verifyEqual(chantypes(:), chans(:))
        end
        function test_missing(this, missing)
            % generate data
            fn = pspm_find_free_fn(this.testfile_prefix, '.mat');
            [degs,~] = this.generate_fixation_data(fn, this.distance{1}, 'lr');
            options = struct();
            d = vertcat(degs{:});
            circle_degree = d(strcmpi({d.name}, 'some')).deg;
            dist = this.distance{1};
            dist_unit = this.unit{1};
            options.resolution = [1280 1024];
            options.fixation_point = [1280/4 1024*3/4];
            options.add_invalid = missing;
            options.channel_action = 'add';
            [sts, ~] = this.verifyWarningFree(@() ...
                pspm_find_valid_fixations(fn, circle_degree, dist,dist_unit,options));
            this.verifyEqual(sts, 1);
            [~, ~, n_data] = pspm_load_data(fn);
            % look for channels with 'missing' in chantype
            missing_chans = cellfun(@(x) ...
                numel(regexp(x.header.chantype, 'missing')) > 0, n_data);
            if missing
                % expect missing channels
                this.verifyTrue(any(missing_chans));
            else
                % expect no missing channels
                this.verifyTrue(all(~missing_chans));
            end
        end
        function test_chan_action(this, channel_action)
            % generate data
            fn = pspm_find_free_fn(this.testfile_prefix, '.mat');
            [degs,~] = this.generate_fixation_data(fn, this.distance{1},  'lr');
            options = struct();
            d = vertcat(degs{:});
            circle_degree = d(strcmpi({d.name}, 'some')).deg;
            dist = this.distance{1};
            dist_unit = this.unit{1};
            options.resolution = [1280 1024];
            options.screen_settings.display_size = 20;
            options.fixation_point = [1280/4 1024*3/4];
            options.channel_action = channel_action;
            [~, ~, o_data] = pspm_load_data(fn);
            [sts, ~] = this.verifyWarningFree(@() ...
                pspm_find_valid_fixations(fn, circle_degree, dist, dist_unit,options));
            this.verifyEqual(sts, 1);
            [~, ~, n_data] = pspm_load_data(fn);
            switch channel_action
                case 'add'
                    this.verifyNotEqual(numel(n_data), numel(o_data));
                case 'replace'
                    this.verifyEqual(numel(n_data), numel(o_data));
            end
        end
        function test_gaze_validation(this, distance, ...
                resolution, eyes)
            % generate data
            fn = pspm_find_free_fn(this.testfile_prefix, '.mat');
            [degs,~] = this.generate_fixation_data(fn, distance, eyes);
            for i = 1:numel(degs)
                testfn = pspm_find_free_fn(this.testfile_prefix, '.mat');


                copyfile(fn, testfn); 
                this.datafiles{end+1} = testfn;
                d = degs{i};
                circle_degree = d.deg;
                dist = distance;
                dist_unit = this.unit{1};
                options.resolution = resolution;
                options.add_invalid = 1;
                options.fixation_point = [resolution(1)/4 resolution(2)*3/4];
                if numel(eyes) == 1
                    options.channel = ['pupil_', eyes];
                else
                    options.channel = 'both';
                end
                if d.expect == 1
                    [~, outfile] = this.verifyWarning(@() ...
                        pspm_find_valid_fixations(testfn, circle_degree, dist, dist_unit, options), ...
                        'ID:invalid_input');
                else
                    [sts, ~] = this.verifyWarningFree(@() ...
                        pspm_find_valid_fixations(testfn, circle_degree, dist, dist_unit, options));
                    this.verifyEqual(sts, 1);
                end
                [~, ~, data] = pspm_load_data(testfn);
                % this test is only possible if NaN pupil values also cause
                % invalid gaze coordinates which will lead to 1's in the
                % missing channel.
                for j=1:length(eyes)
                    e = lower(eyes(j));
                    missing_chan = find(...
                        cellfun(@(x) strcmpi(x.header.chantype, ['pupil_missing_', e]), data),...
                        1, 'last');
                    pupil_chan = find(...
                        cellfun(@(x) strcmpi(x.header.chantype, ['pupil_', e]), data),...
                        1, 'last');
                    this.verifyTrue(all(isnan(data{pupil_chan}.data(data{missing_chan}.data == 1))));
                    if d.expect ~= -1
                        exp_missing = ...
                            max(numel(data{pupil_chan}.data)*d.expect,...
                            sum(isnan(data{pupil_chan}.data)));
                        this.verifyTrue(sum(data{missing_chan}.data) == exp_missing);
                    end
                end
            end
        end
        function test_bitmap_validation(this, distance, ...
                resolution, eyes)
            % generate data
            fn = pspm_find_free_fn(this.testfile_prefix, '.mat');
            [~,bitmaps] = this.generate_fixation_data(fn, distance, eyes);
            for i = 1:numel(bitmaps)
                testfn = pspm_find_free_fn(this.testfile_prefix, '.mat');
                copyfile(fn, testfn);
                this.datafiles{end+1} = testfn;
                d = bitmaps{i};
                bitmap = d.deg;
                options.resolution = resolution;
                options.add_invalid = 1;
                if numel(eyes) == 1
                    options.channel = ['pupil_', eyes];
                else
                    options.channel = 'both';
                end
                if d.expect ~= 1
                    [sts, ~] = this.verifyWarningFree(@() ...
                        pspm_find_valid_fixations(testfn,bitmap, options));
                    this.verifyEqual(sts, 1);
                else
                    [~, ~] = this.verifyWarning(@() ...
                        pspm_find_valid_fixations(testfn,bitmap, options), ...
                        'ID:invalid_input');
                end
                [~, ~, data] = pspm_load_data(testfn);
                % this test is only possible if NaN pupil values also cause
                % invalid gaze coordinates which will lead to 1's in the
                % missing channel.
                for j = 1:length(eyes)
                    e = lower(eyes(j));
                    missing_chan = find(cellfun(@(x) strcmpi(x.header.chantype,...
                        ['pupil_missing_', e]), data), 1, 'last');
                    pupil_chan = find(cellfun(@(x) strcmpi(x.header.chantype,...
                        ['pupil_', e]), data), 1, 'last');
                    this.verifyTrue(all(isnan(data{pupil_chan}.data(data{missing_chan}.data == 1))));
                    if d.expect ~= -1
                        exp_missing = max(numel(data{pupil_chan}.data)*d.expect, sum(isnan(data{pupil_chan}.data)));
                        this.verifyTrue(sum(data{missing_chan}.data) == exp_missing);
                    end
                end
            end
        end
        function invalid_input(this)
            % no input
            this.verifyWarning(@() pspm_find_valid_fixations(), 'ID:invalid_input');
            % wrong input
            this.verifyWarning(@() pspm_find_valid_fixations('a'), 'ID:invalid_input');
            % generate data
            fn = pspm_find_free_fn(this.testfile_prefix, '.mat');
            this.generate_fixation_data(fn, 500, 'lr');
            circle_degree = 'a';
            dist = '1';
            options = [];
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, options), 'ID:invalid_input');
            circle_degree = 1;
            dist = 'a';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, options), 'ID:invalid_input');
            dist = 1;
            dist_unit = 5;
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist,dist_unit,options), 'ID:invalid_input');
            dist_unit = 'cm';
            options2 = [1,2];
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist,dist_unit,options2), 'ID:invalid_input');
            % check bitmap option
            bitmap = 'Hello World!';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, bitmap, ...
                options), 'ID:invalid_input');
            options.resolution = 1;
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit,options), 'ID:invalid_input');
            options.screen_settings.resolution = [1280 1024];
            options.fixation_point = 'a';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
            options.fixation_point = [100 500];
            options.channel_action = 'bla';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
            options.channel_action = 'add';
            options.newfile = 0;
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
            options.newfile = 'abc';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
            options.invalid = 'abc';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
            options.add_invalid = 0;
            options.eyes = 'abc';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
            options.eyes = 'combined';
            options.channel = 'abc';
            this.verifyWarning(@() pspm_find_valid_fixations(fn, circle_degree, ...
                dist, dist_unit, options), 'ID:invalid_input');
        end
    end
end
