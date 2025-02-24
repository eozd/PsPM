function [varargout]=SONGetExtraData(varargin)
% SONGETEXTRADATA reads or writes the extra data area of a SON file
% 
% [ERR, BUFFER]=SONGETEXTRADATA(FH, N, DATATYPE, BYTEOFFSET, FLAG)
% or
% ERR=SONGETEXTRADATA(FH, BUFFER, BYTEOFFSET, FLAG)
% 
% INPUTS:  FH      the SON file handle
%          N       the number of items to read
%          DATATYPE   string class descriptor for the read
%          BYTEOFFSET the offset from the start of the data area
%          BUFFER  the data to write
%          FLAG    0 to read and 1 to write data
% 
% OUTPUTS  ERR= 0 if OK or a negative error
%          BUFFER the output data for a read
%
% e.g. [err data]=SONGetExtraData(fh, 100, 'int32', 64, 0)
% reads 100 32-bit integer values from the data area starting 64 bytes into
% the area
% 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London
         


if (nargin==5)
    fh=varargin{1};
    n=varargin{2};
    datatype=varargin{3};
    byteoffset=varargin{4};
    flag=varargin{5};
    if (flag==0)
        st=sprintf('%s(zeros(1,%d))',datatype, n);
        st=eval(st);
        tmp=feval('whos','st');
        st=sprintf('%s(zeros(1,%d))', datatype, tmp.bytes);
        buffer=eval(st);
        [err buffer]=calllib('son32','SONGetExtraData',...
            fh, buffer, tmp.bytes, byteoffset, flag);
        varargout{1}=err;
        if (err==0 && nargout==2)
            varargout{2}=eval(sprintf('%s(buffer)',datatype));
        else
            if (nargout==2)
                varargout{2}=eval(sprintf('%s([])',datatype));
            end
        end
        return;
    end
end

if (nargin==4)
    fh=varargin{1};
    buffer=varargin{2};
    byteoffset=varargin{4};
    flag=varargin{4};
    if (flag==1)
        tmp=whos('buffer');
        varargout{1}=calllib('son32','SONGetExtraData',...
            fh, buffer, tmp.bytes, byteoffset, flag);
        return;
    end
end

varargout{1}=-1000;
if nargout==2
    varargout{2}=[];
end
return;


