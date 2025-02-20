function [info, data] = nReadDataq(filename)
% Read a DATAQ .wdq file according to the documentation published by 
% on http://www.dataq.com/resources/techinfo/ff.htm
% 
% According to the documentation a .wdq-file consists of three sections
% the header section, the data section and the trailer section. This
% function does only read the header and the data section and thus it only
% returns two structures (info for the header information and data for the
% actual data records). The file trailer has been omitted so far.
% 
% In the header section there are some elements which are read but not
% inerpreted. E.g. Element 33 consists of multiple bitwise fields which are
% in this case only read into info.otherSettings. It is up to the user to
% split the data up accordingly to his needs.
%
% Each element in the header section is commented with 
% '% Element nr - description' so it should simplify the process of 
% searching for an according field name.
%
% The data structure contains an array per channel with the 
% recorded data samples.
%
% Things the function hasn't been tested yet (because lack of test-data):
% - packed an unpacked files
% - hiRes and non-hiRes files
% - differential and non differential channel-configuration
%
% Things the function does not do:
% - it does not read the file trailer
% 
% Author: Tobias Moser (University of Zurich) in Feb. 2015

% initialize info
info = struct();

%% Opening file...
[fid] = fopen(filename,'r');

% start reading the file

%% Header section

% skip element 1 since it depends on element 5

fseek(fid, 2, -1);
% Element 2 -  sample rate numerator and sample rate formation
info.adReadingsPerSample = fread(fid,1,'*uint16');

% Element 3 - Offset in bytes from BOF to header channel info tables
info.headerChannelTablePos = fread(fid,1,'*uint8');

% Element 4 - Number of bytes in each channel info entry
info.channelInfoEntrySize = fread(fid,1,'*uint8');

% Element 5 - Number of bytes in data file header 
info.bytesInDataFileHeader = fread(fid,1,'*int16');

if info.bytesInDataFileHeader == 1156
    info.maxChannels = 29;
    lLength = 5;
else
    info.maxChannels = 144;
    lLength = 8;
end

% jump back to read element 1
fseek(fid, 0, -1);

lTmp = fread(fid, 1, '*uint16');
lAcquired = uint8(0);
for i=1:lLength
    lBit = bitget(lTmp, i);
    lAcquired = bitset(lAcquired, i, lBit);
end
    
info.totalChannelsAcquired = lAcquired;

% correct Element 5 if it is larger than 144
if lAcquired > 144
    info.maxChannels = lAcquired + 1;
end

% go to position for element 6
fseek(fid, 8, -1);

% Element 6 -  Number of ADC data bytes in file excluding header.
info.adcDataBytes = fread(fid,1,'*uint32');

% Element 7 - Total number of event marker, time and date stamp, and event marker comment pointer bytes in trailer
info.eventMarkerInfoPointerBytes = fread(fid, 1, '*uint32');

% Element 8 - Total number of user annotation bytes including 1 null per channel
info.totalUserAnnotationBytes =  fread(fid, 1, '*uint16');

% Element 9 -  	Height of graphics area in pixels
info.graphicsHeight =  fread(fid, 1, '*int16');

% Element 10 -  Width of graphics area in pixels
info.graphicsWidth =  fread(fid, 1, '*int16');

% Element 11 - Cursor position relative to screen center: far left = (element 10)/2; center = 0; far right = (element 10)2-1
info.cursorPosition =  fread(fid, 1, '*int16');

% Element 12 -> some maximum values
%{
Byte #24: Max number of overlapping waveforms per window
Byte #25: Max number of horizontally adjacent waveform windows
The high order 6 bits specify the spacing between vertical grid lines. Default = 0 = 20 pixels of space.
The least significant 2 bits contain 01 - the number of horizontally adjacent windows.
Byte #26: Max number of vertically adjacent waveform windows.
Byte #27: Reserved

-> Notice: read it at the moment as uint32 to keep the fread order; if it should be
used later, split it up into a struct-form
%}

info.maxDesignValues =  fread(fid, 1, '*uint32');

% Element 13 - Time between channel samples: 1/(sample rate throughput / total number of acquired channels)
info.timeBetweenChannelSamples = fread(fid, 1, '*double');

