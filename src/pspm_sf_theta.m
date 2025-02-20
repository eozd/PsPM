function [theta, sr] = pspm_sf_theta
% ● Description
%   pspm_sf_theta returns parameter values for skin conductance response function f_SF.
% ● Format
%   [theta, sr] = pspm_sf_theta
% ● Developer
%   Estimated on 29-Jul-2009
% ● Outputs
%   *  theta : a vector as [theta1, theta2, theta3, theta4, theta5]
%   * theta1 : ODE parameter
%   * theta2 : ODE parameter
%   * theta3 : ODE parameter
%   * theta4 : delay parameter, should be the same as for aSCR model as there is no
%              explicit knowledge of SN bursts so it cannot be empirically determined
%              this was corrected on 12.05.2014
%   * theta5 : scaling parameter in log space, was slightly adapted on 12.05.2014 such
%              that an input with unit amplitude elicits a response with exactly unit
%              amplitude, see pspm_f_amplitude_check.m
%   *     sr : sampling rate.
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
theta = [0.923581    3.921034    2.159389    1.5339    1.6411756741];
sr = 10;
return
