function[out,h]=SONADCToDouble(in,header)
% SONADCTODOUBLE scales a SON ADC channel to double precision floating point
%
% [OUT {, HEADER}]=SONADCTODOUBLE(IN {, HEADER})
%
% Applies the scale and offset supplied in HEADER to the data contained in
% IN. These values are derived form the channel header on disc.
%               OUT=(IN*SCALE/6553.6)+OFFSET
% If no HEADER is supplied as input, a scale of 1.0 and offset of 0.0
% are assumed.
% If supplied as output, HEADER will be updated with fields
% for the min and max values and channel kind will be replaced with 9 (i.e.
% the RealWave channel value).
% 
% 
% Malcolm Lidierth 03/02
% Updated 06/05 ML
% © 2002-2005 King’s College London 

if(nargin<2)
    header.scale=1;
    header.offset=0;
end

if isstruct(header)
    if(isfield(header,'kind'))
        if header.kind~=1
            warning('SONADCToDouble: Not an ADC channel on input');
            out=[];
            h=[];
            return;
        end
    end
end

if strcmp(class(in),'int16')~=1
    warning('SONADCToDouble: 16 bit integer expected');
    out=[];
    h=[];
    return;
end

s=header.scale/6553.6;
o=header.offset;
out=(double(in)*s)+o;

if(nargin==2)
h=header;
end

if(nargout==2)
h.max=(double(max(in(:)))*s)+o;
h.min=(double(min(in(:)))*s)+o;
h.kind=9;
end
