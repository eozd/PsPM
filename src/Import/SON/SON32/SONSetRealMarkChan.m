function ret=SONSetRealMarkChan(fh, chan, sPhyCh, bufsize, comment,...
                chantitle, rate, minimum, maximum, units, points)
% SONSETREALMARKCHAN creates a REALMARK channel
%
% RET=SONSETREALMARKCHAN(FH, CHAN, SPHYCH, BUFSIZE, COMMENT,...
%                 CHANTITLE, RATE, MINIMUM, MAXIMUM, UNITS, POINTS)
%             FH = SON file handle
%             CHAN = the channel number for the new channel
%             SPHYCH = the physical channel number
%             BUFSIZE = the size of the internal buffer (up to 32768 bytes)
%             COMMENT = channel comment string
%             CHANTITLE = channel title string
%             RATE = expected mean rate (only used in sampling)
%             MAXIMUM = approximate maximum value (for display only)
%             MINIMUM = approximate minimum value (for display only)
%             UNITS = channel units string
%             POINTS = number of extra data entries for each marker
%
% Returns zero or a negative error
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

global SON_CHANCOMSZ;                          
global SON_UNITSZ;
global SON_TITLESZ;

if (bufsize>32768)
    bufsize=32768;
end

comment=comment(1 : min(length(comment), SON_CHANCOMSZ));                             
chantitle=chantitle(1 : min(length(chantitle), SON_TITLESZ));    
units=units(1 : min(length(units), SON_UNITSZ)); 

ret=calllib('son32', 'SONSetRealMarkChan',...
                     fh, chan, sPhyCh, bufsize,...
                        comment, chantitle, rate, minimum, maximum, units, points); 
                    