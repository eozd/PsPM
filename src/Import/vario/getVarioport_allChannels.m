function [vario, event] = getVarioport_allChannels(filename)
%Import Varioport data

% Usage:
%   >> vario = getVarioport_allChannels(filename);
%   >> [vario, event] = getVarioport_allChannels(filename);
%
% Outputs:
%   vario     - Varioport data structure
%   event     - marker channel infos as event structure

%2009 by Christoph Berger, Rostock University
%<christoph.berger@med.uni-rostock.de>

vario=[];
if nargout == 2
    event=[];
end
%open file
fid = fopen(filename,'r','b'); %big-endian byte ordering

%channel count
fseek(fid, 7, 'bof');
vario.head.channel_count = fread(fid, 1);

%scanrate in Hertz
fseek(fid, 20, 'bof');
vario.head.ScanRate = fread(fid, 1, 'uint16');
%scaled scanrate
%SCAN_CONST divided by weighted global scanrate = scaled global scanrate in Hertz .
vario.head.SCAN_CONST = 76800;
vario.head.Scaled_Scan_Rate = vario.head.SCAN_CONST / vario.head.ScanRate;
%date of measure
fseek(fid, 16, 'bof');
vario.head.measure_date = fread(fid, 3);
%time of measure
fseek(fid, 12, 'bof');
vario.head.measure_time = fread(fid, 3);
%file header length
fseek(fid, 2, 'bof');
vario.head.length = fread(fid, 1, 'uint16');
% get channel info
for i=1:vario.head.channel_count
    vario.channel(i) = vario_channel_read(i,fid,vario.head.Scaled_Scan_Rate,vario.head.channel_count);
    %write correct channel data
    vario.channel(i).data = (vario.channel(i).data - vario.channel(i).offset) .* (vario.channel(i).mul / vario.channel(i).div);
end
fclose(fid);

if nargout==2
    markIX = find(strcmpi({vario.channel.name},'marker'));
    vario.channel(markIX).time = (1:length(vario.channel(markIX).data)) / vario.channel(markIX).scaled_scan_fac;
    %marker value > 0, marker channel shows difference, new marker value is
    %kept in next sample
    eventIdx = find(vario.channel(markIX).data > 0 & diff([0;vario.channel(markIX).data]) & diff([vario.channel(markIX).data;0]) == 0);
    %allocating
    event= struct('time', {}, 'nid', {},'name', {});
    if ~isempty(eventIdx)
        event(length(eventIdx)).nid=0;
        %events
        for iEvent = 1:length(eventIdx)
            iEventIdx = eventIdx(iEvent);
            event(iEvent).time = vario.channel(markIX).time(iEventIdx);
            event(iEvent).nid = vario.channel(markIX).data(iEventIdx);
            event(iEvent).name = num2str(vario.channel(markIX).data(iEventIdx));
        end
    end    
end

function out = vario_channel_read(chnr,fid,scnrate, chncnt)

%channel name
fseek(fid, (chnr - 1) * 40 + 36, 'bof');
out.name = strtrim(fread(fid, 6,'*char')');
%channel info
%mul
fseek(fid, (chnr - 1) * 40 + 52, 'bof');
out.mul = fread(fid, 1, 'uint16');
%div
fseek(fid, (chnr - 1) * 40 + 56, 'bof');
out.div = fread(fid, 1, 'uint16');
%offset
fseek(fid, (chnr - 1) * 40 + 54, 'bof');
out.offset = fread(fid, 1, 'uint16');
%channel resolution. 1: 2 byte(WORD), 0: 1 byte(BYTE)
fseek(fid, (chnr - 1) * 40 + 47, 'bof');
out.res = fread(fid, 1);
if out.res && 1
    out.sres = 'uint16';
else
    out.sres = 'uint8';
end
%channel unit
fseek(fid, (chnr - 1) * 40 + 42, 'bof');
out.unit = strtrim((fread(fid, 4,'*char'))');
%store_rate in Hertz
fseek(fid, (chnr - 1) * 40 + 48, 'bof');
out.scan_fac = fread(fid, 1);
fseek(fid, (chnr - 1) * 40 + 50, 'bof');
out.store_fac = fread(fid, 1);
out.scaled_scan_fac = scnrate/(out.scan_fac * out.store_fac);

%file offset: begin of channel data
fseek(fid, (chnr - 1) * 40 + 60, 'bof');
%origin=after cheksum header incl. channeldef
out.doffs = fread(fid, 1,'uint32') + 38 + chncnt* 40;
%channel length in byte
fseek(fid, (chnr - 1) * 40 + 64, 'bof');
out.dlen = fread(fid, 1,'uint32');
%channel data
fseek(fid, out.doffs, 'bof');
out.data = fread(fid, out.dlen / (out.res + 1), out.sres);