function [sts, scl] = pspm_sf_scl(model, options)
% ● Description
%   pspm_sf_scl returns the mean skin conductance level for an epoch
% ● Format
%   [sts, scl] = pspm_sf_scl(model, options)
% ● Arguments
%   ┌────────model
%   ├─────────.scr : skin conductance epoch (maximum size depends on computing power,
%   │                a sensible size is 60 s at 10 Hz)
%   ├──────────.sr : [numeric] [unit: Hz] sampling rate.
%   └.missing_data : [Optional] missing epoch data, originally loaded as model.missing
%                    from pspm_sf, but calculated into .missing_data (created
%                    in pspm_sf and then transferred to pspm_sf_dcm.
%   * options: the options struct (not used)
% ● Outputs
%   * scl    : scl outputs
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
scl = [];

% check input arguments
if nargin < 1
  warning('No data specified'); return;
end;
try model.scr; catch, warning('Input data is not defined.'); return; end
scl = mean(model.scr);
sts = 1;

