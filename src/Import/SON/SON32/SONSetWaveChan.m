function ret=SONSetWaveChan(fh, chan, sPhyCh, dvd, bufsize,...
                              comment, chantitle, scale, offset, units)
% SONSETWAVECHAN creates an ADC channel     
%
% RET=SONSETWAVECHAN(FH, CHAN, SPHYCH, DVD, BUFSIZE,...
%                               COMMENT, CHANTITLE, SCALE, OFFSET, UNITS)
%
%             FH = SON file handle
%             CHAN = the channel number for the new channel
%             SPHYCH = the physical channel number
%             DVD = the number of clock ticks per sample
%             BUFSIZE = the size of the internal buffer (up to 32768 bytes)
%             COMMENT = channel comment string
%             CHANTITLE = channel title string
%             SCALE = scale factor
%             OFFSET = offset
%             UNITS = channel units string
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

ret=calllib('son32', 'SONSetWaveChan',...
    fh, chan, sPhyCh, dvd, bufsize,comment, chantitle, scale, offset, units);                             