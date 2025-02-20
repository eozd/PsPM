function SONLoad()
% SONLOAD loads the son32.dll library and defines global constants
%
% Version 32 of the SON library works only under Windows and requires
% version 7 of MATALAB and a copy of CED's son32.dll.
%
% The routines use CEDs son32.dll to provide I/O. This file must be present
% in a 'c:\Spike5' directory (unless you edit SONLoad AND SONDef.h and recompile
% the C source files)
%
% Routines are accessed via calllib where possible or through external dlls
% where callib can not presently provide support (i.e. where there are
% non-scalar structures or fields in the call to son32.dll)
%
% SONLoad() has no arguments and should be run before calling any
% library routines that use the MATLAB calllib function.
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright 2005 © King’s College London

global Version; Version=32.00;

global SON_COMMENTSZ;SON_COMMENTSZ=79;
global SON_CHANCOMSZ; SON_CHANCOMSZ=71;
global SON_TITLESZ; SON_TITLESZ=9;
global SON_UNITSZ; SON_UNITSZ=5;
global SON_FMASKSZ; SON_FMASKSZ=32;


string=lower(computer);

if (strcmp(string,'pcwin')== 0)
    errordlg('This version of the SON library requires the Windows operating system\n');

else
    if (libisloaded('son32')==0)
        try
            value = winqueryreg('HKEY_CLASSES_ROOT', 'Spike2Data\shell\open\command');
        catch
            errordlg('No installed copy of CED''s Spike2 for Windows could be found');
        end
        try
            loadlibrary('c:\spike5\son32.dll',@son32);
        catch
            errordlg('This MATLAB library requires son32.dll to be located in the "C:\SPIKE5" folder. Make a copy there to continue',...
                'SON32.DLL not found');
        end
    end
end