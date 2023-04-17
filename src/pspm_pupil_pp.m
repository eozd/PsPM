function varargout = pspm_pupil_pp (fn, options)
% ● Description
%   pspm_pupil_pp preprocesses pupil diameter signals given in any unit of
%   measurement. It performs the steps described in [1]. This function uses
%   a modified version of [2]. The modified version with a list of changes
%   from the original is shipped with PsPM under pupil-size directory.
%   The steps performed are listed below:
%   1.  Pupil preprocessing is performed in two main steps. In the first
%       step, the “valid” samples are determined. The samples that are not
%       valid are not used in the second step. Determining valid samples is
%       done by
%	      (a) Range filtering: Pupil size values outside a predefined range
%           are considered invalid. This range is configurable.
%	      (b)	Speed filtering: Speed is computed as the 1st difference of
%           pupil size array normalized by the temporal separation. Samples
%           with speed higher than a threshold are considered invalid. The
%           threshold is configurable.
%	      (c)	Edge filtering: Samples at both sides of temporal gaps in the
%           data are considered invalid. Both the duration of gaps and the
%           invalid sample duration before/after the gaps are configurable.
%	      (d)	Trendline filtering: A data trend is generated by smoothing and
%           interpolating the data. Then, samples that are too far away
%           from this trend are considered invalid. These two steps are
%           performed multiple times in an iterative fashion. Note that the
%           generated trend is not the final result of this function. The
%           smoothing, invalid threshold and the number of passes are
%           configurable.
%	      (e)	Isolated sample filtering: Isolated and small sample islands
%           are considered invalid. The size of the islands and the
%           temporal separation are configurable.
%   2.  In the second step, output smooth signal is generated using the
%       valid samples found in the previous step. This is done by
%       performing filtering, upsampling and interpolation. The parameters
%       of the filtering and upsampling are configurable. Once the pupil
%       data is preprocessed, according to the option 'channel_action',
%       it will either replace an existing preprocessed pupil channel or
%       add it as new channel to the provided file.
% ● Format
%   [sts, out_channel] = pspm_pupil_pp(fn)
%   [sts, out_channel] = pspm_pupil_pp(fn, options)
% ● Arguments
%          fn:  [string]
%               Path to the PsPM file which contains the pupil data.
%   ┌──options: [struct]
%   ├────.channel: [optional][numeric/string][Default: 'pupil']
%   │           Channel ID to be preprocessed.
%   │           ▶ ︎Preprocessing raw eye data:
%   │           The best eye is processed when channel is 'pupil'. To
%   │           process a specific eye, use 'pupil_l' or 'pupil_r'.
%   │           To process the combined left and right eye, use 'pupil_lr'.
%   │           ▶ Preprocessing previously processed data:
%   │           Pupil channels created from other preprocessing steps can
%   │           be further processed by this function. To enable this, pass
%   │           one of 'pupil_l_pp' or 'pupil_r_pp'. There is no best eye
%   │           selection in this mode. Hence, the type of the channel must
%   │           be given exactly. Finally, a channel can be specified by
%   │           its index in the given PsPM data structure. It will be
%   │           preprocessed as long as it is a valid pupil channel. If
%   │           channel is specified as a string and there are multiple
%   │           channels with the exact same type, only last one will be
%   │           processed. This is normally not the case with raw data
%   │           channels; however, there may be multiple channels with same
%   │           type if 'add' channel_action was previously used. This
%   │           feature can be combined with 'add' channel_action to create
%   │           preprocessing histories where the result of each step is
%   │           stored as a separate channel.
%   ├────.data: field of the preprocessed channel contains the smoothed,
%   │           upsampled signal that is the result of step 3 in [1].
%   ├──.header: field of the preprocessed channel contains information
%   │           regarding which samples in the input signal were considered
%   │           valid in addition to the usual information of PsPM channels.
%   │           This valid sample info is stored in .header.valid_samples
%   │           field.
%   ├─.channel_combine:
%   │           [optional][numeric/string][Default: 'none']
%   │           Channel ID to be used for computing the mean pupil signal.
%   │           The input format is exactly the same as the .channel field.
%   │           However, the eye specified in this channel must be different
%   │           than the one specified in .channel field. By default, this
%   │           channel is not used. Only specify it if you want to combine
%   │           left and right pupil eye signals, and in this situation,
%   │           the type of the output channel becomes 'pupil_pp_c'.
%   ├─.channel_action:
%   │           [optional][string][Accepts: 'add'/'replace'][Default: 'add']
%   │           Defines whether corrected data should be added or the
%   │           corresponding preprocessed channel should be replaced. Note
%   │           that 'replace' mode does not replace the raw data channel,
%   │           but a previously stored preprocessed channel with a '_pp'
%   │           suffix at the end of its type.
%   ├─.custom_settings:
%   │           [optional][Default: See pspm_pupil_pp_options above]
%   │           Settings structure to modify the preprocessing steps. If
%   │           not specified, the default settings structure obtained from
%   │           <a href="matlab:help pspm_pupil_pp_options">pspm_pupil_pp_options</a>
%   │           will be used. To modify certain fields of this structure,
%   │           you only need to specify those fields in custom_settings.
%   │           For example, to modify settings.raw.PupilMin, you need to
%   │           create a struct with a field .raw.PupilMin.
%   ├─.segments:  [cell array of structures]
%   │           Statistics about user defined segments can be calculated.
%   │           When specified, segments will be stored in .header.segments
%   │           field. Each structure must have the the following fields:
%   ├─.start:   [decimal][Unit: second]
%   │           Starting time of the segment.
%   ├─.end:     [decimal][Unit: second]
%   │           Ending time of the segment.
%   ├─.name:    [string]
%   │           Name of the segment. Segment will be stored by this name.
%   ├─.plot_data:
%   │           [Boolean][Default: false or 0]
%   │           Plot the preprocessing steps if true.
%   └.out_chan: Channel ID of the preprocessed output.
% ● References
%   [1] Kret, Mariska E., and Elio E. Sjak-Shie. "Preprocessing pupil size
%       data: Guidelines and code." Behavior research methods (2018): 1-7.
%   [2]	https://github.com/ElioS-S/pupil-size
% ● History
%   Introduced in PsPM version ?
%   Written in 2019 by Eshref Yozdemir (University of Zurich)
%              2021 by Teddy Chao (UCL)
%   Maintained in 2022 by Teddy Chao (UCL)

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
%% 2 Create default arguments
if nargin == 1
  options = struct();
