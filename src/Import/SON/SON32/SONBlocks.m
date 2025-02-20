function nblocks=SONBlocks(fh,chan)
% SONBLOCKS returns the number of blocks written to disk for the channel
% [NBLOCKS]=SONBLOCKS(FH,CHAN)
%                    FH  SON file handle
%                    CHAN is the channel number from 0 to SONMAXCHANS-1
% Returns 0 or the number of blocks;
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin ~= 2
    nblocks=-1000;
    return;
end

nblocks=calllib('son32','SONBlocks',fh,chan);
return;
