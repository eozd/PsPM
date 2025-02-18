function [sts, scr] = pspm_transfer_function(data, c, Rs, offset, recsys)
% ● Description
%   pspm_transfer_function converts input data into SCR in microsiemens
%   using the following transfer function: G = 1/((c/data-offset)^recsys - Rs),
%   where G is conductance, data is the recorded data, c/offset/Rs are 
%   specified by the user, and recsys is 1 for conductunce measurements 
%   and -1 for resistance measurements. If the measurement system already
%   outputs the conductance G, then the following settings should be used:
%   c = 1, offset = 0, Rs = 0. If the transfer function is not specified,
%   then the imported data will be assigned "arbitrary units".
% ● Format
%   scr = pspm_transfer_function(data, c, Rs, offset, recsys)
%   scr = pspm_transfer_function(data, c, [Rs, offset, recsys])
% ● Arguments
%   * data : the input data into SCR in microsiemens
%   *    c : Transfer constant c. Depending on the recording system:
%            data = c * (measured total conductance in mcS) 
%            - or - 
%            data = c * (measured total resistance in MOhm) = c / (total conductance in mcS)
%   *   Rs : [optional]
%            Series resistors (Rs) are often used as current limiters in MRI and will
%            render the function non-linear. This should be taken into
%            account. Specify Rs in Ohm. Note that some MRI recording
%            systems use resistive wires.
%            default: Rs=0.
%   * offset : [optional, default as 0]
%            Some systems have an offset (e.g. when using fiber optics in MRI, a minimum
%            pulsrate), which can also be taken into account. Offset must be stated in
%            data units.
%   * recsys : [optional]
%            Most SCR measurement systems record a conductance (or a linear 
%            transformation). Some systems record resistance. Specify 
%            'conductance' (default) or 'resistance'.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
scr = [];


% check input arguments
if nargin < 1
  warning('ID:invalid_input','No data given.'); return;
elseif nargin < 2
  warning('ID:invalid_input','No transfer constant given.'); return;
elseif ~isnumeric(c)
  warning('ID:invalid_input','The parameter ''c'' has to be numeric.'); return;
elseif nargin < 3
  Rs=0; offset=0;
elseif ~isnumeric(Rs)
  warning('ID:invalid_input','The parameter ''Rs'' has to be numeric.'); return;
elseif nargin < 4
  offset = 0;
elseif ~isnumeric(offset)
  warning('ID:invalid_input','The parameter ''offset'' has to be numeric.'); return;
elseif nargin < 5
  recsys = 'conductance';
end;

if ~any(strcmpi(recsys, {'conductance','resistance'}))
  warning('ID:invalid_input', ['Invalid recording system given. Use either ', ...
    '''conductance'' or ''resistance''.']); return;
end;

switch recsys
  case 'conductance'
    power = 1;
  case 'resistance'
    power = -1;
end;

% catch zeros
z = (data == 0);
scr(z) = 0;

% catch integer types (linear algebra is not supported for integers)
data = double(data);

% convert
scr(~z) = 1./((c./(data(~z)-offset)).^power-Rs*1e-6);
sts = 1;

