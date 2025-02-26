function [sts, eye, new_chantype] = pspm_find_eye(chantype)
% ● Description
%   pspm_get_eye detects the eye location ('l', 'r', 'c', '') from an
%   eyetracker channel type
% ● Format
%   [sts, eye, new_chantype] = pspm_find_eye(chantype)
% ● Arguments
%   *     chantype: the field header.chantype as returned by pspm_load_data
% ● Outputs
%   *          eye:  one of {'r', 'l', 'c', ''}
%   * new_chantype:  chantype with eye marker removed
% ● History
%   Introduced in PsPM version 5.1.2
%   Written in 2021 by Teddy

global settings
if isempty(settings)
  pspm_init;
end

sts = -1;
eye = '';
new_chantype = '';

if ~contains(chantype, settings.eyetracker_channels)
    warning('ID:invalid_input', 'This function only allows eyetracker input');
    return
end

for eye_attempt = [settings.lateral.char.l, settings.lateral.char.r, settings.lateral.char.c]
  if strcmpi(chantype(length(chantype)-1:length(chantype)), ['_', eye_attempt])
    eye = eye_attempt;
  end
end

if strcmpi(eye, '')
    new_chantype = chantype;
else
    new_chantype = chantype(1:(end-2));
end

sts = 1;
