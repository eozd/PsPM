function usPerTime=SONGetusPerTime(fh)
% SONGETUSPERTIME returns the tick interval in units of SONTimeBase()
% USPERTIME=SONGETUSPERTIME(FH)
%                         FH SON file handle
%     
% See also SONGETTIMEPERADC, SONCHANDIVIDE
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin ~= 1
    usPerTime=-1000;
    return;
end

usPerTime=calllib('son32','SONGetusPerTime',fh);
return;