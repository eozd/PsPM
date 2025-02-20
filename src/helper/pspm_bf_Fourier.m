function [bf, x] = pspm_bf_Fourier(varargin)

% SCR_BF_Fourier provides a sine/cosine set of basis functions with or without
%   Hanning window, of specified lenght and order
%
% FORMAT:
% [bf, x] = pspm_bf_Fourier(td, n, order, window) or 
%           pspm_bf_Fourier([td, n, order, window])
% with 
%   td: sampling interval in seconds 
%   n: window length in seconds (default: 30)
%   order: 1/2 * number of basis functions (default: 8)
%   window: Hanning window (default: 1)
% 
%__________________________________________________________________________
% PsPM 3.0
% (C) 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% v001 drb 03.08.3012

% $Id$
% $Rev$

% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;
% -------------------------------------------------------------------------

% set defaults
%----------------------------------------------------------------------
n = 30; order = 8; window = 1;

% get sampling interval
%----------------------------------------------------------------------
if nargin == 0
    errmsg = 'No sampling interval stated'; warning('ID:invalid_input', errmsg); return;
end
td = varargin{1}(1);

% get input arguments
if nargin == 1
   if numel(varargin{1}) > 1, n = varargin{1}(2); end;
   if numel(varargin{1}) > 2, order = varargin{1}(3); end;
   if numel(varargin{1}) > 3, window = varargin{1}(4); end;
else
   n = varargin{2};
   if nargin > 2, order = varargin{3}; end;
   if nargin > 3, window = varargin{4}; end;
end

if td > n
    warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
    warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;    
end


% construct basis set
%----------------------------------------------------------------------
pst   = 0:td:n-td';
x = pst;
pst   = pst/max(pst);

if window
    g  = (1 - cos(2*pi*pst))/2;
else
    g  = ones(size(pst));
end

bf = g;

for i = 1:order
    bf = [bf g.*sin(i*2*pi*pst)];
    bf = [bf g.*cos(i*2*pi*pst)];
end

return;


