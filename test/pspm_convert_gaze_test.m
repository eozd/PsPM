classdef pspm_convert_gaze_test < pspm_testcase
  % ● Description
  % unittest class for the pspm_convert_gaze_test function
  properties
    raw_input_filename = fullfile('ImportTestData', 'eyelink', 'S114_s2.asc');
    fn = '';
  end
  properties (TestParameter)
    channel_action = { 'add', 'replace' };
    from = { 'pixel', 'mm', 'inches', 'degree'};
    target = {'mm', 'cm', 'inches', 'degree', 'sps' };
  end
  methods
    % get the gaze data channels for a specific unit
    function len = get_gaze_and_unit(this, data, unit)
      len = find(cellfun(@(c) strcmp(c.header.units, unit) && ~isempty(regexp(c.header.chantype, 'gaze_[x|y]_[r|l]')), data));
    end
  end
  methods(TestMethodSetup)
    function backup(this)
      import = {};
      import{end + 1}.type = 'pupil_r';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'pupil_l';
      import{end}.eyelink_trackdist = 600;
      import{end}.distance_unit = 'mm';
      import{end + 1}.type = 'gaze_x_r';
      import{end + 1}.type = 'gaze_y_r';
      import{end + 1}.type = 'gaze_x_l';
      import{end + 1}.type = 'gaze_y_l';
      import{end + 1}.type = 'marker';
      options = struct();
      options.overwrite = 1; % to always overwrite

      [sts, this.fn] = pspm_import(this.raw_input_filename, 'eyelink', import, options);
    end
  end
  methods (Test)
    function validations(this, target)
      this.verifyWarningFree(@() pspm_convert_gaze(this.fn, struct('target', target, 'from', 'pixel', 'screen_width', 111, 'screen_height', 222, 'screen_distance', 333)));
      this.verifyWarning(@() pspm_convert_gaze(this.fn, struct('target', target, 'from', 'not a unit', 'screen_width', 111, 'screen_height', 222, 'screen_distance', 333)),  'ID:invalid_input:from');
      this.verifyWarning(@() pspm_convert_gaze(this.fn, struct('target', target, 'from', 'pixel', 'screen_width', 'not a number', 'screen_height', 222, 'screen_distance', 333)),  'ID:invalid_input:width');
      this.verifyWarning(@() pspm_convert_gaze(this.fn, struct('target', target, 'from', 'pixel', 'screen_width', 111, 'screen_height', 'not a number', 'screen_distance', 333)),  'ID:invalid_input:height');
      this.verifyWarning(@() pspm_convert_gaze(this.fn, struct('target', 'degree', 'from', 'pixel', 'screen_width', 111, 'screen_height', 222, 'screen_distance', 'not a number')),  'ID:invalid_input:distance');
      this.verifyWarning(@() pspm_convert_gaze(this.fn, struct('target', 'invalid conversion', 'from', 'pixel', 'screen_width', 111, 'screen_height', 222, 'screen_distance', 333)), 'ID:invalid_input:target');
    end
    function conversion(this, target, from, channel_action)
        load(this.fn);
        screen_width = 323;
        screen_height = 232;
        screen_distance = 600;
        % conversion from degree to metric units is not possible
        if ~strcmp(from, 'degree') || strcmp(target, 'sps')
            % convert data to 'from' units
            if (~strcmp(from, 'pixel'))
                [sts, infos, data] = pspm_load_data(this.fn);
                [sts, data, pos_of_channels] = pspm_select_channels(data, 'gaze', 'pixel');
                for i = 1:numel(data)
                    if contains(data{i}.header.chantype, 'x')
                        screen_length = screen_width;
                    else
                        screen_length = screen_height;
                    end
                    [data{i}.data, data{i}.header.range] = pspm_convert_pixel2unit_core(data{i}.data, data{i}.header.range, screen_length);
                    if ~strcmp(from, 'degree')
                        [sts, data{i}.data] = pspm_convert_unit(data{i}.data, 'mm', from);
                        data{i}.header.units = from;
                    end
                end
                if strcmp(from, 'degree')
                    for eye = {'r','l'}
                        gaze_x = find(cellfun(@(c) strcmp(c.header.chantype, ['gaze_x_', eye{1}]), data));
                        gaze_y = find(cellfun(@(c) strcmp(c.header.chantype, ['gaze_y_', eye{1}]), data));
                        [data{gaze_x}.data, data{gaze_y}.data, ...
                            data{gaze_x}.header.range, data{gaze_y}.header.range] = ...
                            pspm_convert_visual_angle_core(data{gaze_x}.data, data{gaze_y}.data, ...
                            screen_width, screen_height, screen_distance);
                        data{gaze_x}.header.units = from;
                        data{gaze_y}.header.units = from;
                    end
                end
                this.verifyLength(this.get_gaze_and_unit(data, from), 4);
            end
            pspm_write_channel(this.fn, data, 'add');
            [sts, infos, data] = pspm_load_data(this.fn);
            data_length = length(data);
            if strcmp(target, 'degree')
                this.verifyLength(this.get_gaze_and_unit(data, 'degree'), 0);
            else
                this.verifyLength(find(cellfun(@(c) strcmp(c.header.chantype, 'sps_l'), data)), 0);
                this.verifyLength(find(cellfun(@(c) strcmp(c.header.chantype, 'sps_r'), data)), 0);
            end
            %if strcmpi(from ,'mm') & strcmpi(channel_action, 'replace'), keyboard; end
            [sts, out_channel] = this.verifyWarningFree(@() pspm_convert_gaze(...
                this.fn, struct('target', target, 'from', from, 'screen_width', screen_width, 'screen_height', screen_height, 'screen_distance', screen_distance), struct('channel_action', channel_action)));
            load(this.fn);
            this.verifyTrue(~isempty(out_channel));
            if strcmpi(target, 'sps')
                extra = 1;                
            elseif strcmpi(channel_action, 'add') || ~strcmpi(target, from) 
                extra = 2;
            else
                extra = 0;
            end
            this.verifyLength(data, data_length + extra);
            data_length = length(data);
            if strcmp(target, 'degree')
                this.verifyLength(this.get_gaze_and_unit(data, 'degree'), 2);
            elseif strcmp(target, 'sps')
                this.verifyLength(find(cellfun(@(c) contains(c.header.chantype, 'sps'), data)), 1);
            end
        end
    end
  end
end