% with this determine the Sample Rate for WinDaq-Files only
info.sampleThroughputRate = int16(info.totalChannelsAcquired) / info.timeBetweenChannelSamples;
info.sampleRatePerChannel = 1 / info.timeBetweenChannelSamples;

% Element 14 - Time file was opened by acquisition: total number of seconds since Jan. 1, 1970
info.timeFileOpened = fread(fid, 1, '*int32');

% Element 15 - Time file trailer was written by acquisition: total number of seconds since Jan. 1, 1970
info.timeFileTrailerWritten = fread(fid, 1, '*int32');

% Element 16 - Waveform compression factor Relative to start of data section
info.waveformCompressionFactor = fread(fid,1,'*int32');

% Element 17 - Position of cursor in waveform file
info.waveformFileCursorPosition = fread(fid, 1, '*int32');

% Element 18 - Position of time marker in waveform file
info.waveformFileTimeMarkerPosition = fread(fid, 1, '*int32');

% Element 19 - Number of Pre- and Posttrigger data points
info.preTriggerDataPointsCount = fread(fid, 1, '*int16');
info.postTriggerDataPointsCount = fread(fid, 1, '*int16');

% Element 20 - Position of left limit cursor from screen-center in pixels
info.leftLimitCursorPos = fread(fid, 1, '*int16');

% Element 21 - Position of right limit cursor from screen-center in pixels
info.rightLimitCursorPos = fread(fid, 1, '*int16');

% Element 22 - Playback state memory
info.playbackStateMemroy = fread(fid, 1, '*uint8');

% Element 23 - Grid, annotation, compression mode
info.gridAnnotationCompressionMode = fread(fid, 1, '*uint8');

% Element 24 - Channel number enabled for adjustments
info.adjustmentsforChannelNumber = fread(fid, 1, '*uint8');

% Element 25 - Scroll, "T" key, "P" key, and "W" key states (WinDaq differs from AT-Codas)
info.scrollKeyStates = fread(fid, 1, '*uint8');

% Element 26 - Array of 32 elements describing the channels assigned to each waveform window
% not 100% sure
info.channelsToWaveformWindow = fread(fid, 32, '*uint8');

% Element 27 - various bits, see documentation
info.hiResFile = fread(fid, 1, '*ubit1');
info.thermocoupleType = fread(fid, 1, '*ubit2');
info.mostSignificatn4Bits = fread(fid, 1, '*ubit4');
info.oscFreeRun = fread(fid, 1, '*ubit1');
info.lowestPhysicalChannel = fread(fid, 1, '*ubit1');

% Bit 9 = 1 if lowest physical channel number is 0 instead of 1
if info.lowestPhysicalChannel == 1
    info.lowestPhysicalChannel = 0;
else
    info.lowestPhysicalChannel = 1;
end
    
info.f3KeySelection = fread(fid, 1, '*ubit2');
info.f4KeySelection = fread(fid, 1, '*ubit2');
info.packedFile = fread(fid, 1, '*ubit1');
info.fft.display = fread(fid, 1, '*ubit1');

% Element 28 - Bits 14 and 15 define FFT window. Bit 13 defines FFT type.
info.fft.typeAndWindow = fread(fid, 1, '*uint16');

% Element 29 - Bits 0 thru 3 define magnification factor applied to spectrum; 
% Bits 4 thru 7 define the spectrum moving average factor
info.spectrum = fread(fid, 1, '*uint8');

% Element 30 - Bits 5 and 6 define the display mode; 
% bit 7 trig sweep slope; 
% Bit 4 = 1/0, erase bar on/off
% Bits 0 thru 3 define the trigger channel source
info.variousDisplaySettings = fread(fid, 1, '*uint8');

% Element 31 - MS 14 bits describe the Triggered sweep level 
% Data bit 0 is set to indicate Triggered Mode or 
% data bit 1 is set to indicate Triggered Storage Mode.
info.triggeredSettings = fread(fid, 1, '*int16');

% Element 32 - Bits 7 & 6 describe the active XY cursor.
% Bits 4 - 0 describe the number of 1/16th XY screen stripes enabled (0 - 16).
info.xySettings = fread(fid, 1, '*uint8');

% Element 33 - see documentation
info.otherSettings = fread(fid, 1, '*uint8');

% Element 34 - Channel information 
% go to headerChannelTablePos and start with the iteration through each channel
% until the number fo info.maxChannels is reached

