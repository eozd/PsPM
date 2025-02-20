function [sts, vd] = pspm_convert_mm2visdeg(mm, distance)
% SCR_CONVERT_MM2VISDEG converts milimeter values to visual degree values.
%
% It can work on PsPM files or on numeric vectors.
%
% FORMAT: 
%   [sts, vd] = pspm_convert_mm2visdeg(mm, distance)
%
% ARGUMENTS: 
%           mm:                 a numeric vector of milimeter values
%           distance:           distance between screen and eyes in meter
%               
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)

% $Id$
% $Rev$

% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;
sts = -1;

if ~isnumeric(mm)
    warning('ID:invalid_input', 'mm is not numeric');
elseif ~isnumeric(distance)
    warning('ID:invalid_input', 'distance is not numeric'); return;
end

d_mm = distance*1000;
vd = 2.*atan(mm ./ (2*d_mm)).*180./pi;
sts = 1;