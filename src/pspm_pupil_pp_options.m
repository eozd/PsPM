function [sts, default_settings] = pspm_pupil_pp_options(custom_settings)
% ● Description
%   pspm_pupil_pp_options is a helper function that can be used to modify the
%   behaviour of pspm_pupil_pp function. This function returns the settings
%   structure used by pspm_pupil_pp for pupil preprocessing. You can modify the
%   returned structure and then pass it to pspm_pupil_pp. See below for
%   explanation of the parameters. Adapted from:
%   - src/ext/pupil-size/code/helperFunctions/rawDataFilter.m lines 63 to 149,
%   - src/ext/pupil-size/code/dataModels/ValidSamplesModel.m lines 357 to 373.
% ● Format
%   [sts, default_settings] = pspm_pupil_pp_options()
% ● Outputs
%   *  default_settings: Structure with the fields below.
%   ┌───────────────raw
%   │ 
%   │ // Allowable values criteria
%   │ 
%   ├─PupilDiameter_Min:  Minimum allowable pupil size. Pupil values less than 
%   │                     this value will be marked as invalid. (Default: 1.5)
%   ├─PupilDiameter_Max:  Maximum allowable pupil size. Pupil values greater than 
%   │                     thin value will be marked as invalid. (Default: 9.0)
%   │ 
%   │ // Isolated sample filter criteria
%   │ // 'Sample-islands' are clusters of samples that are temporally separated
%   │ // from other samples.
%   │ 
%   ├─islandFilter_islandSeperation_ms:
%   │                      Minimum distance used to consider samples 'separated'.
%   │                      (Default: 40 ms)
%   ├─islandFilter_minIslandWidth_ms:
%   │                      Minimum temporal width required to still consider
%   │                      a sample island valid. If the temporal width of the
%   │                      island is less than this value, all the samples in
%   │                      the island will be marked as invalid. (Default: 50 ms)
%   │ 
%   │ // Dilation speed filter criteria
%   │ 
%   ├─dilationSpeedFilter_MadMultiplier:
%   │                      Number of medians to use as the cutoff threshold
%   │                      when applying the speed filter. (Default: 16)
%   ├─dilationSpeedFilter_maxGap_ms:
%   │                      Only calculate the speed when the gap between samples
%   │                      is smaller than this value. (Default: 200 ms)
%   │ 
%   │ // Edge removal filter criteria
%   │ // Sometimes gaps in the data after the dilation speed filter feature
%   │ // artifacts at their edges. These artifacts are not always removed by
%   │ // the dilation speed filter; as such, samples arounds these gaps may
%   │ // also need to be marked as invalid. The settings below indicate when a
%   │ // section of missing data is classified as a gap (samples around these
%   │ // gaps are in turn rejected).
%   │ 
%   ├─gapDetect_minWidth:  Minimum width of a missing data section that causes
%   │                      it to be classified as a gap. (Default: 75 ms)
%   ├─gapDetect_maxWidth:  Maximum width of a missing data section that causes
%   │                      it to be classified as a gap. (Default: 2000 ms)
%   ├─gapPadding_backward: The section right before the start of a gap within
%   │                      which samples are to be rejected. (Default: 50 ms)
%   ├─gapPadding_forward:  The section right after the end of a gap within
%   │                      which samples are to be rejected. (Default: 50 ms)
%   │ 
%   │ // Deviation filter criteria
%   │ // At this point a subset of the original samples are marked as valid.
%   │ // These samples are the input for this filter. The dilation speed
%   │ // filter will not reject samples that do not feature outlying speeds,
%   │ // such as is the case when these samples are clustered together. As
%   │ // such, a deviation from a smooth trend-line filter is warranted.
%   │ 
%   ├─residualsFilter_passes:
%   │                      Number of passes the deviation filter makes. 
%   │                      (Default: 4)
%   ├─residualsFilter_MadMultiplier:
%   │                      The multiplier used when defining the threshold.
%   │                      Threshold equals this multiplier times the median.
%   │                      After each pass, all the input samples that are
%   │                      outside the threshold are removed. Note that all
%   │                      samples (even the ones which may have been rejected
%   │                      by the previous deviation filter pass) are 
%   │                      considered. (Default: 16)
%   │
%   │ // At each pass, a smooth continuous trend line is generated using the
%   │ // data below, from which the deviation is than calculated and used as
%   │ // the filter criteria. The below computation is performed:
%   │ // [lowpassB, lowpassA] = butter(1, lowpassCF/(interpFs/2));
%   │ 
%   ├─residualsFilter_interpFs:
%   │                      Fs for first order Butterworth filter.
%   │                      (Default: 100 Hz)
%   ├─residualsFilter_lowpassCF:
%   │                      Cutoff frequency for first order Butterworth filter. 
%   │                      (Default: 16 Hz)
%   │
%   ├─residualsFilter_lowpassB:
%   │                      Numerator (B) coefficients of the first-order 
%   │                      Butterworth filter used in the residuals filter passes.
%   │                      Automatically computed from residualsFilter_lowpassCF  
%   │                      and residualsFilter_interpFs.
%   ├─residualsFilter_lowpassA:
%   │                      Denominator (A) coefficients of the first-order 
%   │                      Butterworth filter used in the residuals filter
%   │                      passes. Automatically computed.
%   │
%   │ // Keep filter data
%   │
%   └───────keepFilterData:If true, intermediate filter data will be stored.
%                          Set to false to save memory and improve plotting
%                          performance. (Default: true)
%            
%   ┌───────────────valid
%   ├interp_upsamplingFreq:The upsampling frequency used to generate the smooth
%   │                      signal. (Default: 1000 Hz)
%   ├───────interp_maxGap: Maximum gap in the used (valid) raw samples to
%   │                      interpolate over. Sections that were interpolated
%   │                      over distances larger than this value will be set
%   │                      to NaN. (Default: 250 ms)
%   │ 
%   │  // For final data smoothing, the below computation is performed:
%   │  // [LpFilt_B, LpFilt_A]  = butter(LpFilt_order, ...
%   │  //               2*LpFilt_cutoffFreq/interp_upsamplingFreq );
%   │
%   ├────LpFilt_cutoffFreq:The cutoff frequency (in Hz) for the low-pass Butterworth filter
%   │                      that is applied to the upsampled signal. (Default: 4 Hz)
%   ├─────────LpFilt_order:The order of the Butterworth filter used on the 
%   │                      upsampled signal. (Default: 4)
%   ├─────────────LpFilt_B:The numerator coefficients of the digital Butterworth 
%   │                      low-pass filter. Automatically computed.
%   └─────────────LpFilt_A:The denominator coefficients of the digital 
%                          Butterworth low-pass filter. Automatically computed.
%       
%   
% ● History
%   Introduced In PsPM version ?.
%   Written in 2019 by Eshref Yozdemir (University of Zurich)
%   Maintained in 2022 by Teddy
%   Maintained in 2024 by Bernhard von Raußendorf

