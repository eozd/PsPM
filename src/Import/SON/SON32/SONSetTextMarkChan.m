function ret=SONSetTextMarkChan(fh, chan, sPhyCh, bufsize,...
                              comment, chantitle, rate, units, points)
% SONSETTEXTMARKCHAN creates a TEXTMARK channel
%             FH = SON file handle
%             CHAN = the channel number for the new channel
%             SPHYCH = the physical channel number
%             BUFSIZE = the size of the internal buffer (up to 32768 bytes)
%             COMMENT = channel comment string
%             CHANTITLE = channel title string
%             RATE = the expected data rate (during sampling)
%             UNITS = channel units string
%             POINTS = maximum number of characters per marker
%
% Returns zero or a negagtive error
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

ret=calllib('son32', 'SONSetTextMarkChan',...
                    fh, chan, sPhyCh, bufsize,...
                              comment, chantitle, rate, units, points);                             