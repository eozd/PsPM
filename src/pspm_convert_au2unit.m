function [sts, outchannel] = pspm_convert_au2unit(varargin)
% ● Description
%   pspm_convert_au2unit converts arbitrary unit values to unit values. It works on a
%   PsPM file and is able to replace a channel or add the data as
%   a new channel.
%   Important features:
%   Given arbitrary unit values are converted using a recording distance D
%   given in 'unit', a reference distance Dref given in 'reference_unit', a
%   multiplicator A given in 'reference_unit'.
%   Before applying the conversion, the function takes the square root of the
%   input data if the recording method is area. This is performed to always
%   return linear units.
%   Using the given variables, the following calculations are performed:
%   0. Take square root of data if recording is 'area'.
%   1. Let from unit to reference_unit converted recording distance be Dconv.
%   2. x ← A*(Dconv/Dref)*x
%   3. Convert x from ref_unit to unit.
% ● Format
%   [sts, channel_index]  = pspm_convert_au2unit(fn, unit, distance, record_method,
%                           multiplicator, reference_distance, reference_unit, options)
%   [sts, converted_data] = pspm_convert_au2unit(data, unit, distance, record_method,
%                           multiplicator, reference_distance, reference_unit, options)
% ● Arguments
%   *            fn : Filename which contains the channels to be converted.
%   *          data : A one-dimensional vector which contains the data to be converted.
%   *          unit : To which unit the data should be converted. possible values are mm,
%                     cm, dm, m, in, inches.
%   *      distance : Distance between camera and eyes in units as specified in the
%                     parameter unit.
%   * record_method : Either 'area' or 'diameter', tells the function what the format of
%                     the recorded data is.
%   * multiplicator : The multiplicator in the linear conversion.
%   * reference_distance: Distance at which the multiplicator value was obtained, as
%                     specified in the parameter unit. The values will be proportionally
%                     translated to this distance before applying the conversion function.
%   * reference_unit : Reference unit with which the multiplicator and reference_distance
%                     values were obtained. Possible values are mm, cm, dm, m, in, inches.
%   ┌───────options
%   ├──────.channel : [optional][numeric/string] [Default: 'both']
%   │                 Channel ID to be preprocessed.
%   │                 To process both eyes, use 'both', which will work on 'pupil_r' and
%   │                 'pupil_l'.
%   │                 To process a specific eye, use 'pupil_l' or 'pupil_r'.
%   │                 To process the combined left and right eye, use 'pupil_c'.
%   │                 The identifier 'pupil' will use the first existing
%   │                 option out of the following:
%   │                 (1) L-R-combined pupil;
%   │                 (2) non-lateralised pupil;
%   │                 (3) best eye pupil;
%   │                 (4) any pupil channel.
%   │                 If there are multiple channels of the specified type, only last one
%   │                 will be processed. You can also specify the number of a channel.
%   └.channel_action : ['add'/'replace', default as 'add']
%                     Defines whether the new channel should be added or the previous
%                     outputs of this function should be replaced.
% ● Outputs
%   * channel_index : Index of channel containing the processed data.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Updated in 2024 by Dominik R Bach (University of Bonn)

%% initialise
global settings
if isempty(settings)
    pspm_init;
end
sts = -1;
outchannel = [];
%% load alternating inputs
if nargin < 1
    warning('ID:invalid_input', 'No arguments given. Don''t know what to do.');
    return;
elseif ischar(varargin{1})
    fn = varargin{1};
    mode = 'file';
    data  = -1;
elseif isnumeric(varargin{1})
    mode = 'data';
    data = varargin{1};
    fn = '';
end

if nargin < 2
    warning('ID:invalid_input','''unit'' is required.');
    return;
elseif nargin < 3
    warning('ID:invalid_input','''distance'' is required.');
    return;
elseif nargin < 4
    warning('ID:invalid_input', '''record_method'' is required.');
    return;
elseif nargin < 5
    warning('ID:invalid_input', '''multiplicator'' is required.');
    return;
elseif nargin < 6
    warning('ID:invalid_input', '''reference_distance'' is required.');
    return;
elseif nargin < 7
    warning('ID:invalid_input', '''reference_unit'' is required.');
    return;
else
    unit = varargin{2};
    distance = varargin{3};
    record_method = varargin{4};
    multiplicator = varargin{5};
    reference_distance = varargin{6};
    reference_unit = varargin{7};
    opt_idx = 8;
end

%% set default values
if nargin >= opt_idx
    options = varargin{opt_idx};
else
    options = struct();
end
options = pspm_options(options, 'convert_au2unit');
if options.invalid
    return
end

if ~(ismember(record_method, {'area', 'diameter'}))
    warning('ID:invalid_input', 'record_method must be ''area'' or ''diameter''');
    return;
end
if ~isnumeric(distance)
    warning('ID:invalid_input', 'distance must be a numeric value');
    return;
end
if ~isnumeric(multiplicator)
    warning('ID:invalid_input', 'multiplicator must be a numeric value');
    return;
end
if ~isnumeric(reference_distance)
    warning('ID:invalid_input', 'reference_distance must be a numeric value');
    return;
end

%% check values
if ~isnumeric(data)
    warning('ID:invalid_input', 'data is not numeric.');
    return;
elseif ~isnumeric(distance)
    warning('ID:invalid_input', 'distance is not numeric.');
    return;
end

%% main part
switch mode
    % try to load data
    case 'file'
        channel = options.channel;
        if strcmpi(channel, 'both')
            channel = {'pupil_r', 'pupil_l'};
        else
            channel = {channel};
        end
        [f_sts, alldata.infos, alldata.data] = pspm_load_data(fn);
        if f_sts < 1, return; end
        convert_data = {};
        for i = 1:numel(channel)
        [sts, channeldata, infos, pos_of_channel(i)] = pspm_load_channel(alldata, channel{i}, 'pupil');
            if sts < 1, return; end
            % recursive call to avoid the formula being stated twice in the same function
            [sts, convert_data.data{i}] = pspm_convert_au2unit(channeldata.data, unit, distance, record_method, ...
                multiplicator, reference_distance, reference_unit, options);
            if sts < 1, return; end
            convert_data{i}.header = channeldata.header;
            convert_data{i}.header.units = unit;
        end
        [f_sts, f_info] = pspm_write_channel(fn, convert_data, options.channel_action, struct('channel', pos_of_channel));
        if f_sts < 1, return; end
        outchannel = f_info.channel;
     % convert data
    case 'data'
        convert_data = data;
        if strcmpi(record_method, 'area')
            convert_data = sqrt(convert_data);
        end
        [~, distance] = pspm_convert_unit(distance, unit, reference_unit);
        convert_data = multiplicator * (distance / reference_distance) * convert_data;
        %% convert data from reference_unit to unit
        [~, convert_data] = pspm_convert_unit(convert_data, reference_unit, unit);
        outchannel = convert_data;
end
sts = 1;
