function [sts, auc] = pspm_sf_auc(model, options)
% ● Description
%   pspm_sf_auc returns the integral/area under the curve of an SCR time series
% ● Format
%   [sts, auc] = pspm_sf_auc(scr, sr, options)
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
%   *     auc : The calculated area under the curve.
% ● Reference
%   Bach DR, Friston KJ, Dolan RJ (2010). Analytic measures for the
%   quantification of arousal from spontanaeous skin conductance
%   fluctuations. International Journal of Psychophysiology, 76, 52-55.
% ● References
%   [1] Bach DR, Friston KJ, Dolan RJ (2010). Analytic measures for the
%       quantification of arousal from spontanaeous skin conductance
%       fluctuations. International Journal of Psychophysiology, 76, 52-55.
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
auc = [];

%% check input arguments
if nargin < 1
  warning('No data specified'); return;
end;
try model.scr; catch, warning('Input data is not defined.'); return; end
scr = model.scr;
scr = scr - min(scr);
auc = mean(scr);
sts = 1;
