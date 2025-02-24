function err=SONEmptyFile(fh)
% SONEMPTYFILE Deletes data written to file FH
%
% ERR=SONEMPTYFILE(FH)
%  - see CED documentation for details
% 
%
% Malcolm Lidierth 05/05
% © King’s College London 2005

if nargin<1
    err=-1000;
    return;
end

err=calllib('son32','SONEmptyFile',fh);