function[data,h]=SONGetADCChannel(fid, chan, varargin)
% SONGETADCCHANNEL reads an ADC (waveform) channel from a SON file.
%
% [DATA {, HEADER}]=SONGETADCCHANNEL(FID, CHAN{, START{, STOP{, OPTIONS}}})
% FID is the matlab file handle, CHAN is the channel number (1=max)
% 
% [DATA, HEADER]=SONGETADCCHANNEL(FID, 1{, OPTIONS})
%       reads all the data on channel 1
% [DATA, HEADER]=SONGETADCCHANNEL(FID, 1, 10{, OPTIONS})
%       reads disc block 10 for continuous data or epoch 10 for triggered
%       data
% [DATA, HEADER]=SONGETADCCHANNEL(FID, 1, 10, 20{, OPTIONS})
%       reads disc blocks 10-20 for continuous data or epochs 10-20
%       for triggered data
%
% When present, OPTIONS must be the last input argument. Valid options
% are:
% 'ticks', 'microseconds', 'milliseconds' and 'seconds' cause times to
%    be scaled to the appropriate unit (seconds by default)in HEADER
% 'scale' - calls SONADCToDouble to apply the channel scale and offset to DATA
%    which will  be cast to double precision
% 'progress' - causes a progress bar to be displayed during the read.
%
% Returns the signed 16 bit integer ADC values in DATA (scaled, offset and
% cast to double if 'scale' is used as an option). If present, HEADER
% will be returned with the channel header information from the file.
%
% For continuously sampled data, DATA is a simple vector.
% If sampling was triggered, DATA will be  2-dimensional matrix
% with each epoch (frame) of data in a separate row.
% 
% Examples:
% [data, header]=SONGetADCChannel(fid, 1, 'ticks')
%      reads all data on channel 1 returning an int16 vector or matrix
%      Times in header will be in clock ticks
%
% options={'progress' 'scale' 'ticks'}
% [data, header]=SONGetADCChannel(fid, 1, 200, 399, options{:})
%    reads epochs 200-399 from channel 1 and displays a progress bar. Data is 
%    returned in double-precision floating point after scaling and applying
%    the offset stored on disc via SONADCToDouble. If sampling was
%    continuous, data will be a vector containing data blocks 200-399.
%    If triggered, data will be a 200 row matrix, each row containing one
%    data epoch. 
%
% in this case HEADER could have the following example field values
%       FileName: source filename (and path)
%         system: SON version identifier
%    FileChannel: Channel number in file
%        phyChan: Physical (hardware) port.
%           kind: 1 (or 9 if scales) - channel type identifier 
%        comment: Channel comment
%          title: Channel title
% sampleinterval: sampling interval in seconds              
%          scale: e.g. 200, scaling factor used to convert to 'units'
%         offset: e.g. 1 offset applied to scaled data
%          units: Channel units
%        npoints: e.g. [1x200 double] number of valid data points
%                   in each column of DATA                
%           mode: 'Triggered' or 'Continuous' sampling
%          start: e.g [1x200 double] start time for each column in data
%                       in 'TimeUnits'
%           stop: e.g. [1x200 double] end time for each column in data
%                       in 'TimeUnits'
%         Epochs: a cell array e.g. {[200]  [399]  'of'  [961]  'epochs'}
%                       lists the blocks or epochs read
%      TimeUnits: e.g. 'Ticks' the time units
%      transpose: default 0, a flag used to indicate if the columns and
%                       rows of DATA have been transposed
%
%       min and max fields will also be present if the data are scaled
%
%   See also SONADCTODOUBLE
%
% Malcolm Lidierth 03/02
% Updated 06/05 ML
% © 2002-2005 King’s College London 

       

Info=SONChannelInfo(fid,chan);

if isempty (Info)
    data=[];
    h=[];
    return;
end

if Info.kind ~=1
    warning('SONGetADCChannel: Channel %d No data or wrong channel type', chan);
    data=[];
    h=[];
    return;
end

ShowProgress=0;
ScaleData=0;
arguments=nargin;
for i=1:length(varargin)
    if ischar(varargin{i})
        arguments=arguments-1;
    end
    if strcmpi(varargin{i},'progress') && Info.blocks>10
        ShowProgress=1;
        progbar=progressbar(0,sprintf('Analyzing %d blocks on channel %d',Info.blocks,chan),...
            'Name',sprintf('%s',fopen(fid)));
    end
    if strcmpi(varargin{i},'scale')
        ScaleData=1;
    end
end


FileH=SONFileHeader(fid);
SizeOfHeader=20;                                            % Block header is 20 bytes long
header=SONGetBlockHeaders(fid,chan);


SampleInterval=(header(3,1)-header(2,1))/(header(5,1)-1);   % Sample interval in clock ticks


h.FileName=Info.FileName;                                   % Set up the header information to return
h.system=['SON' num2str(FileH.systemID)];                 
h.FileChannel=chan;
h.phyChan=Info.phyChan;
h.kind=Info.kind;
%h.blocks=Info.blocks;
%h.preTrig=Info.preTrig;
h.comment=Info.comment;
h.title=Info.title;
h.sampleinterval=SONGetSampleInterval(fid,chan);
h.scale=Info.scale;
h.offset=Info.offset;
h.units=Info.units;



