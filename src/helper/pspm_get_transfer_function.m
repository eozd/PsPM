function pspm_get_transfer_function(infile, outfile, Rs, Rtest, scrchan, skipvalues)
% SCR_GET_TRANSFER_FUNCTION automatically reads a calibration spike 2 dataset and
% estimates a transfer function, assuming non linear transfer due to
% (known) serial resistors in the fMRI equipment and an offset in the pulse
% converter
%
% FORMAT:
% pspm_get_transfer_function(SCR file, output file, serial resistor value, 
% [test resistor value, scr channel number, skipvalues])
%
% where SCR file is either an .smr file or an SCRalyze file
% DEFAULTS: 
% test resistors: load from pspm_filtestbox.mat (equivalent to value
% 'filtestbox')
% scr channel number: look for scr channel number
%
% if the calibration dataset contains multiple channels, the SCR channel
% name must contain 'scr', 'gsr' or 'eda', or the channel number must be
% given as input argument
%
% each resistor value needs to be measured for at least 5 seconds, 
% after the last (highest) resistor, the circuit needs to be interrupted 
% for at least 2 seconds to get pulse offset
%
% RETURNS:
% a .mat file is automatically written that will contain a values for 
% pspm_transfer_function.m
% graphical output is presented on the screen and to a file
%
%__________________________________________________________________________
% PsPM 
% (C) 2008 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% $Id$
% $Rev$

% CONSTANTS
global settings;
if isempty(settings), pspm_init; end;

% chars to identify SCR channel 
scrnames=settings.import.channames.scr;

% check input argumens
if nargin<5, scrchan=0; end;
if nargin<6,skipvalues=0; end;

% check testresistors
if nargin>=4
    if ischar(Rtest)
        if strcmp(Rtest, 'filtestbox')
            k=1000;
            % load the "true", measured resistor values for the FIL testbox
            load('pspm_filtestbox.mat');
        end
    end
else
    load('pspm_filtestbox.mat');
end

% check input file
if exist(infile)~=2
    errmsg='Data file not found'; warning(errmsg); return;
end

% check output file
[pathname filename]=fileparts(outfile);
outfile=fullfile(pathname, filename);
clear pathname filename extension vers;

% import data
[pth fn ext] = fileparts(infile);
switch ext
    case {'.smr'}
        import{1}.type = 'scr';
        import{1}.channel = scrchan;
        options = struct('overwrite', 1);
        newfn = pspm_import(infile, 'spike', import, options);
      
    case {'.mat'}
        newfn = infile;
end

[sts infos data] = pspm_load_data(newfn{1}, 'scr');
if sts == -1, warning('Data could not be loaded'); return; end;
scr = data{1}.data;
sr  = data{1}.header.sr;



% identify resistance steps
% -------------------------------------------------------------------------
% - create smoothed scr series
scrs = conv(scr, ones(round(sr/5), 1)./round(sr/5));
% - find possible offset (last value)
offset = scrs(end-sr);
% - set dummy (infinite) offset resistor
Rtest(end + 1) = 1e100;
% - initialise
point(1)=find(scrs>1.5*offset, 1);
% - loop over resistor values
for step=1:(numel(Rtest) - 1)
    % look at std in second 2-4
    x(step)  = mean(scrs(round((point(step)+2*sr):(point(step)+4*sr))));
    sd(step) = std(scrs(round((point(step)+2*sr):(point(step)+4*sr))));
    % look for deviation > 3*sd and > .2 * expected change
    nextx = (Rtest(step) + Rs) .* (x(step) - offset) ./ (Rtest(step + 1) + Rs) + offset;
    nextdiff = x(step) - nextx;
    cutoff = max([0.2*nextdiff, 3*sd(step)]);
    ind = round((point(step)+4*sr):numel(scrs));
    dummy = find(scrs(ind) < (x(step) - cutoff), 1);
    if isempty(dummy); warning('Resistance change not found'); return; end;
    point(step + 1) = ind(1) + dummy;
end
% - delete dummy Rtest
Rtest(end) = [];

% - get end of file
if numel(scr) > (point(end) + 5 * sr)
    point(end + 1) = numel(scr);
end

% identify corresponding pulse frequencies
for step=1:(numel(point)-1)
    pulse(step)=mean(scr((point(step)+1*sr):(point(step+1)-1*sr)));
end

