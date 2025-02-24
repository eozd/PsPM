function ret=SONSetWaveMarkChan(fh, chan, sPhyCh, dvd, bufsize, comment,...
           chantitle, rate, scale, offset, units, points, pretrig, ntrace)
% SONSETWAVEMARKCHAN creates a REALMARK channel
% 
% RET=SONSETWAVEMARKCHAN(FH, CHAN, SPHYCH, DVD, BUFSIZE, COMMENT,...
%            CHANTITLE, RATE, SCALE, OFFSET, UNITS, POINTS, PRETRIG, NTRACE)
%
%             FH = SON file handle
%             CHAN = the channel number for the new channel
%             SPHYCH = the physical channel number
%             DVD = the number of clock ticks per sample
%             BUFSIZE = the size of the internal buffer (up to 32768 bytes)
%             COMMENT = channel comment string
%             CHANTITLE = channel title string
%             RATE = expected mean rate (only used in sampling)
%             SCALE = scale factor
%             OFFSET = offset
%             UNITS = channel units string
%             POINTS = number of extra data entries for each marker
%             PRETRIG = pre-trigger wvaeform points
%             NTRACE = number of interleaved traces (1 to 4)
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

ret=calllib('son32', 'SONSetWaveMarkChan',...
           fh, chan, sPhyCh, dvd, bufsize, comment,...
           chantitle, rate, scale, offset, units, points, pretrig, ntrace);                             