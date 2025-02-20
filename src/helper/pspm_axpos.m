function pos = axpos (rownum, colnum, leftmarg, rightmarg, upmarg, downmarg, inmarg)
% FORMAT 
% pos = axpos (rownum, colnum, leftmarg, rightmarg, upmarg,downmarg, inmarg)
% gets an axes number x 2 (x, y) matrix to be used in axes commands
%__________________________________________________________________________
% PsPM 3.0
% (C) 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% $Id$
% $Rev$

% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;
% -------------------------------------------------------------------------

height=(1-(upmarg+downmarg+(rownum-1)*inmarg))/rownum;
width=(1-(leftmarg+rightmarg+(colnum-1)*inmarg))/colnum;
ax=1;
for row=1:rownum
    for col=1:colnum
        pos(ax,1)=leftmarg+(col-1)*(width+inmarg);
        pos(ax,2)=downmarg+(rownum-row)*(height+inmarg);
        pos(ax,3)=width;
        pos(ax,4)=height;
        ax=ax+1;
    end
end
clear ax width height;