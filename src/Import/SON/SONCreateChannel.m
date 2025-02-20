function[freechan]=SONCreateChannel(fid,SrcChan,data,dataheader)
% Obsolete function. To write to a file use the SON32 library
%
% Create a new channel in  SON file fid using the existing channel SrcChan channel header as a template.
% Channel data is contained in data. If data is type int16 a new ADC channel will be written. If floating point a 
% RealWave channel will be written as long as the file is of a high enough version (6 or beyond)
% Returns the SON channel number of the created channel
% 
% Malcolm Lidierth 02/02
%
%% 14/5/03 Add feature to use title  from input dataheader for new channels comment
%% 21/5/03 If writing ADC data update the units field in the channel header
%% 
%% 
SizeOfHeader=20;
datatype=class(data); 

[filename permission]=fopen(fid);                           % Is the file open for writing?
if strcmp(permission,'rb+')==0
    error('SONCreateChannel:  File not opened for writing');
end

FileH=SONFileHeader(fid);
if (FileH.systemID<6)  & (strcmp(datatype,'int16')~=1)      % ... make sure it's compatible with the file
    warning('SONExportChannel: SON file is below version 6. RealWave data not allowed. Use SONUpgradeToVersion6.m first');
    return;
end

Failed=0;
for freechan=1:FileH.channels                               %Find a free channel entry
    Info=SONChannelInfo(fid,freechan);
    if(Info.kind==0) break;
        Failed=1;
    end
end
if (Failed==1)
    error('SONCreateChannel: No free space exists in the file to write a channel header');
end

                                     

switch datatype                                             % Check data type...
case {'int16'} 
    Bytes=2;                                                %ADC
case {'single'}
    Bytes=4;                                                % RealWave
case('double')
    data=single(data);                                      % Double so convert to single for disk save and treat as RealWave
    datatype='single';
    Bytes=4;
end


if (nargin<=3) | (dataheader.transpose==0)                         % Transpose data if needed - data should be organized in column vectors
    data=data';                                          % Transpose by default
end                                  
                                           


S=SONChannelInfo(fid,SrcChan);
if (S.kind~=1) & (S.kind~=9)
    warning('SONExportChannel: Only waveforam channels (ADC or Real) can be written');
    return;
end


header=SONGetBlockHeaders(fid,SrcChan);
BlockSize=ceil(header(5,1)*Bytes/512)*512;      % Find a suitable block size - must be 512 byte multiple

% WRITE DATA
fseek(fid,0,'eof');                             % Start at the end-of-file (previously deleted blocks are not used)
[rows,columns]=size(header);
written=1;
for i=1:columns                                 % One block per column in header
    p=ftell(fid);
    if (i==1)                                   % First block in channel.....
        FirstBlock=p;
        fwrite(fid,-1,'int32');
    else
        fwrite(fid,p-BlockSize,'int32');        % ....otherwise, pointer to preceding block
    end
    if (i==columns)                             % Lat block in channel .....
        LastBlock=p;
        fwrite(fid,-1,'int32');
    else
        fwrite(fid,p+BlockSize,'int32');        % ....otherwise pointer to next block
    end
    fwrite(fid,header(2,i),'int32');            % Copy header data
    fwrite(fid,header(3,i),'int32');
    fwrite(fid,freechan,'int16');
    fwrite(fid,header(5,i),'int16');
    count=fwrite(fid,data(written:written+header(5,i)-1),datatype);     % Write data
    fwrite(fid,1:(BlockSize-20)/Bytes-count,datatype);                  % Pad file to next block boundary
    written=written+count;                                              % Update array pointer
end



% WRITE CHANNEL HEADER
base=512+(140*(SrcChan-1));                                % Move to start of source channel header entry
fseek(fid,base,'bof');
buffer=fread(fid,140,'int8');
base=512+(140*(freechan-1));                                %Start of new channel header
fseek(fid,base,'bof');                                     % Duplicate channel header
fwrite(fid,buffer,'int8');

fseek(fid,base+6,'bof');                                   % Replace firstBlock and lastBlock entries
fwrite(fid,FirstBlock,'int32');
fwrite(fid,LastBlock,'int32');
fseek(fid,base+26,'bof');
bytes=fread(fid,1,'uint8');
comment=fscanf(fid,'%c',min(63,bytes));
if(nargin==4) & (isfield(dataheader,'comment'))               % 14/5/03 Add feature to use title in input dataheader 
       comment=['MATLAB: ' dataheader.comment];                 %
else                                                            %
comment=['MATLAB:',comment];                                    %
end                                                             %
fseek(fid,base+26,'bof');                                       %
fwrite(fid,min(63,length(comment)),'uint8');                    %
fwrite(fid,comment(1:min(63,length(comment))),'char');        % 14/5/03 variable length change                      
fseek(fid,base+106,'bof');
fwrite(fid,-1,'int16');                                 % physChan=-1, not a physical channel
fseek(fid,base+122,'bof');
switch datatype
case 'int16'
    fwrite(fid,1,'uint8');
    if(nargin==4) & (isfield(dataheader,'scale'))
        fseek(fid,1,'cof');
        fwrite(fid,dataheader.scale,'float32');
        fwrite(fid,dataheader.offset,'float32');
        fwrite(fid,length(dataheader.units),'uint8');           % 21/5/03 Write units field
        fwrite(fid,dataheader.units,'uint8');
    end
case 'single'
    fwrite(fid,9,'uint8');
    if(nargin==4) & (isfield(dataheader,'max'))
        fseek(fid,1,'cof');
        fwrite(fid,dataheader.min,'float32');
        fwrite(fid,dataheader.max,'float32');
    end
end




