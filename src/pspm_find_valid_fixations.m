function [sts, pos_of_channel, fn] = pspm_find_valid_fixations(fn, varargin)
% ● Description
%   pspm_find_valid_fixations finds deviations from a specified gaze
%   fixation area. The primary usage of this function is to improve
%   analyis of pupil size. Pupil size data will be incorrect when gaze is
%   not in forward direction, due to foreshortening error. This function
%   allows excluding pupil data points with too large foreshortening. To do
%   so, it acts on one (or two) pupil channel(s), together with the
%   associated x/y gaze channels which must have been converted to the
%   correct units (distance units, or pixel units for bitmap fixation).
%   After finding the invalid fixations from the gaze channels, the
%   corresponding data values in the pupil channel are set to NaN. In this
%   usage of the function, a circle around fixation point defines the valid
%   fixations. Note: an alternative or complement to this strategy is to
%   explicitly correct the pupil foreshortening error, see
%   pspm_pupil_correct and pspm_pupil_correct_eyelink.
%   An alternative usage of this function is to find fixations on a
%   particular screen area, e.g. to define overt attention. In this usage,
%   a bitmap of valid fixation points can be provided, as an alternative to
%   the circle around fixation point. Since this usage is currently
%   considered secondary, it still requires a valid pupil channel as
%   primary channel, even though unrelated to pupil analysis.
%   In both usages, valid fixations can be outputted as additional channel.
%   By default, screen centre is assumed as fixation point. If an explicit
%   fixation point is given, the function assumes that the screen is
%   perpendicular to the vector from the eye to the fixation point (which
%   is approximately correct for large enough screen distance).
% ● Format
%   [sts, channel_index] = pspm_find_valid_fixations(fn, bitmap, options)
%   [sts, channel_index] = pspm_find_valid_fixations(fn, circle_degree, distance, unit, options)
% ● Arguments
%   *             fn : The actual data file containing the eyelink recording with gaze
%                      data converted to cm.
%   *         bitmap : A nxm matrix of the same size as the display, with 1 
%                      for valid and 0 for invalid gaze points. IMPORTANT: the bitmap has to
%                      be defined in terms of the eyetracker coordinate system, i.e.
%                      bitmap(1,1) must correpond to the origin of the eyetracker
%                      coordinate system, and must be of the same size as
%                      the display.
%   *  circle_degree : Size of boundary circle given in degree visual angles.
%   *       distance : Distance between eye and screen in length units.
%   *           unit : Unit in which distance is given.
%   ┌────────options
%   ├.fixation_point : A nx2 vector containing x and y of the fixation point (with respect
%   │                  to the given resolution, and in the eyetracker coordinate system).
%   │                  n should equal either 1 (constant fixation point) or the length
%   │                  of the actual data. If resolution is not defined the values are
%   │                  given in percent. Therefore (0.5 0.5) would correspond to the
%   │                  middle of the screen. Default is (0.5 0.5). Only taken into account
%   │                  if there is no bitmap.
%   ├────.resolution : Resolution with which the fixation point is defined (Maximum value
%   │                  of the x and y coordinates). This can be the screen resolution in
%   │                  pixels (e.g. (1280 1024)) or the width and height of the screen
%   │                  in cm (e.g. (50 30)). Default is (1 1). Only taken into account
%   │                  if there is no bitmap.
%   ├.plot_gaze_coords: Define whether to plot the gaze coordinates for visual
%   │                 inspection of the validation process. Default is false.
%   ├.channel_action: Define whether to add or replace the data. Default is
%   │                 'add'. Possible values are 'add' or 'replace'
%   ├───.add_invalid: [0/1] If this option is enabled, an extra channel will be
%   │                 written containing information about the valid samples.
%   │                 Data points equal to 1 correspond to invalid fixation.
%   │                 Default is not to add this channel.
%   └───────.channel: Choose channels in which the data should be set to NaN
%                     during invalid fixations. This can be a channel
%                     number, any channel type including 'pupil' (which
%                     will select a channel according to the precedence
%                     order specified in pspm_load_channel), or 'both',
%                     which will work on 'pupil_r' and 'pupil_l' and
%                     then update channel statistics and best eye.
%                     The selected channel must be an eyetracker
%                     channel, and the file must contain the corresponding
%                     gaze channel(s) in the correct units: distance units for
%                     mode "fixation" and distance or pixel units for mode
%                     "bitmap".
%                     Default is 'pupil'.
% ● References
%   [1]  Korn CW & Bach DR (2016). A solid frame for the window on cognition:
%        Modelling event-related pupil responses. Journal of Vision, 16:28,1-6.
% ● Developer note
%   Additional i/o options for recursive calls are not included in the help.
%   (1) fn can be a data structure as permitted by pspm_load_data,
%   (2) the output argument pos_of_channels is an index of the channel(s)
%   that was/were replaced or added
%   (3) The third output argument is required for recursive calls
% ● History
%   Introduced in PsPM 4.0
%   Written in 2016 Tobias Moser (University of Zurich)
%   Updated in 2021 by Teddy
%   Channel logic changed in 2024 by Dominik Bach (Uni Bonn)

