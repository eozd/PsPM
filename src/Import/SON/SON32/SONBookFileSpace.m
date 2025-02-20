function [err]=SONBookFileSpace(fh, lspace)
% SONBOOKFILESPACE Allocates disk space for a file
% ERR=SONBOOKFILESPACE(FH,LSPACE)
%                     FHH SON32.DLL file handle
%                     LSPACE space in bytes
% Returns 0 or a negative error code
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London


if nargin ~= 2 
    err=-1000;
    return;
end

err=calllib('son32','SONBookFileSpace',fh,lspace);
return;
