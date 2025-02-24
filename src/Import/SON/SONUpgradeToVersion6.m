function[]=SONUpgradeToVersion6(fid)
% Obsolete function
% Upgrades SON file ADC and ADCMark data to SON version 6. 
% File header date and time fields are not upgraded
% The file header creator field is set to 'MAT-TO-6' but only if it is '00000000' to begin with.
% IT IS RECOMMENDED THAT YOU BACKUP FILES BEFORE USING THIS ROUTINE. 

% Malcolm Lidierth 03/02

FileH=SONFileHeader(fid);
if FileH.systemID==6                        % Already version 6 so do nothing
    return;
end
if FileH.systemID<3
    warning('SONUpgradeVersionTo6: This file is very old (version 1 or 2 of SON). This upgrade may not work');
    return;
end
    
for chan=1:FileH.channels                   %Run throught he channels
    Info=SONChannelInfo(fid,chan);
    if(Info.kind==1) | (Info.kind==6)       % If ADC or ADCMark update them
        base=512+(140*(chan-1));            % Offset due to file header and preceding channel headers
        fseek(fid,base+102,'bof');
        fwrite(fid,Info.divide*FileH.timePerADC,'int32');    % Set lChanDvd
        fseek(fid,base+138,'bof');
        fwrite(fid,1,'int16');                               % Set adc.divide to 1
    end
end

if strcmp(FileH.Creator,'00000000')==1
    fseek(fid,12,'bof');
    fprintf(fid,'MAT-TO-6');
end

fseek(fid,44,'bof');
fwrite(fid,1e-6,'float64');                  % Set dTimeBase to 1e-6 seconds

frewind(fid);
fwrite(fid,6,'int16');