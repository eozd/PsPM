function[data,h]=SONGetTextMarkerChannel(fid, chan, varargin)
% SONGETTESTMARKERCHANNEL reads a marker channel from a SON file.
%
% [data{, h}]=SONGETMARKER(FID, CHAN)
% FID is the MATLAB file handle and CHAN is the channel number (1 to Max)
% DATA is a structure containing:
%   DATA.TIMINGS: a length n vector with the marker timestamps
%   DATA.MARKERS: an n x 4 array of uint8 type, containing the marker
%   values
%	DATA.TEXT: an n x m array, with m characters for each of the n tiemstamps
% When present, OPTIONS must be the last input argument. Valid options
% are:
% 'ticks', 'microseconds', 'milliseconds' and 'seconds' cause times to
%    be scaled to the appropriate unit (seconds by default)in HEADER
% 'scale' - no effect
% 'progress' - causes a progress bar to be displayed during the read.
%
% 
% Malcolm Lidierth 02/02
% Updated 06/05 ML
% © King’s College London 2002-20052

Info=SONChannelInfo(fid,chan);

if isempty (Info)
    data=[];
    h=[];
    return;
end

if(Info.kind~=8) 
    warning('SONGetTextMarkerChannel: Channel %d No data or not a TextMark channel',chan);
    data=[];
    h=[];
    return;
    return;
end

FileH=SONFileHeader(fid);
SizeOfHeader=20;                                            % Block header is 20 bytes long
header=SONGetBlockHeaders(fid,chan);
ShowProgress=0;
arguments=nargin;
for i=1:length(varargin)
    if ischar(varargin{i}) 
        arguments=arguments-1;
        if strcmpi(varargin{i},'progress') && Info.blocks>10
            ShowProgress=1;
            progbar=progressbar(0,sprintf('Analyzing %d blocks on channel %d',Info.blocks,chan),...
                'Name',sprintf('%s',fopen(fid)));
        end
    end
end

switch arguments
    case {2}
        startBlock=1;
        endBlock=Info.blocks;
    case {3}
        startBlock=varargin{1};
        endBlock=varargin{1};
    otherwise
        startBlock=varargin{1};
        endBlock=min(Info.blocks,varargin{2});
end

NumberOfMarkers=sum(header(5,startBlock:endBlock)); % Sum of samples in required blocks      

data.timings=zeros(NumberOfMarkers,1);
data.markers=uint8(zeros(NumberOfMarkers,4));
data.text=char(zeros(NumberOfMarkers,Info.nExtra));

count=1;
for block=1:Info.blocks
    fseek(fid, header(1, block)+SizeOfHeader, 'bof');               % Start of block
    for i=1:header(5,block)                                         % loop for each marker
        data.timings(count,1)=fread(fid,1,'int32');          % Time
        data.markers(count,:)=fread(fid,4,'int8=>int8');            % 4x marker bytes
        data.text(count,:)=fread(fid,Info.nExtra,'char=>char');
        k=findstr(data.text(count,:),0);                            % Look for NULL terminator and clear succeeding characters
        data.text(count,k(1):Info.nExtra)=0;
        count=count+1;
        if ShowProgress==1
            done=(i-startBlock)/max(1,endBlock-startBlock);
            progressbar(done, progbar,sprintf('Reading Channel %d....     %d%% Done',chan,(int16(done*100)/5)*5));
        end
    end
end

[data.timings,h.TimeUnits]=SONTicksToSeconds(fid,data.timings, varargin{:}); % Convert time

if(nargout>1)
    h.FileName=Info.FileName;                                   % Set up the header information to return
    h.system=['SON' num2str(FileH.systemID)];
    h.FileChannel=chan;
    h.phyChan=Info.phyChan;
    h.kind=Info.kind;
    h.blocks=Info.blocks;
    h.npoints=NumberOfMarkers;
    h.values=Info.nExtra;
    h.preTrig=Info.preTrig;
    h.comment=Info.comment;
    h.title=Info.title;
end
[data.timings,h.TimeUnits]=SONTicksToSeconds(fid,data.timings, varargin{:});                % Convert time
h.Epochs={startBlock endBlock 'of' Info.blocks 'blocks'};
if ShowProgress==1
    close(progbar);
    drawnow;
end