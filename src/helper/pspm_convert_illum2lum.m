function [luminance] = pspm_convert_illum2lum(illuminance, distance, display_size, aspect)
% SCR_CONVERT_ILLUM2LUM converts illuminance values into luminance values
%
% FORMAT: [luminance] = pspm_convert_illum2lum(illuminance, distance, display_size, aspect)
%
% ARGUMENTS: 
%   
%      illuminance:         The measured illuminance value in lux.
%      distance:            Distance between eye and screen in m.
%      display_size:        Size of the display in Inch
%      aspect:              Struct containing two aspect ratios of the
%                           screen.
%           actual:         States the actual aspect ratio of the screen.
%                           Default is [16 9].
%           used:           States the aspect ratio which was set on the
%                           screen. If is not set, is automatically set to
%                           the value of aspect.actual.
%__________________________________________________________________________
% PsPM 3.0
% (C) 2008-2015 Tobias Moser (University of Zurich)

% $Id$
% $Rev$

% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;


if nargin < 4 || isempty(aspect) || ~isstruct(aspect)
    aspect = struct();
end

if ~isfield(aspect, 'actual')
    aspect.actual = [16 9];
end

if ~isfield(aspect, 'used')
    aspect.used = aspect.actual;
end

d_size_m = display_size*2.54/100;

h = d_size_m/sqrt((aspect.actual(1)/aspect.actual(2))^2 + 1);
w = (aspect.used(1)/aspect.used(2))*h;

luminance    = ( illuminance*(distance^2) ) / ( h * w );
