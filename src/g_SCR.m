function [gx,dgdx,dgdPhi] = g_SCR(Xt,Phi,ut,inG)
% ● Description 
%   This is the SCR observation function required by the VBA toolbox. It 
%   adds the three generative processes (phasic SCR, SF, SCL) modelled in
%   f_SCR.
% ● Arguments
%     Xt: a 7-element vector
%    Phi: input required by VBA, ignored
%     ut: input required by VBA, ignored
%    inG: input required by VBA, ignored
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

global settings;
if isempty(settings), pspm_init; end
gx = Xt(1) + Xt(4) + Xt(7);
dgdx = zeros(size(Xt,1),1);
dgdx([1;4;7]) = 1;
dgdPhi = [];
if any(isnan(gx)|isinf(gx)), keyboard; end
if any(isnan(dgdx)|isinf(dgdx)), keyboard; end
