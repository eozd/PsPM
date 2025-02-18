function [sts, data] = pspm_get_blink_l(import)
% ● Description
%   pspm_get_blink_l is a common function for importing eyelink data
%   (blink_l data)
% ● Format
%   [sts, data]= pspm_get_blink_l(import)
% ● Arguments
%   ┌──import
%   ├───.data:  column vector of waveform data
%   ├──.units:  units of waveform data
%   └─────.sr:  sample rate
% ● History
%   Introduced in PsPM 4.0.2
%   Written in 2018 Laure Ciernik

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
% assign pupil data
data.data = import.data(:);
% add header
data.header.chantype = 'blink_l';
data.header.units = import.units;
data.header.sr = import.sr;
%% Return values
sts = 1;
return
