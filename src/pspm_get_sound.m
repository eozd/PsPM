function [sts, data] = pspm_get_sound(import)
% ● Description
%   pspm_get_sound is a common function for importing sound data.
% ● Format
%   [sts, data] = pspm_get_sound(import)
% ● Arguments
%   ┌─import
%   ├──.data : column vector of waveform data.
%   ├─.units : units of data.
%   └────.sr : sample rate.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Tobias Moser (University of Zurich)

%% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
% assign respiratory data
data.data = import.data(:);
% add header
data.header.chantype = 'snd';
data.header.units = import.units;
data.header.sr = import.sr;
% check status
sts = 1;
return
