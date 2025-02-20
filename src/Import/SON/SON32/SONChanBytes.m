function [bytes]=SONChanBytes(fh, chan)
% SONCHANBYTES returns the number of bytes written, or buffered, on the 
% specified channel
% BYTES=SONCHANBYTES(FH, CHAN)
%                     FH SON file handle
%                     CHAN Channel number 0 to SONMAXCHANS-1
% 
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin ~= 2
    bytes=-1000;
    return;
end


bytes=calllib('son32','SONChanBytes',fh,chan);
return;