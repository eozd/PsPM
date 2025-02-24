function err=SONSetEventChan(fh, chan, PhyCh, bufsize, comment, title, rate, kind)
% SONSETEVENTCHAN sets up a new event or marker channel
% 
% ERR=SONSETEVENTCHAN(FH, CHAN, PHYCH, BUFSZ, COMMENT, TITLE, RATE, KIND)
% INPUTS: FH the SON file handle
%         CHAN the channel number
%         PHYCH the physical channel number
%         BUFSZ size of the write buffer
%         COMMENT the channel comment
%         TITLE the channel title
%         RATE the ideal or expected rate
%         KIND is a string that sets the channel type:
%                  'EventRise', 'EventFall', 'EventBoth' or 'Marker'
%         
% Returns zero or a negative error code in ERR
% See CED documentation for details
%         
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London
        
global SON_CHANCOMSZ;                          
global SON_TITLESZ;

if (bufsize>32768)
    bufsize=32768;
end

comment=comment(1:min(length(comment),SON_CHANCOMSZ));
title=title(1:min(length(title),SON_TITLESZ));
switch  lower(kind)
    case {'eventfall'}
        type=2;
    case {'eventrise'}
        type=3;
    case {'eventboth'}
        type=4;
    case {'marker'}
        type=5;
    otherwise
        err=-1000;
        return;
end    
err=calllib('son32','SONSetEventChan',...
    fh, chan, PhyCh, bufsize, comment, title, rate, type);