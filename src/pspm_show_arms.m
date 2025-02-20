function pspm_show_arms
% ● Developer
%   Happy Easter!
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

global settings
if isempty(settings)
  pspm_init;
end
pf = pspm_path('CologneCoatOfArms.jpg');
%pf = [settings.path, 'CologneCoatOfArms.jpg'];
P = imread(pf);
figure('Position', [40 40 300 400], 'MenuBar', 'none', 'Name', 'Viva Colonia', 'Color', 'k');
image(P);
axis image
axis off
return
