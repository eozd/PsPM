function [sts, out_channel] = pspm_pupil_pp(fn, options)

% DEFINITION
% pspm_pupil_pp preprocesses pupil diameter signals given in any unit of measurement. It performs
% the steps described in [1]. This function uses a modified version of [2]. The modified version
% with a list of changes from the original is shipped with PsPM under pupil-size directory.
% The steps performed are listed below:
% 1.	Pupil preprocessing is performed in two main steps. In the first step, the “valid” samples
%	are determined. The samples that are not valid are not used in the second step. Determining
%	valid samples is done by
%	(a)	Range filtering: Pupil size values outside a predefined range are considered invalid.
%		This range is configurable.
%	(b)	Speed filtering: Speed is computed as the 1st difference of pupil size array normalized by
%		the temporal separation. Samples with speed higher than a threshold are considered invalid.
%		The threshold is configurable.
%	(c)	Edge filtering: Samples at both sides of temporal gaps in the data are considered invalid.
%		Both the duration of gaps and the invalid sample duration before/after the gaps are
%		configurable.
%	(d)	Trendline filtering: A data trend is generated by smoothing and interpolating the data.
%		Then, samples that are too far away from this trend are considered invalid.
%		These two steps are performed multiple times in an iterative fashion.
%		Note that the generated trend is not the final result of this function.
%		The smoothing, invalid threshold and the number of passes are configurable.
%	(e)	Isolated sample filtering: Isolated and small sample islands are
%		considered invalid. The size of the islands and the temporal separation
%		are configurable.
% 2.	In the second step, output smooth signal is generated using the valid
%	samples found in the previous step. This is done by performing filtering,
%	upsampling and interpolation. The parameters of the filtering and upsampling
%	are configurable. Once the pupil data is preprocessed, according to the
%	option 'channel_action', it will either replace an existing preprocessed
%	pupil channel or add it as new channel to the provided file.
%
% FORMAT
% [sts, out_channel] = pspm_pupil_pp(fn)
% [sts, out_channel] = pspm_pupil_pp(fn, options)
%
% VARIABLES
% fn		[string] Path to the PsPM file which contains the pupil data.
% options
% 	channel	[optional][numeric/string][Default: 'pupil']
% 			Channel ID to be preprocessed.
% 			Preprocessing raw eye data:
% 			The best eye is processed when channel is 'pupil'. To process a specific eye,
%			use 'pupil_l' or 'pupil_r'. To process the combined left and right eye, use 'pupil_lr'.
% 			Preprocessing previously processed data:
% 			Pupil channels created from other preprocessing steps can be further processed by this
%			function. To enable this, pass one of 'pupil_l_pp' or 'pupil_r_pp'. There is no best eye
%			selection in this mode. Hence, the type of the channel must be given exactly.
% 			Finally, a channel can be specified by its index in the given PsPM data structure. It
%			will be preprocessed as long as it is a valid pupil channel. If channel is specified as
%			a string and there are multiple channels with the exact same type, only last one will be
%			processed. This is normally not the case with raw data channels; however, there may be
%			multiple channels with same type if 'add' channel_action was previously used. This
%			feature can be combined with 'add' channel_action to create preprocessing histories
%			where the result of each step is stored as a separate channel.
%			.data 	field of the preprocessed channel contains the smoothed, upsampled
% 					signal that is the result of step 3 in [1].
% 			.header field of the preprocessed channel contains information regarding which samples
%					in the input signal were considered valid in addition to the usual information
%					of PsPM channels. This valid sample info is stored in .header.valid_samples
%					field.
% channel_combine	[optional][numeric/string][Default: 'none']
%			Channel ID to be used for computing the mean pupil signal. The input format is exactly
%			the same as the .channel field. However, the eye specified in this channel must be
%			different than the one specified in .channel field. By default, this channel is not
%			used. Only specify it if you want to combine left and right pupil eye signals, and in
%			this situation, the type of the output channel becomes 'pupil_lr_pp'.
% 	channel_action	[optional][string][Accepts: 'add'/'replace'][Default: 'add']
% 			Defines whether corrected data should be added or the corresponding preprocessed channel
%			should be replaced. Note that 'replace' mode does not replace the raw data channel, but a
%			previously stored preprocessed channel with a '_pp' suffix at the end of its type.
% 	custom_settings	[optional][Default: See pspm_pupil_pp_options above]
% 			Settings structure to modify the preprocessing steps. If not specified, the default
%			settings structure obtained from <a href="matlab:help pspm_pupil_pp_options">pspm_pupil_pp_options</a>
%			will be used. To modify certain fields of this structure, you only need to specify those
%			fields in custom_settings. For example, to modify settings.raw.PupilMin, you need to
%			create a struct with a field .raw.PupilMin.
% segments	[cell array of structures]
% 			Statistics about user defined segments can be calculated. When specified, segments will
%			be stored in .header.segments field.
% 			Each structure must have the the following fields:
% 			start	[decimal][Unit: second]
% 					Starting time of the segment
% 			end		[decimal][Unit: second]
% 					Ending time of the segment
% 			name	[string]
% 					Name of the segment. Segment will be stored by this name.
% 			plot_data	[Boolean][Default: false]
% 					Plot the preprocessing steps if true.
% 			out_channel	Channel ID of the preprocessed output.
%
% REFERENCE
% [1]	Kret, Mariska E., and Elio E. Sjak-Shie. "Preprocessing pupil size data:
%		Guidelines and code." Behavior research methods (2018): 1-7.
% [2]	https://github.com/ElioS-S/pupil-size
%
% (C) 2019 Eshref Yozdemir (University of Zurich)
% Updated 2021 Teddy Chao (WCHN, UCL)