end
options = pspm_options(options, 'pupil_pp');
if options.invalid
  return
end
[lsts, default_settings] = pspm_pupil_pp_options();
if lsts ~= 1
  return
end
if isfield(options, 'custom_settings')
 default_settings = pspm_assign_fields_recursively(...
   default_settings, options.custom_settings);
end
options.custom_settings = default_settings;

%% 3 Input checks
if ~ismember(options.channel_action, {'add', 'replace'})
  warning('ID:invalid_input', ...
    'Option channel_action must be either ''add'' or ''replace''');
  return
end
for seg = options.segments
  if ~isfield(seg{1}, 'start') || ~isfield(seg{1}, 'end') || ~isfield(seg{1}, 'name')
    warning('ID:invalid_input', ...
      'Each segment structure must have .start, .end and .name fields');
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
  old_channeltype = sprintf('%s and %s', ...
    data{1}.header.chantype, data_combine{1}.header.chantype);
else
  data_combine{1}.data = [];
  old_channeltype = data{1}.header.chantype;
end
%% 5 preprocess
[lsts, smooth_signal, model] = pspm_preprocess(data, data_combine, ...
  options.segments, options.custom_settings, options.plot_data);
if lsts ~= 1
  return
end
%% 6 save
channel_str = num2str(options.channel);
o.msg.prefix = sprintf(...
  'Pupil preprocessing :: Input channel: %s -- Input channeltype: %s -- Output channeltype: %s --', ...
  channel_str, ...
  old_channeltype, ...
  smooth_signal.header.chantype);
[lsts, out_id] = pspm_write_channel(fn, smooth_signal, options.channel_action, o);
if ~lsts
  return
