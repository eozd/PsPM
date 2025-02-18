function [sts, b, a] = pspm_butter(order, freqratio, pass)
% ● Description
%   pspm_butter interfaces Matlab Signal Processing Toolbox filters and
%   additionally implements a few standard filters for those who don''t have
%   this toolbox
% ● Format
%   [sts, b, a] = pspm_butter(order, freqratio)
% ● Arguments
%   *     order: the order of the Butterworth filter to be designed
%   * freqratio: the cut-off frequency of the Butterworth filter to be designed
% ● Outputs
%   *       sts: -1 if non-standard filters are requested
% ● History
%   Introduced in PsPM 3.0
%   Written in 2009-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
a = []; b = [];
errmsg = ' - please install the signal processing toolbox if you need other filters.';
%% check input arguments
if nargin < 2
  warning('ID:invalid_input','Not enough input arguments.'); return;
elseif nargin < 3
  pass = 'low';
elseif ~(any(strcmpi(pass, {'high', 'low'})))
  warning('ID:invalid_input','%s is not a valid argument.', pass); return;
end;

if ~settings.signal && order ~= 1
  warning('ID:toolbox_missing','This function can only create 1st order filters - %s', errmsg); return;
end;
%% filters
if settings.signal
  [b, a] = butter(order, freqratio, pass);
else
  F = load('pspm_butter.mat', 'filt');
  switch pass
    case 'low'
      f = F.filt{1};
    case 'high'
      f = F.filt{2};
  end;
  d = abs([f.freqratio] - freqratio);
  n = find(d < .0001);
  if isempty(n)
    warning('ID:toolbox_missing','No filter implemented for this frequency ratio %s', errmsg); return;
  else
    if numel(n) > 1
      [foo, n] = min(d);
    end;
    a = f(n).a;
    b = f(n).b;
  end;
end
sts = 1;
return

% create filters (last used on 29.09.2013)
% ------------------------------------------------------------------------
% % lowpass
% freqratio = [4.95/5 1./([2:4 5:5:500])];
% for n = 1:numel(freqratio)
%     [filt{1}(n).b filt{1}(n).a] = butter(1, freqratio(n));
%     filt{1}(n).freqratio = freqratio(n);
% end;
% % highpass (standard filter DCM, standard filter GLM)
% freqratio = [0.0159./([4.5 5:5:500]), 0.05./([4.5 5:5:500])];
% for n = 1:numel(freqratio)
%     [filt{2}(n).b filt{2}(n).a] = butter(1, freqratio(n), 'high');
%     filt{2}(n).freqratio = freqratio(n);
% end;
% save([settings.path, 'pspm_butter.mat'], 'filt');
