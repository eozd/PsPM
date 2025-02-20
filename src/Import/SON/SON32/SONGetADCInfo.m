function [sc,of,units,points,preTrig]=SONGetADCInfo(fh, chan)
% SONGETADCINFO Returns information about an ADC data channel
% (scale{,offset{,units{,points{,preTrig}}}})=SONGetADCInfo(fh, chan)
%                 Inputs  FH SON file handle
%                         CHAN Channel number 0 to SONMaxChan()-1
%                 Outputs SCALE   } As defined in Spike2
%                         OFFSET  }
%                         UNITS    character string with units
%                         POINTS   number of points for ADCMark channel
%                         PRETRIG  number of pre-Trigger points for
%                                  ADCMArk  channel
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

global SON_UNITSZ;


if nargin ~=2
    sc=-1000;
    return;
end

units=char(zeros(1,SON_UNITSZ+1));
[sc of units points preTrig]=...
    calllib('son32','SONGetADCInfo',fh,chan,0,0,units,0,0);
return;
