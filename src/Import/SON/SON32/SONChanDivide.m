function [lDivide]=SONChanDivide(fh, chan)
% SONCHANDIVIDE returns the clock ticks per ADC value from the specified
% channel
% LDIVIDE=SONCHANDIVIDE(FH, CHAN)
%                             FH SON file handle
%                             CHAN Channel number
%
% See also SONGETUSPERTIME
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin ~= 2
    lDivide=-1000;
    return;
end


lDivide=calllib('son32','SONChanDivide',fh,chan);
return;