%% initialise
global settings;
if isempty(settings), pspm_init; end
sts = -1;
pos_of_channel = -1;

%% validate input
if numel(varargin) < 1
  warning('ID:invalid_input', ['Not enough input arguments.', ...
    ' You have to either pass a bitmap or circle_degree, distance and unit',...
    ' to compute the valid fixations']); return;
end
if numel(varargin{1}) > 1
  mode = 'bitmap';
  bitmap = varargin{1};
  if ~ismatrix(bitmap) || (~isnumeric(bitmap) && ~islogical(bitmap))
    warning('ID:invalid_input', ['The bitmap must be a matrix and must',...
      ' contain numeric or logical values.']); return;
  end
  if numel(varargin) < 2
    options = struct();
    options.mode = 'bitmap';
  else
    options = varargin{2};
    options.mode = 'bitmap';
  end
else
  mode = 'fixation';
  if numel(varargin) < 3
    warning('ID:invalid_input', ['Not enough input arguments.', ...
      ' You have to set circle_degree, distance and unit',...
      ' to compute the valid fixations']); return;
  end
  circle_degree = varargin{1};
  distance = varargin{2};
  unit = varargin{3};
  if numel(varargin) < 4
    options = struct();
    options.mode = 'fixation';
  else
    options = varargin{4};
    if ~isstruct(options)
      warning('ID:invalid_input', 'Options must be a struct.');
      return;
    else
      options.mode = 'fixation';
    end
  end
  if ~isnumeric(circle_degree)
    warning('ID:invalid_input', 'Circle_degree is not numeric.');
    return;
  elseif ~isnumeric(distance)
    warning('ID:invalid_input', 'Distance is not set or not numeric.');
    return;
  elseif ~ischar(unit)
    warning('ID:invalid_input', 'Unit should be a char.');
    return;
  end
end

% check & change distance to 'mm'
if strcmpi(mode,'fixation')
  if ~strcmpi(unit,'mm')
    [nsts,distance] = pspm_convert_unit(distance,unit ,'mm');
    if nsts~=1
      warning('ID:invalid_input', 'Failed to convert distance to mm.');
    end
  end
end

% check options
options = pspm_options(options, 'find_valid_fixations');
if options.invalid
  return
end


% in recursive calls, fn is a struct with fields .data and .infos, which is
% simply checked by by pspm_load_data
alldata = struct();
[sts_load, alldata.infos, alldata.data] = pspm_load_data(fn);
if sts_load < 1, return, end

