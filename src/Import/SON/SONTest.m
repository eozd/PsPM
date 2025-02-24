function[]=SONTest(file)
% SONTEST tests the integrity of a SON File usinf CED's SonFix program.
%
% SONTEST(FILE)
% FILE may be a string or a file identifier
% If FILE  contains a directory root but no filename or *.smr, all
% files in the directory will be tested. 
% Files currently open for writing within Matlab will not be tested.
% The version of SonFix should be dated 18 Feb 2002 or later to cope with version 6.
% ***Edit SONTest.m to contain the correct path for the SONFIX program***
%
% Malcolm Lidierth 03/02
% Updated 06/05 ML
% © King’s College London 2002-2005

if (nargin<1)
    file='*.smr';
end

if strcmp(class(file),'char')~=1        % If not a character string expect a file identifier
    file=fopen(file);                   % convert to string
end

SONFIX='c:\Spike5\sonfix.exe';        % Edit path to point to SonFix.exe
present=dir(SONFIX);
if isempty(present)
    warning('SONTest: Could not find SONFix.exe');
    return;
end

SONFIX=[SONFIX,' ',file];
eval(sprintf('!%s',SONFIX));

