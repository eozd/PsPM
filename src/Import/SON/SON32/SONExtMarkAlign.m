function state=SONExtMarkAlign(fh, n)
% SONEXTMARKALIGN gets and sets the alignment state for marker channels
% This is a feature of V7 of the SON filing system
% Using aligned markers improves cross-platform portability of SON files
% STATE=SONEXTMARKALIGN(FH,N)
%         FH= SON file handle
%         N = -2, Check channel alignment
%             -1, Check the file header alignment flag
%             0, Set the file header flag to unaligned
%             1, Set the file header flag to aligned
% See CED documentation for details
% 
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

if nargin<2
    state=-1000;
    return;
end

state=calllib('son32','SONExtMarkAlign', fh, n);
