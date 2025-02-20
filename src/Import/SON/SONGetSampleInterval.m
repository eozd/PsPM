function[interval, start]=SONGetSampleInterval(fid,chan)
% SONGETSAMPLEINTERVAL returns the sampling interval in seconds 
% on a waveform data channel in a SON file, i.e. the reciprocal of the
% sampling rate for the channel, together with the time of the first sample
%
% [INTERVAL{, START}]=SONGETSAMPLEINTERVAL(FID, CHAN)
% FID is the matlab file handle and CHAN is the channel number (1-max)
% The sampling INTERVAL and, if requested START time for the data are
% returned in seconds.
% Note that the returned times are always in seconds.
%
% Malcolm Lidierth 02/02
% Updated 09/05 ML
% © 2002-2005 King’s College London


FileH=SONFileHeader(fid);                                   % File header
Info=SONChannelInfo(fid,chan);                              % Channel header
header=SONGetBlockHeaders(fid,chan);
switch Info.kind                                            % Disk block headers
    case {1,6,7,9}
        switch FileH.systemID
            case {1,2,3,4,5}                                                % Before version 6
                if (isfield(Info,'divide'))
                    interval=Info.divide*FileH.usPerTime*FileH.timePerADC*1e-6; % Convert to seconds
                    start=header(2,1)*FileH.usPerTime*FileH.timePerADC*1e-6;
                else
                    warning('SONGetSampleInterval: ldivide not defined Channel #%d', chan);
                    interval=[];
                    start=[];
                end
            otherwise                                                       % Version 6 and above
                interval=Info.lChanDvd*FileH.usPerTime*FileH.dTimeBase;
                start=header(2,1)*FileH.usPerTime*FileH.dTimeBase;
        end
    otherwise
        warning('SONGetSampleInterval: Invalid channel type Channel #%d',chan);
        interval=[];
        start=[];
        return;
end

