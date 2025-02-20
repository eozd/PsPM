function data = pspm_denoise_spike(inputdata, header, kbdata, cutoff)
% ● Description
%   pspm_denoise_spike removes noise from spike type 4 trigger channels
% ● Format
%   data = pspm_denoise_spike(inputdata, header, kbdata, cutoff)
% ● Arguments
%   * inputdata : data for denoising.
%   *    header : header of data
%   *    kbdata : keyboard channel data
%   *    cutoff : the cut off value for denoising
% ● Outputs
%   *    data: denoised data
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

% if both + and - getevents are recorded, filter out spikes
% with < cutoff ms duration and take only low to high transitions
pulse=inputdata;
% start with low to high
if header.initLow==0
  pulse(1)=[];
end;

% filter out high spikes
dt=diff(pulse);
dthi=dt(1:2:end);
noisepulse=find(dthi<cutoff);
delpulse=[noisepulse*2-1; noisepulse*2];
pulse(delpulse)=[];

% filter out low spikes
dt=diff(pulse);
dtlo=dt(2:2:end);
noisepulse=find(dtlo<cutoff);
delpulse=[noisepulse*2; noisepulse*2+1];
pulse(delpulse)=[];
clear dt dthi dtlo noisepulse delpulse

if isempty(pulse), pulse=0; end;

% check for buffer overflow if keyboard channel is given
% (if one event flank isn't written to file,
% polarity is changed after buffer overflow)
if nargin == 3 && ~isempty(kbdata)
  keyboardmarkers = kbdata.markers;
  bufferoverflow = find(ismember(keyboardmarkers, repmat([255 0 0 0], size(keyboardmarkers,1), 1), 'rows')==1);
  if ~isempty(bufferoverflow)
    for k = 1:numel(bufferoverflow)
      n = bufferoverflow(k);
      % find trigger closest to buffer overflow
      bufferoverflowtime=kbdata.timings(n);
      [dummy, nexttrigger]=min(abs(pulse-bufferoverflowtime));
      % check for polarity after buffer overflow
      if mod(nexttrigger,2)==1, ttl=1; else ttl=0; end;
      if nexttrigger==numel(pulse)
        % if this is the last event, then just bin
        % it
        pulse(end)=[];
      else
        % check length of next interval
        nextinterval=pulse(nexttrigger + 1) - pulse(nexttrigger);
        % if ttl+ interval is longer than default,
        % assume that polarity is changed and trigger
        % flank wasn't written to disk at buffer
        % overflow & correct polarity by removing
        % nexttrigger
        if ttl==1&&nextinterval>110 % max marker duration in ms
          pulse(nexttrigger)=[];
        end;
      end;
      errmsg=sprintf('During sampling, a buffer overflow occured at %.2f s. Please check your data for consistency.', bufferoverflowtime/1000);
      warning(errmsg);
    end;
  end;
end;

% store only lo to hi transitions
data = pulse(1:2:end);

return
