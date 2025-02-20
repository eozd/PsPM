function[data,header]=SONGetChannel(fid, chan, varargin)
% SONGETCHANNEL provides a gateway to the individual channel read functions. 
% 
% [DATA{, HEADER}]=SONGETCHANNEL(FID, CHAN{, OPTIONS});
% where:
%         FID is the matlab file handle
%         CHAN is the channel number to read (1 to Max)
%         OPTIONS if present, are a set of one or more arguments 
%                   (see below)
% 
%         DATA receives the data or structure from the read operation
%         HEADER, if present, receives the channel header information
%
% 
% Malcolm Lidierth 02/02
% Updated 06/05 ML
% © King’s College London 2002-2005

SizeOfHeader=20;    % Block header is 20 bytes long

if ischar(fid)==1
    warning('SONGetChannel: expecting a file handle from fopen(), not a string "%s" on input',fid );
    data=[];
    header=[];
    return;
end


[path, name, ext]=fileparts(fopen(fid));
if strcmpi(ext,'.smr') ~=1
    warning('SONGetChannel: file handle points to "%s". \nThis is not a valid SON file',fopen(fid));
    data=[];
    header=[];
    return;
end


Info=SONChannelInfo(fid,chan);
if(Info.kind==0) 
    warning('SONGetChannel: Channel #%d does not exist (or has been deleted)',chan);
    data=[];
    header=[];
    return;
end

switch Info.kind
case {1}
    [data,header]=SONGetADCChannel(fid,chan,varargin{:});
case {2,3,4}
    [data,header]=SONGetEventChannel(fid,chan,varargin{:});
case {5}
    [data,header]=SONGetMarkerChannel(fid,chan,varargin{:});
case {6}
    [data,header]=SONGetADCMarkerChannel(fid,chan,varargin{:});
case {7}
    [data,header]=SONGetRealMarkerChannel(fid,chan,varargin{:});
case {8}
    [data,header]=SONGetTextMarkerChannel(fid,chan,varargin{:});
case {9}
    [data,header]=SONGetRealWaveChannel(fid,chan,varargin{:});
otherwise
    warning('SONGetChannel: Channel type not supported');
    data=[];
    header=[];
    return;
end


switch Info.kind
case {1,6,7,9}
    if isempty(header)==0
        header.transpose=0;
    end
end



    






    