global settings
if isempty(settings)
  pspm_init;
end

sts = -1;
default_settings = struct(); 

if nargin < 1
    flag = 0;
elseif ~isstruct(custom_settings)
    warning('Input must be a struct. Returning default settings.');
    flag = 0;
else
    flag = 1;
end



if nargin == 1 && flag == 1

    reqFieldsRaw = {'residualsFilter_interpFs','residualsFilter_lowpassCF'};
    if isfield(custom_settings,'raw') && all(isfield(custom_settings.raw, reqFieldsRaw))
        % from src/ext/pupil-size/code/helperFunctions/rawDataFilter.m
      
        [custom_settings.raw.residualsFilter_lowpassB , custom_settings.raw.residualsFilter_lowpassA]   ...
            = butter(1 , custom_settings.raw.residualsFilter_lowpassCF/(custom_settings.raw.residualsFilter_interpFs/2) );
    else
        warning('Missing required fields in custom_settings.raw: Default filter coefficients will be used.'); % change
    end

    reqFieldsValid = {'LpFilt_cutoffFreq','interp_upsamplingFreq','LpFilt_order'};
    if isfield(custom_settings,'valid') && all(isfield(custom_settings.valid, reqFieldsValid))
        % settingsOut = getDefaultSettings() from ValidSamplesModel
        [custom_settings.valid.LpFilt_B, custom_settings.valid.LpFilt_A] = butter(custom_settings.valid.LpFilt_order, ...
            2*custom_settings.valid.LpFilt_cutoffFreq/custom_settings.valid.interp_upsamplingFreq );
    else
        warning('Missing required fields in custom_settings.valid: Default filter coefficients will be used.'); % change
    end    

end


libbase_path = pspm_path('ext','pupil-size', 'code');
libpath = {fullfile(libbase_path, 'dataModels'), fullfile(libbase_path, 'helperFunctions')};
addpath(libpath{:});
default_settings = PupilDataModel.getDefaultSettings();

% gets 
default_settings.valid.LpFilt_cutoffFreq   = 4; % could also be added to the default_settings in ValidSamplesModel
default_settings.valid.LpFilt_order        = 4; % could also be added to the default_settings in ValidSamplesModel

if nargin == 1 && flag == 1 
    default_settings = pspm_assign_fields_recursively(default_settings, custom_settings);
end


rmpath(libpath{:});
sts = 1;
return
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

end