%% Header Channel Section

% only read if the header channel size is equal to 36 bytes
% because the documentation only describes elements with
% 36 bytes size (when this was written)
if info.channelInfoEntrySize == 36
    for i = 1:info.totalChannelsAcquired
        offsetFactor = uint16(i-1);
        headerpos = uint16(info.headerChannelTablePos) + offsetFactor*uint16(info.channelInfoEntrySize);
        fseek(fid, headerpos, -1);
        % go to position of entry
        % Item 1 - Scaling Slope (m) applied to the waveform to scale it within the display window
        info.scalingSlope(i) = fread(fid, 1, '*single');
        % Item 2 - Scaling intercept value (b) to Item 1
        info.scalingIntercept(i) = fread(fid, 1, '*single');
        % Item 3 - Calibration scaling factor (m) for waveform value display
        info.calibrationScalingFactor(i) = fread(fid, 1, '*double');
        % Item 4 - Calibration Intercept factor (b) for waveform value display
        info.calibrationInterceptFactor(i) = fread(fid, 1, '*double');
        % Item 5 - Engineering units tag for calibrated waveform*
        info.engineeringUnitsTag(i, 1:6) = deblank(fread(fid, 6, '*char'));

        % Item 6 - Reserved -> skip element
        fseek(fid, 1, 0);
        % Item 7
        % Unpacked files: Reserved
        % Packed files: Sample rate divisor for the channel
        info.sampleRateDivisor(i) = fread(fid, 1, '*uint8'); % only if packed Element27 bi 14 = 1
        % Item 8 - 6 bits (Standard version) or 8 bits (Multiplexer versions) used to 
        % describe the physical channel number
        info.physicalChannelNumber(i) = fread(fid, 1, '*uint8');
        % Item 9 - Specifies Gain, mV Full Scale, and Unipolar/Bipolar
        info.channelGain(i) = fread(fid, 1, 'bit4=>uint8');
        info.channelMvFullScale(i) = fread(fid, 1, 'bit4=>uint8');
        % Item 10 - see documentation 
        info.channelSpecificSettings = fread(fid, 1, '*uint16');
        
        % calculate (according to Element 6 in File-Header)
        % numer of channel samples
        info.numberOfChannelSamples(i) = ...
            (((info.adcDataBytes/uint32(2*info.totalChannelsAcquired)) - 1) ...
            / uint32(info.sampleRateDivisor(i))) + 1;
        
    end 
end

%% Conclusion

% warn if file has some special properties
if info.packedFile
    warning('Importing from a packed file. Support has not been tested yet.');
end

if info.hiResFile 
    warning('Importing from a hiRes file. Support has not been tested yet.');
end

if info.maxChannels >= 144
    warning('Importing from a Multiplexer file. Support has not been tested yet.');
end
    
% prepare 
if info.packedFile
    info.adcDataBytes = 2*sum(info.numberOfChannelSamples(:));
end
info.numberOfSamplesWritten = info.adcDataBytes / 2 / uint32(info.totalChannelsAcquired);

%% DATA section

% after the fileheader is where to find the acquired data
data = cell(1,info.totalChannelsAcquired);
for i=1:info.totalChannelsAcquired,
    fseek(fid, info.bytesInDataFileHeader + int16(2*(i-1)), -1);
    % read data
    if info.packedFile
        % does this make sense, because reading
        nSamples = info.numberOfChannelSamples(i);
    else
        nSamples = info.numberOfSamplesWritten;
    end
    data{i} = fread(fid, nSamples, '*int16', 2*(info.totalChannelsAcquired -1));
    % convert data to an equivalent engineering unit
    % - shift 16bit number to the right by two bits
    % - multiply by slope m
    % - add the intercept b
    if info.hiResFile
        data{i} = double(data{i}*0.25)*info.calibrationScalingFactor(i)+info.calibrationInterceptFactor(i);
    else
        data{i} = double(bitshift(data{i}, -2))*info.calibrationScalingFactor(i)+info.calibrationInterceptFactor(i);
    end
end

fclose(fid);

datacheck = cellfun(@(x) numel(x), data);
if sum(datacheck) == 0
    warning(['Data seems to be empty. Has the file been closed properly? ', ...
        'Maybe try to open, save and import the file again.']);
end