% progress according to options.channel
if ~strcmpi(options.channel, 'both')
    [sts_load, data, infos, pos_of_channel] = pspm_load_channel(alldata, options.channel);
    if sts_load < 1, return; end


    % load corresponding gaze channels in correct units
    channelunits_list = cellfun(@(x) data.header.units, alldata.data, 'uni', false);
    if strcmpi(mode, 'fixation')
        channels_correct_units = find(~contains(channelunits_list, 'degree') & ~contains(channelunits_list, 'pixel'));
    elseif strcmpi(mode, 'bitmap')
        channels_correct_units = find(~contains(channelunits_list, 'degree'));
    end
    gazedata = struct('infos', alldata.infos, 'data', {alldata.data(channels_correct_units)});

    [sts_gaze, gaze_x, gaze_y, eye] = pspm_load_gaze(gazedata, data.header.chantype);

    if sts_gaze < 1
        warning('ID:invalid_input', ['Unable to perform gaze ', ...
          'validation. Cannot find gaze channels with distance ',...
          'unit values. Maybe you need to convert them with ', ...
          'pspm_convert_pixel2unit()']);
        return;
    end

    x_unit = gaze_x.header.units;
    y_unit = gaze_y.header.units;

    switch mode
         case 'fixation'
             % expand fixation point to size of data
             fix_point = options.fixation_point;
             if size(fix_point, 1) == 1
                 fix_point = repmat(fix_point(:)', numel(gaze_x.data), 1);
             elseif size(fix_point, 1) ~= numel(gaze_x)
                 warning('ID:invalid_input', ['Fixation point has wrong ', ...
                     'dimensions - it should be 1x2 or nx2 where n is the ', ...
                     'number of gaze data points.']);
                    return
             end

             % normalise fixation point to fraction of full screen
             fix_point = fix_point ./ repmat(options.resolution(:)', ...
                 size(fix_point, 1), 1);

             % convert data to mm
             if ~strcmpi(x_unit,'mm')
                [nsts,x_data] = pspm_convert_unit(gaze_x.data, x_unit, 'mm');
                [msts,x_range] = pspm_convert_unit(transpose(gaze_x.header.range), x_unit, 'mm');
                  if nsts~=1 || msts~=1
                    warning('ID:invalid_input', 'Failed to convert data.');
                    return
                  end
             else
                x_data = gaze_x.data;
                x_range = gaze_x.header.range;
             end
             if ~strcmpi(y_unit,'mm')
                 [nsts,y_data] = pspm_convert_unit(gaze_y.data, y_unit, 'mm');
                 [msts,y_range] = pspm_convert_unit(transpose(gaze_y.header.range), y_unit, 'mm');
                 if nsts~=1 || msts~=1
                     warning('ID:invalid_input', 'Failed to convert data.');
                     return
                 end
             else
                 y_data = gaze_y.data;
                 y_range = gaze_y.header.range;
             end

            % convert normalized fixation points to data resolution
            fix_point_temp = zeros(size(fix_point));
            fix_point_temp(:,1) = x_range(1)+ fix_point(:,1)* diff(x_range);
            fix_point_temp(:,2) = y_range(1)+ fix_point(:,2)* diff(y_range);

            % calculate the visual angle of the gaze points
            gaze_dist = fix_point_temp - [x_data(:), y_data(:)];
            gaze_dist = sqrt(gaze_dist(:,1).^2 + gaze_dist(:,2).^2);
            angle_of_gaze = 2 * atan(gaze_dist/(2*distance));

            % compare calculated distance to accepted radius
            excl = angle_of_gaze > deg2rad(circle_degree);

            % check plotting
            if options.plot_gaze_coords
              fg = figure('Name', 'Fixation plot');
              ax = axes('NextPlot', 'add');
              set(ax, 'Parent', handle(fg));

              % first fixation point
              x_point = fix_point_temp(1,1);
              y_point = fix_point_temp(1,2);
              radius  = tan(deg2rad(circle_degree)/2) * 2 * distance;

              % plot the circle around the first fixation point
              th = 0:pi/50:2*pi;
              x_unit = radius(1) * cos(th) + x_point;
              y_unit = radius(1) * sin(th) + y_point;

              % plot gaze coordinates
              mi=min(min(x_data),min(y_data));
              ma=max(max(x_data),max(y_data));

              axis([mi ma mi ma]);
              scatter(ax, x_data, y_data, 'k.');
              plot(x_unit, y_unit, 'r');
            end
         case 'bitmap'
             [ylim,xlim] = size(bitmap);
             map_x_range = [1,xlim];
             map_y_range = [1,ylim];

             x_data = gaze_x.data;
             y_data = gaze_y.data;
             x_range = gaze_x.header.range;
             y_range = gaze_y.header.range;

             N = numel(x_data);

             % change bitmap to logical
             bitmap = logical(bitmap);

             % normalize recorded data to adjust to right range
             % of the bitmap
             x_data = (x_data - x_range(1))/diff(x_range);
             y_data = (y_data - y_range(1))/diff(y_range);

             % adapt to bitmap range
             x_data = map_x_range(1)+ x_data * diff(map_x_range);
             y_data = map_y_range(1)+ y_data * diff(map_y_range);

             % round gaze data such that we can use them as
             % indexed
             x_data = round(x_data);
             y_data = round(y_data);

             % set all gaze values which are out of the display
             % window range to NaN
             x_data(x_data > map_x_range(2) | x_data < map_x_range(1)) = NaN;
             y_data(y_data > map_y_range(2) | y_data < map_y_range(1)) = NaN;

             % only take gaze coordinates which both aren't NaNs
             valid_gaze_idx = find(~isnan(x_data) & ~isnan(y_data));
             valid_gaze = [x_data(valid_gaze_idx),y_data(valid_gaze_idx)];

             val= zeros(N,1);
             for k=1:numel(valid_gaze_idx)
                 val(valid_gaze_idx(k)) = bitmap(valid_gaze(k,2),valid_gaze(k,1));
             end
             val = logical(val);
             excl = ~val;

             if options.plot_gaze_coords
                 fg = figure;
                 ax = axes('NextPlot', 'add');
                 set(ax, 'Parent', handle(fg));


                 mi=min(min(x_data),min(y_data));
                 ma=max(max(x_data),max(y_data));
                 axis([mi ma mi ma]);
                 imshow(bitmap);
                 hold on;
                 scatter( x_data, y_data);

             end
     end

     % set excluded periods in data to NaN
     data.data(excl == 1) = NaN;
     if all(isnan(data.data))
         warning('ID:invalid_input', ['All values of channel ''%s'' ', ...
             'completely set to NaN. Please reconsider your parameters.'], ...
             data.header.chantype);
     end

     % add to alldata and update infos
     if ~strcmpi(options.channel_action, 'replace')
         pos_of_channel = numel(alldata.data) + 1;
     end

     alldata.data{pos_of_channel} = data;
     n_inv = sum(isnan(data.data));
     n_data = numel(data.data);
     alldata.infos.source.chan_stats{pos_of_channel}.nan_ratio = n_inv/n_data;

     % add invalid fixations if requested
     if options.add_invalid

         [sts, ~, new_chantype] = pspm_find_eye(data.header.chantype);
         excl_hdr = struct('chantype', [new_chantype, '_missing_', eye],...
             'units', '', 'sr', data.header.sr);
         excl_data = struct('data', double(excl), 'header', excl_hdr);
         alldata.data{end+1} = excl_data;
     end
elseif strcmpi(options.channel, 'both')
    % call this function recursively
    channels = {'pupil_r', 'pupil_l'};
    for i_channel = 1:2
        options.channel = channels{i_channel};
        varargin{end} = options;
        % varargin{:} unpacks the cell array into single arguments:
        [rsts(i_channel), pos_of_channel(i_channel), alldata] = pspm_find_valid_fixations(alldata, varargin{:});
    end
    if (rsts(1) < 1 && rsts(2) < 1)
        return;
    elseif (rsts(1) < 1 || rsts(2) < 1)
        pos_of_channel(rsts < 1) = [];
    else
        % update best eye
        eye_stat = Inf(1,numel(alldata.infos.source.eyesObserved));
        for i = 1:numel(alldata.infos.source.eyesObserved)
            e_stat = alldata.infos.source.chan_stats(pos_of_channel);
            eye_stat(i) = max(cellfun(@(x) x.nan_ratio, e_stat));
        end
        [~, min_idx] = min(eye_stat);
        alldata.infos.source.best_eye = lower(alldata.infos.source.eyesObserved(min_idx));
    end
end

% write to file or return data
if ischar(fn)
  alldata.options = struct('overwrite', 1);
  [sts, ~, ~, ~] = pspm_load_data(fn, alldata);
elseif isstruct(fn)
    sts = 1;
    fn = alldata;
end