%% 1 Initialise
global settings;
if isempty(settings)
  pspm_init;
end
sts = -1;

%% 2 Create default arguments
if nargin == 1
  options = struct();
end
if ~isfield(options, 'channel')
  options.channel = 'pupil';
end
if ~isfield(options, 'channel_action')
	options.channel_action = 'add';
end
if ~isfield(options, 'channel_combine')
	options.channel_combine = 'none';
end
if ~isfield(options, 'plot_data')
	options.plot_data = false;
end
[lsts, default_settings] = pspm_pupil_pp_options();
if lsts ~= 1
	return
end
if isfield(options, 'custom_settings')
	default_settings = pspm_assign_fields_recursively(default_settings, options.custom_settings);
end
options.custom_settings = default_settings;
if ~isfield(options, 'segments')
	options.segments = {};
end

%% 3 Input checks
if ~ismember(options.channel_action, {'add', 'replace'})
	warning('ID:invalid_input', 'Option channel_action must be either ''add'' or ''replace''');
	return
end
for seg = options.segments
	if ~isfield(seg{1}, 'start') || ~isfield(seg{1}, 'end') || ~isfield(seg{1}, 'name')
		warning('ID:invalid_input', 'Each segment structure must have .start, .end and .name fields');
		return
	end
end

%% 4 Load
action_combine = ~strcmp(options.channel_combine, 'none');
addpath(pspm_path('backroom'));
[lsts, data] = pspm_load_single_chan(fn, options.channel, 'last', 'pupil');
if lsts ~= 1
	return
end
if action_combine
	[lsts, data_combine] = pspm_load_single_chan(fn, options.channel_combine, 'last', 'pupil');
	if lsts ~= 1
		return
	end
	if strcmp(pspm_get_eye(data{1}.header.chantype), pspm_get_eye(data_combine{1}.header.chantype))
		warning('ID:invalid_input', 'options.channel and options.channel_combine must specify different eyes');
		return;
	end
	if data{1}.header.sr ~= data_combine{1}.header.sr
		warning('ID:invalid_input', 'options.channel and options.channel_combine data have different sampling rate');
		return;
	end
	if ~strcmp(data{1}.header.units, data_combine{1}.header.units)
		warning('ID:invalid_input', 'options.channel and options.channel_combine data have different units');
		return;
	end
	if numel(data{1}.data) ~= numel(data_combine{1}.data)
		warning('ID:invalid_input', 'options.channel and options.channel_combine data have different lengths');
		return;
	end
	old_chantype = sprintf('%s and %s', data{1}.header.chantype, data_combine{1}.header.chantype);
else
	data_combine{1}.data = [];
	old_chantype = data{1}.header.chantype;
end
rmpath(pspm_path('backroom'));

%% 5 preprocess
[lsts, smooth_signal] = pspm_preprocess(data, data_combine, options.segments, options.custom_settings, options.plot_data, 'pupil');
if lsts ~= 1
	return
end

%% 6 save
channel_str = num2str(options.channel);
o.msg.prefix = sprintf(...
	'Pupil preprocessing :: Input channel: %s -- Input chantype: %s -- Output chantype: %s --', ...
	channel_str, ...
	old_chantype, ...
	smooth_signal.header.chantype);
[lsts, out_id] = pspm_write_channel(fn, smooth_signal, options.channel_action, o);
if lsts ~= 1
	return
end
out_channel = out_id.channel;
sts = 1;
end
