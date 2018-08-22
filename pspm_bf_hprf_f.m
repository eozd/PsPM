function [bs, x] = pspm_bf_hprf_f( td, soa )
% pspm_bf_hprf_f basis function dependent on SOA 
%   Detailed explanation goes here
% Description: 
%
% FORMAT: [bf p] = pspm_bf_hprf_f(td, soa)
% with  td = time resolution in s

%
% REFERENCE
%
%________________________________________________________________________
% PsPM 4.0

% initialise
global settings
if isempty(settings), pspm_init; end;

% check input arguments
if nargin < 1
   errmsg='No sampling interval stated'; warning('ID:invalid_input',errmsg); return;
elseif nargin < 2
    soa = 3.5; 
end;

d = 30;
start = 0;
stop = d + soa;

if td > (stop-start)
    warning('ID:invalid_input', 'Time resolution is larger than duration of the function.'); return;
elseif td == 0
    warning('ID:invalid_input', 'Time resolution must be larger than 0.'); return;
elseif soa < 2
    soa = 2;
    stop = d + soa;
    warning('Changing SOA to 2s to avoid implausible values (<2s).');
elseif soa > 8
    warning(['SOA longer than 8s is not recommended. ', ...
        'Use at own risk.']);
end;

x = (start:td:stop-td)';
% das stimmt nicht --> verstehe nicht wie ich anfang und ende des intervals
% bekomme
bs = rectangularPulse(start, stop,x);

end

