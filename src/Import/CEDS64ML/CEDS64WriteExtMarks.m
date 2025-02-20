%{
    Copyright (C) Cambridge Electronic Design Limited 2014
    Author: James Thompson
    Web: www.ced.co.uk email: james@ced.co.uk, softhelp@ced.co.uk

    This file is part of CEDS64ML, a MATLAB interface to the SON64 library.

    CEDS64ML is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    CEDS64ML is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with CEDS64ML.  If not, see <http://www.gnu.org/licenses/>.
%}

function [ iOk ] = CEDS64WriteExtMarks( fhand, iChan, vMarkers )
%CEDS64WRITEEXTMARKS Writes extended markers to an extrended marker channel
%   [ iOk ] = CEDS64WriteExtMarks( hand, iChan, cMarkers, iType )
%   Inputs
%   fhand - An integer handle to an open file
%   iChan - An channel number for an event channel
%   vMarkers - A vector of 64-bit integers (marker times in ticks)
%   Outputs 
%   iOK - 0 if the writing was successful otherwise a negative error code

if (nargin ~= 3)
    iOk = -22;
    return;
end

rType = calllib('ceds64int', 'S64ChanType', fhand, iChan);
switch (rType)
    case 6 % writing to a wavemark channel
        if (~isa(vMarkers, 'CEDWaveMark'))
            iOk = -11;
            return;
        end
    case 7 % writing to a realmark channel
        if (~isa(vMarkers, 'CEDRealMark'))
            iOk = -11;
            return;
        end
    case 8 % writing to a textmark channel
        if (~isa(vMarkers, 'CEDTextMark'))
            iOk = -11;
            return;
        end
    otherwise
        iOk = -11;
        return;
end

N = length(vMarkers);
[ iOk, iRows, iCols ] = CEDS64GetExtMarkInfo( fhand, iChan );
if iOk < 0 %at this point it's unsafe to continue
    return;
end
% Step 1 iterator loop
marker = struct(CEDMarker());
for n=1:N
    % step 2 split nth marker into basic marker + m_data
    % we use transpose as it is needed for multitrace wavemarks to
    % get the column (trace) values properly interleaved, and does
    % no harm to the other forms of extended marker data
    Data = reshape(transpose(vMarkers(n).m_Data), [], 1 );
    nSize = length(Data);
    % make sure Data is not too large for the channel
    switch (rType)
        case 8 % a textmarker channel
            if nSize > iRows
                Data = Data(1:iRows);
            end
        case 7 % a realmarker channel
            if nSize > (iRows*iCols)
                Data = Data(1:iRows*iCols);
            end
        case 6 % a wavemark channel
            if nSize > (iRows*iCols)
                Data = Data(1:iRows*iCols);
            end
    end
    
    marker.m_Time = vMarkers(n).GetTime();
    marker.m_Code1 = vMarkers(n).GetCode(1);
    marker.m_Code2 = vMarkers(n).GetCode(2);
    marker.m_Code3 = vMarkers(n).GetCode(3);
    marker.m_Code4 = vMarkers(n).GetCode(4);
    
    switch (rType)
        case 8 % a textmarker channel
            iOk = calllib('ceds64int', 'S64Write1TextMark', fhand, iChan, marker, Data, nSize);
        case 7 % a realmarker channel
            iOk = calllib('ceds64int', 'S64Write1RealMark', fhand, iChan, marker, Data, nSize);
        case 6 % a wavemark channel
            iOk = calllib('ceds64int', 'S64Write1WaveMark', fhand, iChan, marker, Data, nSize);
    end
    if iOk < 0
        break;
    end
end
end

