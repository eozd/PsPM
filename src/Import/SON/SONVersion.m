function ver=SONVersion(varargin)
% SONVERSION returns/displays the version number of the matlab SON library
% 
% VER=SONVERSION
%       returns and displays the version while
% VER=SONVERSION('nodisplay')
%       suppresses the display
%
% Updated 06/05 ML
% © King’s College London 2002-2005

title='MATLAB SON Library';
ver=1.1;
if nargin==0 || strcmpi(varargin{1},'nodisplay')~=1
st=sprintf('Author:Malcolm Lidierth\nmalcolm.lidierth@kcl.ac.uk\n Copyright %c King%cs College London 2002-2005\n Version:%3.2f 20.06.05\n\nSON Filing system \nCopyright %c Cambridge Electronic Design 1988-2004 Version 7.0',169,39,ver,169);
(msgbox( st,title,'modal'));
end
