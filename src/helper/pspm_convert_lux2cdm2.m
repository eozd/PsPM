function [sts, cd] = pspm_convert_lux2cdm2(lux, screen)
% SCR_CONVERT_LUX2CDM2 converts lux values to cd/m^2 values. In other words
% a conversion from illuminance (what we measure with the light meter) to
% luminance
%
% It can work on PsPM files or on numeric vectors.
% 
%
% FORMAT: 
%   [sts, cd] = pspm_convert_lux2cdm2(lux, screen)
%
% ARGUMENTS: 
%           lux:                a numeric vector of lux values
%           screen:             a struct with the following fields
%               diameter:       screen diameter in inches
%               distance:       distance between screen and eyes in meter
%               aspect_actual:  actual aspect ratio of the screen (property
%                               of the hardware). a 1x2 vector is espected 
%                               e.g. [16 9]
%               aspect_used:    used aspect ratio of the screen (set in the
%                               software) (optional). a 1x2 vector is 
%                               expected e.g. [5 4]
%__________________________________________________________________________
% PsPM 3.1
% (C) 2016 Tobias Moser (University of Zurich)
%
% $Id$
% $Rev$
%
% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;
sts = -1;


if ~isnumeric(lux)
    warning('ID:invalid_input', 'Lux is not numeric.'); return;
elseif ~isstruct(screen)
    warning('ID:invalid_input', 'Screen is not a struct.'); return;
elseif ~isfield(screen, 'diameter') || ~isnumeric(screen.diameter)
    warning('ID:invalid_input', 'screen.diameter does not exist or is not numeric.');
elseif ~isfield(screen, 'distance') || ~isnumeric(screen.distance)
    warning('ID:invalid_input', 'screen.distance does not exist or is not numeric.');
elseif ~isfield(screen, 'aspect_actual') || ~isnumeric(screen.aspect_actual)
    warning('ID:invalid_input', 'screen.aspect_actual does not exist or is not numeric.'); return;
elseif isfield(screen, 'aspect_used') && ~isnumeric(screen.aspect_used)
    warning('ID:invalid_input', 'screen.aspect_used is not numeric.'); return;
end

% default value from aspect_actual
if ~isfield(screen, 'aspect_used')
    screen.aspect_used = screen.aspect_actual;
end

% do conversion
dia_cm = screen.diameter*2.54;
h = sqrt((screen.aspect_actual(2)*dia_cm)^2 / (sum(screen.aspect_actual.^2)))/100;
w = h*screen.aspect_used(1)/screen.aspect_used(2)/100;

cd = (lux.*screen.distance^2)/(h*w);
sts = 1;