% now estimate transfer function
if numel(point)>(numel(Rtest)+1)
    offset=pulse(end);
    PR=pulse(1:(end-1))-offset;
else
    offset=0;
    PR=pulse;
end
R=Rtest+Rs;

% get rid of values to be skipped
PR=PR((skipvalues+1):end);
R=R((skipvalues+1):end);

%estimate values
init_value = 50; % if estimation doesn't work, change start to an approximation
LB = 1e-10;
UB = inf;
options=optimset('Display','off','TolFun',1e-20, 'LargeScale','off', 'MaxFunEvals', 1000, 'Algorithm', 'active-set');
c = fmincon('pspm_transfer_fit',init_value,[],[],[],[],LB,UB,[],options, R, PR);
% write transfer function values
if exist(outfile)==2
    overwrite=menu('File already exists. Overwrite?', 'Yes', 'No');
else
    overwrite=1;
end
if overwrite==1
    infos.date=date;
    infos.data=infile;
    save([outfile, '.mat'], 'infos', 'c', 'Rs', 'offset');
end
% make figures for graphical output
fig.h=figure('Position', [100 100 800 1000], 'PaperPositionMode', 'auto', 'PaperOrientation', 'Portrait', 'InvertHardCopy', 'off', 'Color', 'w');
annotation('textbox', [0.1 0.9 0.8 0.1], 'String', ['Transfer function estimation of ', date], 'FontWeight', 'Bold', 'FontSize', 16, 'LineStyle', 'none', 'HorizontalAlignment', 'center');
pos=pspm_axpos(2,1,0.05,0.05,0.1,0.2,0.05);
% show recognition of resistor 
fig.ax(1).h=axes('Position', pos(1,:));
plot(scr, 'r');
hold on
scatter(point, scr(point), 'g'); 
scatter(point(1:end-1)+diff(point)/2, pulse, 'b')
legend({'pulse rate', 'resistor change', 'mean pulse rate'});
title('Separation of resistor values', 'FontWeight', 'Bold', 'FontSize', 14);
set(fig.ax(1).h, 'FontWeight', 'Bold', 'FontSize', 10, 'XTick', []);
% show fit of transfer function
fig.ax(2).h=axes('Position', pos(2,:));
scatter(1:numel(PR), 1e6./Rtest((skipvalues+1):end), 'b');
hold on
scatter(1:numel(PR), 1./(c./PR-(1e-6)*Rs), 'r');
legend({'conductance of resistors (mcS)', 'conductance predicted from pulse rate (mcS)'});
title( 'Predicted and true conductance values', 'FontWeight', 'Bold', 'FontSize', 14);
me=max(1./Rtest((skipvalues+1):end).*1e6-1./(c./PR-Rs));
set(fig.ax(2).h, 'FontWeight', 'Bold', 'FontSize', 10, 'XTick', []);
% give values
if skipvalues>0
    annotation('textbox', [0.1 0.15 0.8 0.05], 'String', sprintf('First %d value(s) skipped', skipvalues), 'FontWeight', 'Bold', 'FontSize', 10, 'LineStyle', 'none');
end    
annotation('textbox', [0.1 0.12 0.8 0.04], 'String', ['Maximum Difference (true/pred): ', num2str(me, '%0.2f'), ' mcS'], 'FontWeight', 'Bold', 'FontSize', 10, 'LineStyle', 'none');
annotation('textbox', [0.1 0.09 0.8 0.04], 'String', 'Transfer function: C_B_o_d_y = (c/(data-offset)-Rs*1e-6)^-^1', 'FontWeight', 'Bold', 'FontSize', 10, 'LineStyle', 'none');
annotation('textbox', [0.1 0.06 0.8 0.04], 'String', ['c = ', num2str(c, '%0.2f')], 'FontWeight', 'Bold', 'FontSize', 10, 'LineStyle', 'none');
annotation('textbox', [0.1 0.03 0.8 0.04], 'String', ['offset = ', num2str(offset, '%0.2f')], 'FontWeight', 'Bold', 'FontSize', 10, 'LineStyle', 'none');
annotation('textbox', [0.1 0.00 0.8 0.04], 'String', ['written to ', outfile, '.mat'], 'FontWeight', 'Bold', 'FontSize', 10, 'LineStyle', 'none', 'Interpreter', 'none');
print ('-depsc', outfile)




