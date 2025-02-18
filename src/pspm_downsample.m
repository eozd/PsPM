function [sts, data, newsr] = pspm_downsample(data, sr,sr_down)
% ● Description
%   pspm_downsample performs a downsampling (resampling) operation on 
%   the provided data. Currently used by used by pspm_prepdata & pspm_dcm
%   
% ● Format
%           [sts, data, newsr] = pspm_downsample(data, sr,sr_down)
%
% ● Arguments
%   *        data:    the input data for performing downsampling on.
%   *        sr:      original sampling rate of the input data.
%   *        sr_down: targeted downsampling rate.
%
% ● Output
%   *       sts: -1 if the frequency ratio is not an integer
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy Chao
%   Maintained in 2024 by Bernhard von Raußendorf

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

%% 2 Check input arguments
if nargin < 2
  warning('Not enough input arguments.'); return
end

%% 3 Performing downsampling

freqratio = sr/sr_down;

if freqratio == ceil(freqratio) % NB isinteger might not work for some values
    % this gives the same output as the signal processing toolbox function
    % downsample(data, freqratio)
    data = data(1:freqratio:end); % from old pspm_downsample
    newsr = sr_down;
    sts = 1;
elseif settings.signal
    % this uses a filter and is therefore not used for integer sampling
    % ratio. It allows real sr ratios but requires integer initial and final sr
    if sr == floor(sr) && sr_down == floor(sr_down)
        data = resample(data, sr_down, sr);
        newsr = sr_down;
    else
        % use a crude but very general way of getting to integer numbers by
        % changing the new sampling rate
        altsr = round(sr);
        altdownsr = round(sr_down);
        data = resample(data, altdownsr, altsr);
        newsr = sr * altdownsr/altsr;
        warning('ID:freq_change', 'The desired downsample rate was changed.');
    end
    sts = 1;
else
    sts = -1;
    warning('ID:nonint_sr', 'Downsampling failed because signal processing toolbox is not installed and downsampling ratio is non-integer.');
    % the function returns the original data
end


