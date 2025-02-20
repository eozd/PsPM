function ret=SONChanDelete(varargin)
% SONCHANDELETE deletes a channel from a SON file
%     RET=SONCHANDELETE(FH, CHAN {,QUERY})
%         FH = file handle
%         CHAN = channel number 0 to SONMAXCHANS-1
%         QUERY (if present) =  0 Do not query
%                            <> 0 Query before deleting (default)
% Returns 0 if deletion successful, negative error code otherwise
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin < 2
    ret=-1000;
    return;
end

fh=varargin{1};
chan=varargin{2};
if nargin==3
    query=varargin{3};
else
    query=1;
end


if query~=0
    s=sprintf('Do you really want to delete Channel %d',chan);
    button = questdlg(s,'Channel Delete','No','Yes','No');
    if strcmp(button,'No')
        ret=0;
        return;
    end
end


ret=calllib('son32','SONChanDelete',fh,chan);
return;