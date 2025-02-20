function rate=SONIdealRate(fh, chan, newrate)
% SONIDEALRATE gets or sets the ideal sampling rate on a channel
%
% RATE=SONIDEALRATE(FH, CHAN)
% returns the current rate on channel CHAN in file FH
%
% RATE=SONIDEALRATE(FH, CHAN, NEWRATE)
% returns the rate at the time of the call an sets a new rate if NEWRATE>0
% Caution: this ovewrites the existing rate setting in the file
%
% FH is the SON file handle, CHAN is the channel number (0-SONMaxChans()-1)
%
% Note that the ideal rate setting does not influence the real rate of 
% sampling
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin<3
    newrate=-1;
end
rate=calllib('son32','SONIdealRate', fh, chan, newrate);