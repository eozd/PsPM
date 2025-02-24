function ret=SONWriteEventBlock(fh, chan, buffer, count)
% SONWRITEEVENTBLOCK writes data to an ADC channel
% 
% RET=SONWRITEEVENTBLOCK(FH, CHAN, BUFFER, COUNT)
% INPUTS: FH the SON file handle
%         CHAN the target channel
%         BUFFER the data to be written containing int32 timestamps
%         COUNT the number of data items to write from buffer
%         
% Returns zero or a negative error code.
% 
% For efficient use of disc space, COUNT should be  a multiple of 
% (BUFSIZE bytes - 20)/4 , where BUFSIZE is supplied in a prior call to
% SONSETEVENTCHAN (20 is the size of the block header on disc)
% 
% see CED documentation
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if (strcmp(class(buffer),'int32'))
    ret=calllib('son32','SONWriteEventBlock', fh, chan, buffer, count);
else
    ret=-22;
end