function[ChanList]=SONChanList(fid)
% SONCHANLIST returns a structure with details of active channels in a SON file
% 
% LIST=SONCHANLIST(FID)
%
% FID is the file handle.
% List is a structure with field for the channel number, kind, title,
% comment and the number of physical port data were collected from

% Malcolm Lidierth 03/02
% Updated 06/05 ML
% © 2002-2005 King’s College London 

h=SONFileHeader(fid);

if isempty(h)
    ChanList=[];
    return;
end

AcChan=0;
for i=1:h.channels
    c=SONChannelInfo(fid,i);
    if(c.kind>0)                   % Only look at channels that are active
        AcChan=AcChan+1;
        ChanList(AcChan).number=i;
        ChanList(AcChan).kind=c.kind;
        ChanList(AcChan).title=c.title;
        ChanList(AcChan).comment=c.comment;
        ChanList(AcChan).phyChan=c.phyChan;
    end
end

            
            
            
