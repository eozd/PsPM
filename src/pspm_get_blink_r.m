function [sts, data] = pspm_get_blink_r(import)
% ● Description
%   pspm_get_blink_r is a common function for importing eyelink data
%   (blink_r data)
% ● Format
%   [sts, data] = pspm_get_blink_r(import)
% ● Arguments
%   ┌────import
%   ├─────.data : column vector of waveform data
%   ├────.units : units of waveform data
%   └───────.sr : sample rate
% ● History
%   Introduced in PsPM 4.0.2
%   Written in 2018 by Laure Ciernik

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
%% Processing
% assign pupil data
data.data = import.data(:);
% add header
data.header.chantype = 'blink_r';
data.header.units = import.units;
data.header.sr = import.sr;
%% Return values
sts = 1;
return