end
out_chan = out_id.channel;
sts = 1;
varargout{1} = sts;
switch nargout
  case 2
    varargout{2} = out_chan;
  case 3
    varargout{2} = out_chan;
    varargout{3} = model;
end
return

function varargout  = pspm_preprocess(data, data_combine, segments, custom_settings, plot_data)
sts = -1;
% 1 definitions
combining = ~isempty(data_combine{1}.data);
data_is_left = strcmpi(pspm_get_eye(data{1}.header.chantype), 'l');
n_samples = numel(data{1}.data);
sr = data{1}.header.sr;
diameter.t_ms = transpose(linspace(0, 1000 * (n_samples-1) / sr, n_samples));
if data_is_left
  diameter.L = data{1}.data;
  diameter.R = data_combine{1}.data;
else
  diameter.L = data_combine{1}.data;
  diameter.R = data{1}.data;
end
if size(diameter.L, 1) == 1
  diameter.L = transpose(diameter.L);
end
if size(diameter.R, 1) == 1
  diameter.R = transpose(diameter.R);
end
segmentStart = transpose(cell2mat(cellfun(@(x) x.start, segments, 'uni', false)));
segmentEnd = transpose(cell2mat(cellfun(@(x) x.end, segments, 'uni', false)));
segmentName = transpose(cellfun(@(x) x.name, segments, 'uni', false));
segmentTable = table(segmentStart, segmentEnd, segmentName);
new_sr = custom_settings.valid.interp_upsamplingFreq;
upsampling_factor = new_sr / sr;
desired_output_samples = round(upsampling_factor * numel(data{1}.data));
% 2 load lib
libbase_path = pspm_path('ext',['pupil', '-size'], 'code');
libpath = {fullfile(libbase_path, 'dataModels'), fullfile(libbase_path, 'helperFunctions')};
addpath(libpath{:});
% 3 filtering
model = PupilDataModel(data{1}.header.units, diameter, segmentTable, 0, custom_settings);
model.filterRawData();
if combining
  smooth_signal.header.chantype = pspm_update_channeltype(data{1}.header.chantype, {'pp', 'c'});
elseif contains(data{1}.header.chantype, '_pp')
  smooth_signal.header.chantype = data{1}.header.chantype;
else
  marker = strfind(data{1}.header.chantype, '_');
  marker = marker(1);
  smooth_signal.header.chantype = ...
    [data{1}.header.chantype(1:marker-1),...
    '_pp_',...
    data{1}.header.chantype(marker+1:end)];
end
smooth_signal.header.units = data{1}.header.units;
smooth_signal.header.sr = new_sr;
smooth_signal.header.segments = segments;
% 4 store signal and valid samples
try
  model.processValidSamples();
  if combining
    validsamples_obj = model.meanPupil_ValidSamples;
    smooth_signal.header.valid_samples.data_l = model.leftPupil_ValidSamples.samples.pupilDiameter;
    smooth_signal.header.valid_samples.sample_indices_l = model.leftPupil_RawData.isValid;
    smooth_signal.header.valid_samples.valid_percentage_l = model.leftPupil_ValidSamples.validFraction;
    smooth_signal.header.valid_samples.data_r = model.rightPupil_ValidSamples.samples.pupilDiameter;
    smooth_signal.header.valid_samples.sample_indices_r = model.rightPupil_RawData.isValid;
    smooth_signal.header.valid_samples.valid_percentage_r = model.rightPupil_ValidSamples.validFraction;
  else
    if data_is_left
      validsamples_obj = model.leftPupil_ValidSamples;
      rawdata_obj = model.leftPupil_RawData;
    else
      validsamples_obj = model.rightPupil_ValidSamples;
      rawdata_obj = model.rightPupil_RawData;
    end
    smooth_signal.header.valid_samples.data = validsamples_obj.samples.pupilDiameter;
    smooth_signal.header.valid_samples.sample_indices = find(rawdata_obj.isValid);
    smooth_signal.header.valid_samples.valid_percentage = validsamples_obj.validFraction;
  end
  smooth_signal.data = validsamples_obj.signal.pupilDiameter;
  smooth_signal.data = pspm_complete_with_nans(smooth_signal.data, validsamples_obj.signal.t(1), ...
    new_sr, desired_output_samples);
  % 5 store segment information
  if ~isempty(segments)
    seg_results = model.analyzeSegments();
    seg_results = seg_results{1};
    if combining
      seg_eyes = {'left', 'right', 'mean'};
    elseif data_is_left
      seg_eyes = {'left'};
    else
      seg_eyes = {'right'};
    end
    smooth_signal.header.segments = pspm_store_segment_stats(smooth_signal.header.segments, seg_results, seg_eyes);
  end
  if plot_data
    model.plotData();
  end