NumFrames=1;                                                % Number of frames. Initialize to one.
Frame(1)=1;
for i=1:Info.blocks-1                                       % Check for discontinuities in data record
    IntervalBetweenBlocks=header(2,i+1)-header(3,i);
    if IntervalBetweenBlocks>SampleInterval                 % If true data is discontinuous (triggered)
        NumFrames=NumFrames+1;                              % Count discontinuities (NumFrames)
        Frame(i+1)=NumFrames;                               % Record the frame number that each block belongs to
    else
        Frame(i+1)=Frame(i);                                % Pad between discontinuities
    end
end

    switch arguments
        case {2}
            FramesToReturn=NumFrames;
            h.npoints=zeros(1,FramesToReturn);
            startEpoch=1;           %Read all data
            endEpoch=Info.blocks;
        case {3}
            if NumFrames==1                     % Read one epoch
                startEpoch=varargin{1};  
                endEpoch=varargin{1};
            else
                FramesToReturn=1;
                h.npoints=0;
                startEpoch=find(Frame<=varargin{1});
                endEpoch=startEpoch(end);
                startEpoch=endEpoch;
            end
        case {4}
            if NumFrames==1
                startEpoch=varargin{1};         % Read a range of epochs
                        endEpoch=varargin{2};
            else
                FramesToReturn=varargin{2}-varargin{1}+1;
                h.npoints=zeros(1,FramesToReturn);
                startEpoch=find(Frame==varargin{1});
                startEpoch=startEpoch(1);
                endEpoch=find(Frame<=varargin{2});
                endEpoch=endEpoch(end);
            end
          
    end

% Make sure we are in range if using START and STOP    
        if (startEpoch>Info.blocks || startEpoch>endEpoch)
            data=[];
            h=[];
            close(progbar);
            warning('SONGetADCChannel: Invalid START and/or STOP')
            return;
        end
        if endEpoch>Info.blocks
            endEpoch=Info.blocks;
        end
        



if NumFrames==1 
%%%%%%% Continuous sampling - one frame only. Epochs correspond to blocks
%%%%%%% in the SON file
    NumberOfSamples=sum(header(5,startEpoch:endEpoch));     % Sum of samples in all blocks
    data=int16(zeros(1,NumberOfSamples));                   % Pre-allocate memory for data
    pointer=1;
   
    h.mode='Continuous';
    h.epochs=[startEpoch endEpoch];
    h.npoints=NumberOfSamples;
    h.start=header(2,startEpoch); % Time of first data point (clock ticks)
    h.stop=header(3,endEpoch);    % End of data (clock ticks)

    for i=startEpoch:endEpoch
        fseek(fid,header(1,i)+SizeOfHeader,'bof');
        data(pointer:pointer+header(5,i)-1)=fread(fid,header(5,i),'int16=>int16');
        pointer=pointer+header(5,i);
        if ShowProgress==1
            done=(i-startEpoch)/max(1,endEpoch-startEpoch);
            progressbar(done, progbar,sprintf('Reading Channel %d....     %d%% Done',chan,(int16(done*100)/5)*5));
        end
    end
else
%%%%%%% Frame based data -  multiple frames. Epochs correspond to
%%%%%%% frames of data
    NumberOfSamples=sum(header(5,startEpoch:endEpoch));  % Sum of samples in required epochs
    FrameLength=max(histc(Frame,startEpoch:endEpoch))...
        *max(header(5,startEpoch:endEpoch));% Maximum data points to a frame
    data=int16(zeros(FramesToReturn,FrameLength)); % Pre-allocate array
    p=1;                  % Pointer into data array for each disk data block
    Frame(Info.blocks+1)=-99; % Dummy entry to avoid index error in for loop
    h.mode='Triggered';
    h.start(1)=header(2,startEpoch);% Time of first data point in first returned epoch (clock ticks)
    index=1; %epoch counter
    for i=startEpoch:endEpoch                                       
        fseek(fid,header(1,i)+SizeOfHeader,'bof');
        data(index,p:p+header(5,i)-1)=fread(fid,header(5,i),'int16=>int16');
        h.npoints(index)=h.npoints(index)+header(5,i);
        if Frame(i+1)==Frame(i)
            p=p+header(5,i);               % Increment pointer or.....
        else
            h.stop(index)=header(3,i);     % End time for this frame, clock ticks
            if(i<endEpoch)
            p=1;                          % begin new frame
            index=index+1;
            h.start(index)=header(2,i+1); % Time of first data point in next frame (clock ticks)
            end
        end
        if ShowProgress==1
            done=(i-startEpoch)/max(1,endEpoch-startEpoch);
            progressbar(done, progbar,...
                sprintf('Reading Channel %d.....     %d%% Done',chan,(int16(done*100)/5)*5));
        end
    end
end
if NumFrames==1
    h.Epochs={startEpoch endEpoch 'of' Info.blocks 'blocks'};
else
    h.Epochs={startEpoch endEpoch 'of' NumFrames 'epochs'};
end
[h.start,h.TimeUnits]=SONTicksToSeconds(fid,h.start,varargin{:});
[h.stop,h.TimeUnits]=SONTicksToSeconds(fid,h.stop,varargin{:});

if ScaleData==1
    if ShowProgress==1
        progressbar(1,progbar,'Scaling data.....');
    end
    [data,h]=SONADCToDouble(data,h);
end

if ShowProgress==1
    close(progbar);
    drawnow;
end