catch err
  % https://www.mathworks.com/matlabcentral/answers/225796-rethrow-a-whole-error-as-warning
  warning('ID:invalid_data_structure', getReport(err, 'extended', 'hyperlinks', 'on'));
  smooth_signal.data = NaN(desired_output_samples, 1);
end
rmpath(libpath{:});
sts = 1;
varargout{1} = sts;
switch nargout
  case 2
    varargout{2} = smooth_signal;
  case 3
    varargout{2} = smooth_signal;
    varargout{3} = model;
end
function data = pspm_complete_with_nans(data, t_beg, sr, output_samples)
% Complete the given data that possibly has missing samples at the
% beginning and at the end. The amount of missing samples is determined
% by sampling rate and the data beginning second t_beg.
sec_between_upsampled_samples = 1 / sr;
n_missing_at_the_beg = round(t_beg / sec_between_upsampled_samples);
n_missing_at_the_end = output_samples - numel(data) - n_missing_at_the_beg;
data = [NaN(n_missing_at_the_beg, 1) ; data ; NaN(n_missing_at_the_end, 1)];
function segments = pspm_store_segment_stats(segments, seg_results, seg_eyes)
stat_columns = {...
  'Pupil_SmoothSig_meanDiam', ...
  'Pupil_SmoothSig_minDiam', ...
  'Pupil_SmoothSig_maxDiam', ...
  'Pupil_SmoothSig_missingDataPercent', ...
  'Pupil_SmoothSig_sampleCount', ...
  'Pupil_ValidSamples_meanDiam', ...
  'Pupil_ValidSamples_minDiam', ...
  'Pupil_ValidSamples_maxDiam', ...
  'Pupil_ValidSamples_validPercent', ...
  'Pupil_ValidSamples_sampleCount', ...
  };
for eyestr = seg_eyes
  for colstr = stat_columns
    eyecolstr = [eyestr{1} colstr{1}];
    col = seg_results.(eyecolstr);
    for i = 1:numel(segments)
      segments{i}.(eyecolstr) = col(i);
    end
  end
end
function out_struct = pspm_assign_fields_recursively(out_struct, in_struct)
% Definition
% pspm_assign_fields_recursively assign all fields of in_struct to
% out_struct recursively, overwriting when necessary.
fnames = fieldnames(in_struct);
for i = 1:numel(fnames)
	name = fnames{i};
	if isstruct(in_struct.(name)) && isfield(out_struct, name)
		out_struct.(name) = pspm_assign_fields_recursively(out_struct.(name), in_struct.(name));
	else
		out_struct.(name) = in_struct.(name);
	end
end
function eye = pspm_get_eye(channeltype)
% Definition
% pspm_get_eye detect the eye location from an input channel type
%	FORMAT
%	eye = pspm_get_eye(channeltype)
% ARGUMENTS
%   Input
%     channeltype  a string that contains the eye location
%   Output
%     eye    		a character
% PsPM (version 5.1.2)
% (C) 2021 Teddy Chao (UCL)
eye = 'unknown';
for eye_attempt = ['l', 'r', 'c']
	if contains(channeltype, ['_', eye_attempt, '_'])
		eye = eye_attempt;
	elseif channeltype(length(channeltype)-1:length(channeltype)) == ['_', eye_attempt]
		eye = eye_attempt;
	end
end
if strcmp(eye, 'unknown')
	warning('ID:invalid_input', 'channeltype does not contain a valid eye');
	return
end