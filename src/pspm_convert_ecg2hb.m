function [sts,outchannel,debug_info] = pspm_convert_ecg2hb(fn, options)
% ● Description
%   pspm_convert_ecg2hb identifies the position of QRS complexes in ECG data and writes
%   them as heart beat channel into the datafile. This function implements the algorithm
%   by Pan & Tompkins (1985) with some adjustments described in the function 
%   help under Developer's notes.
% ● Format
%   [sts, channel_index, quality_info] = pspm_convert_ecg2hb(fn, options)
% ● Arguments
%   *            fn : data file name
%   ┌───────options
%   ├──────.channel : [optional, numeric/string, default: 'ecg', i.e. last ECG channel
%   │                 in the file] Channel type or channel ID to be preprocessed.
%   │                 Channel can be specified by its index (numeric) in the file, or by
%   │                 channel type (string). If there are multiple channels with this
%   │                 type, only the last one will be processed. If you want to detect
%   │                 R-peaks for several ECG channels in a PsPM file, call this function
%   │                 multiple times with the index of each channel. In this case, set
%   │                 the option 'channel_action' to 'add', to store each resulting 'hb'
%   │                 channel separately.
%   ├──────────.semi: Activates the semi automatic mode, allowing the handcorrection of
%   │                 all IBIs that fulfill: >/< mean(ibi) +/- 3 * std(ibi) [def. 0].
%   ├─────────.minHR: Minimal HR [def. 20bpm].
%   ├─────────.maxHR: Maximal HR [def. 200bpm].
%   ├─────.debugmode: [numeric, default as 0]
%   │                 Runs the algorithm in debugmode (additional results
%   │                 in debug variable 'infos.pt_debug') and plots a graph
%   │                 that allows quality checks.
%   ├──────.twthresh: Sets the threshold to perform the twave check.
%   │                 [def. 0.36s].
%   └.channel_action: ['add'/'replace', default as 'replace']
%                     Defines whether the new channel should be added or
%                     the previous outputs of this function should be replaced.
%
% ● Outputs
%   *  channel_index: index of channel containing the processed data
%   *   quality_info: generated if options.debugmode == 1
% ● References
%   [1] Adjusted algorithm:
%       Paulus PC, Castegnetti G, & Bach DR (2016). Modeling event-related
%       heart period responses. Psychophysiology, 53, 837-846.
%   [2] Original algorithm:
%       Pan J & Tomkins WJ (1985). A Real-Time QRS Detection Algorithm. IEEE
%       Transactions on Biomedical Engineering, 32, 230-236.
% ● History
%   Introduced in PsPM 3.0
%   Written in 2013-2015 Philipp C Paulus & Dominik R Bach
%   (Technische Universitaet Dresden, University of Zurich)
%   Updated in 2022 Teddy
% ● Developer
%   ▶︎ Changes from the original Pan & Tompkins algorithm
%   filter:       P. & T. intend to achieve a pass band from 5-15 Hz with a
%                 real-time filter. This function uses an offline second
%                 order Butterworth filter with a pass band of 5-15 Hz.
%
%   derivative:   Instead of a the real-time derivativion used by P. & T.,
%                 the MATLAB function 'diff' is used.
%
%   time shift:   In this implementation of the algorithm there is a
%                 time shift between the amplified and integrated signal.
%                 Therefore an R-spike is identified if there is a peak in
%                 the amplified signal and a peak within an interval in the
%                 integrated signal.
%                 time shift=round(pt.settings.filt.sr/6.25) - time shift
%                 of approximately 0.16 sec
%
%   tmax:         To avoid the case that tmax might become smaller than
%                 tmin. tmax must at least be 2*tmin.
%
%   HRmin:        P. & T. do not suggest a minimal HR since the algorithm
%                 is designed for clinical use. We set a minimal HR of 5
%                 bpm (options.HRmin).
%
%   HRmax:        P. & T. suggest a maximum heartrate of 300 bpm. Since in
%                 most psychophysiological studies HR > 200 bpm are very
%                 unlikely to occur HRmax was set to be 200 bpm
%                 (options.HRmax).
%   ▶︎ Important variables of the algorithm
%   PEAKF/PEAKI:  Are the current peaks in the amplified (F) and integrated
%                 (I) signal. These peaks are compared with the threshold
%                 set.
%
%   twave check:  Compares the slope of the current, potential QRS complex
%                 with the slope of the ones preceding it. If the slope is
%                 less than half of those preceding it, a twave is
%                 identified and the current PEAK is marked to be a noise
%                 peak and the threshold set will be updated.
%
%   SPKF/SPKI:    If the current peak (PEAKF/PEAKI) is larger than the
%                 threshold set and has sufficient steepness it is
%                 marked as a QRS complex, the threshold set will be
%                 updated.
%
%   NPKF/NPKI:    Are current peaks which are either smaller than the
%                 threshold set or have insufficient steepness.
%
%   THRF/THRI:    Are the running estimates of the thresholds. They are
%                 updated in different manner according to the type of
%                 the current peak (noise or signal peak).
%
%   x:            Contains the data. Column 1 contains the filtered raw
%                 signal, column 2 contains the amplified signal, column 3
%                 the integrated signal.
%
%   pt_peaks:     Contains all peaks in the amplified (column 1) and
%                 integrated (column 2) signal.
%
%   R:            Vector of the same length as the raw data, containing
%                 information on the position of the QRS complexes.

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = [];
debug_info = [];

%% check input
if nargin < 1
  warning('ID:invalid_input', 'No input. Don''t know what to do.'); return;
elseif nargin < 2
  options = struct();
end
options = pspm_options(options, 'convert_ecg2hb');
if options.invalid
  return
end

%% user output
fprintf('\n\xBB QRS detection for %s,', fn);

%% additional options
% settings for semi automatic mode
pt.settings.semi = options.semi;         %   semiautomatic mode - default as 0, also accepts 1
pt.settings.outfact = options.outfact;      %   mark those IBIs that are >/< mean(IBI)+/- outfact * std(IBI)
% settings for QRS detection
pt.settings.minHR = options.minHR;       %   original: 0 ; set to 20 bpm [def](min 1)
pt.settings.maxHR = options.maxHR;      %   original: 300 bpm; adjusted to 200 bpm [def]!
pt.settings.twthresh = options.twthresh;  %   original: 0.36 s [def]!
pt.settings.debugmode = options.debugmode;    %   no debuggin [def]
pt_debug=[];

%% get data
[nsts, data] = pspm_load_channel(fn, options.channel, 'ecg');
if nsts < 1, return; end

% =========================================================================
% Pan Tompkins QRS detection
% =========================================================================

% ---Settings -------------------------------------------------------------
% define filter properties
pt.settings.filt.sr=data.header.sr ;
pt.settings.filt.lpfreq=15;
pt.settings.filt.lporder=1;
pt.settings.filt.hpfreq=5;
pt.settings.filt.hporder=1;
pt.settings.filt.direction='uni';
pt.settings.filt.down=200;

% set min and max HR
pt.settings.tmin=round(60/pt.settings.maxHR*pt.settings.filt.down);
pt.set.tmax=round(60/pt.settings.minHR*pt.settings.filt.down);

% ---Filter Rawdata--------------------------------------------------------
[nsts,pt.data.x,pt.settings.filt.sr]=pspm_prepdata(data.data,pt.settings.filt);
if nsts == -1, return; end
pt.settings.n=length(pt.data.x);

% ---setup threshold variables and R variable------------------------------
pt.set.THRI=zeros(pt.settings.n,1);
pt.set.THRF=pt.set.THRI;
pt.set.R=[];

% --Derive-----------------------------------------------------------------
pt.data.x(1:size(pt.data.x,1)-1,2)=diff(pt.data.x);

% --Square-----------------------------------------------------------------
pt.data.x(:,2)=pt.data.x(:,2).^2;

% --Sliding Window Integrator----------------------------------------------
pt.settings.q=round(pt.settings.filt.sr/6.66667);
pt.data.x(:,3)=pt.data.x(:,2);
for j=(pt.settings.q+1):pt.settings.n
  pt.data.x(j,3)=(1/pt.settings.q)*(sum(pt.data.x((j-pt.settings.q):j,2)));
end

% --Find peaks-------------------------------------------------------------
pt.data.pt_peaks=zeros(length(pt.data.x),2);
indx=find(diff(sign(diff(pt.data.x(:,2))))==-2);
pt.data.pt_peaks(indx+1,1)=pt.data.x(indx+1,2);
indx = find(diff(sign(diff(pt.data.x(:,3))))==-2);
pt.data.pt_peaks(indx+1,2)=pt.data.x(indx+1,3);

% --Find first noisepeak and first signal peak-----------------------------
pt.data.r=zeros(pt.settings.n,1); % initialise r vector

[pt.set.SPKF,pt.set.tstart]=max(pt.data.pt_peaks(pt.settings.q:pt.settings.q+2*pt.settings.filt.sr,1));
pt.set.SPKI=max(pt.data.pt_peaks(pt.settings.q:pt.set.tmax,2));
pt.set.NPKF=mean(pt.data.pt_peaks(pt.settings.q:pt.settings.q+2*pt.settings.filt.sr,2));
pt.set.NPKI=mean(pt.data.pt_peaks(pt.settings.q:pt.settings.q+2*pt.settings.filt.sr,2));

[pt.set]=update_set(pt.set.SPKF*2,pt.set,'SPKF1');
[pt.set]=update_set(pt.set.SPKI*2,pt.set,'SPKI1');
pt.set.tstart=pt.set.tstart+pt.settings.q;

% start qrs detection at tstart
pt.set.tstart=1;
% pt.data.r(pt.set.tstart)=1;
% pt.set.R=pt.set.tstart;
% pt.set.tstart=pt.set.tstart+pt.settings.tmin;

% ---Debug Mode------------------------------------------------------------
if pt.settings.debugmode==1
  % ----------------------------------------------------------------------
  %    Info variable containing information on pt_debug.data
  pt.pt_debug.info={'heartbeats','amplified signal','integrated signal',...
    'amplified peaks','integrated peaks','amplified thresholds',...
    'integrated thresholds'};
  % ----------------------------------------------------------------------
  pt.pt_debug.data=nan(length(pt.data.x),7);
  pt.pt_debug.data(:,2)=pt.data.x(:,2);
  pt.pt_debug.data(:,3)=pt.data.x(:,3);
  pt.pt_debug.data(:,4)=pt.data.pt_peaks(:,1);
  pt.pt_debug.data(:,5)=pt.data.pt_peaks(:,2);
end
% ---Start R-Spike search: setup standard values---------------------------
pt.set.ts=round(pt.settings.filt.sr/6.25);

% ---Run find_r------------------------------------------------------------
[pt]=find_r(pt);

% ---Debug Mode------------------------------------------------------------
if pt.settings.debugmode==1
  pt.pt_debug.data(:,1)=pt.data.r;
  pt.debug.data(pt.pt_debug.data(:,1)==1,1)=max(max(pt.pt_debug.data));
  pt_debug=pt.pt_debug;
  figure; hold on;
  stem(pt_debug.data(:,1),'k');
  plot(pt_debug.data(:,2:7));
  legend(pt.pt_debug.info);
end

% ---Manual check for outliers---------------------------------------------
if pt.settings.semi==1
  if any(diff(pt.set.R)<mean(diff(pt.set.R))-pt.settings.outfact*std(diff(pt.set.R))) || ...
      any(diff(pt.set.R)>mean(diff(pt.set.R))+pt.settings.outfact*std(diff(pt.set.R)))

    noise=find(diff(pt.set.R)<mean(diff(pt.set.R))-pt.settings.outfact*std(diff(pt.set.R)));
    miss=find(diff(pt.set.R)>mean(diff(pt.set.R))+pt.settings.outfact*std(diff(pt.set.R)));
    pt.faulty=sort([noise miss]);
    % -----------------------------------------------------------------
    [nsts,R]=pspm_ecg_editor(pt); % open gui to manually check for outliers
    if nsts~=-1 && not(isempty(R))
      pt.set.R=R;
    else
      warning('Manual correction not completed. Results will not be saved to file!')
      sts=-1;
      return
    end
  end
end

% ---Prepare output and save-----------------------------------------------
newhr=pt.set.R/pt.settings.filt.sr;

% save data
newdata.data = newhr(:);
newdata.header.sr = 1;
newdata.header.units = 'events';
newdata.header.chantype = 'hb';

% user output
fprintf(' done.');

action = options.channel_action;

o.msg.prefix = 'QRS detection with Pan & Tompkins algorithm and HB-timeseries';
[nsts, write_info] = pspm_write_channel(fn, newdata, action, o);
if nsts == -1, return; end
outchannel = write_info.channel;
debug_info = pt_debug;
sts = 1;
return

% -------------------------------------------------------------------------
%   see below for subfunctions find_r, update_set, tmax, twave_check
% -------------------------------------------------------------------------

%% ---Find R---------------------------------------------------------------
function [pt]=find_r(pt)
% ---Setup standard values ------------------------------------------------
cse=1;
pt.set.rc=1;
pt.set.twave='negative';
pt.set.grad=gradient(pt.data.x(:,2));
CSE(1,:)='SPKI%d';
CSE(2,:)='SPKF%d';
% -------------------------------------------------------------------------
while pt.set.tstart+pt.set.tmax <= pt.settings.n
  % ---R-spike search--------------------------------------------------------
  if cse < 3
    j=pt.set.tstart;
    while j <= pt.set.tstart + pt.set.tmax && j < pt.settings.n
      if j+pt.set.tmax < pt.settings.n
        invl=j:j+pt.set.tmax;
        invl2=j:j+pt.set.ts;
      else
        invl=j:pt.settings.n;
        invl2=j:pt.settings.n;
      end
      % -------------------------------------------------------------
      % no peak found in first pass, so lower threshold
      if j==(pt.set.tstart+pt.set.tmax) && cse==1
        cse=2;
        j=pt.set.tstart;
        % ---------------------------------------------------------
        % no peak found in second pass, so use most likely peak
      elseif  j==(pt.set.tstart+pt.set.tmax) && cse==2
        cse=3;
        % ---------------------------------------------------------
        % no peak at this point
      elseif pt.data.pt_peaks(j,1) == 0
        j = j + 1;
        % ---------------------------------------------------------
        % R peak at this point
      elseif pt.data.pt_peaks(j,1) >= (pt.set.THRF/cse) && max(pt.data.pt_peaks(invl2,2)) >= (pt.set.THRI/cse)  ...
          && strcmp(twave_check(pt,j),'negative')
        if pt.settings.debugmode==1 % save current thresholds to debug variable
          if j+pt.set.tmax <= pt.settings.n
            pt.pt_debug.data(j:j+pt.set.tmax,6)=pt.set.THRF/cse;
            pt.pt_debug.data(j:j+pt.set.tmax,7)=pt.set.THRI/cse;
          else
            pt.pt_debug.data(j:end,6)=pt.set.THRF/cse;
            pt.pt_debug.data(j:end,7)=pt.set.THRI/cse;
          end
        end
        [pt.set]=update_set(max(pt.data.pt_peaks(invl2,2)),pt.set,sprintf(CSE(1,:),cse));
        [pt.set]=update_set(pt.data.pt_peaks(j,1),pt.set,sprintf(CSE(2,:),cse));
        pt.data.r(j,1)=1;
        cse=1;
        pt.set.tstart=j+pt.settings.tmin;
        pt.set.R(end+1)=j;
        % ---update tmax-------------------------------------------
        if length(pt.set.R)>= 9
          [pt]=tmax(pt);
        end
        % ---------------------------------------------------------

        break
        % ----------------------------------------------------------
        % noise peak at this point
      elseif  pt.data.pt_peaks(j,1) > 0 || strcmp(pt.set.twave,'positive')
        [pt.set]=update_set(pt.data.pt_peaks(j,1),pt.set,'NPKF');
        [pt.set]=update_set(pt.data.pt_peaks(j,2),pt.set,'NPKI');
        j=j+1;
        % ----------------------------------------------------------
        % this shouldn't happen:
      else
        error;
      end
    end

    % ---if neither with thr 1 nor with thr 2 an r spike could be identified---
  elseif cse == 3
    % divide invl into 3 smaller intervals
    for k = 1:3
      mindx=(k-1)*round(length(invl)/3)+1:k*round(length(invl)/3);
      if max(mindx)>length(invl)
        mindx(mindx>length(invl))=[];
      end
      minvl=invl(1,mindx);
      if any(pt.data.pt_peaks(minvl,1)>pt.set.THRF)
        [PEAKI,~]=max(pt.data.pt_peaks(minvl,2));
        [pt.set]=update_set(PEAKI,pt.set,CSE(1,:));
        [PEAKF,posPEAKF]=max(pt.data.pt_peaks(minvl,1));
        [pt.set]=update_set(PEAKF,pt.set,CSE(2,:));

        pt.set.tstart=posPEAKF+pt.set.tstart;
        pt.data.r(pt.set.tstart,1)=1;
        pt.set.R(end+1)=pt.set.tstart;
        cse=1;
        pt.set.tstart=pt.set.tstart+pt.settings.tmin;
        break
      end

      if k==3
        if numel(pt.set.R) < 2 || pt.set.R(end)-pt.set.R(end-1)>0
          [PEAKI,~]=max(pt.data.pt_peaks(invl,2));
          [pt.set]=update_set(PEAKI,pt.set,CSE(1,:));
          [PEAKF,posPEAKF]=max(pt.data.pt_peaks(invl,1));
          [pt.set]=update_set(PEAKF,pt.set,CSE(2,:));

          pt.set.tstart=posPEAKF+pt.set.tstart;
          pt.data.r(pt.set.tstart,1)=1;
          pt.set.R(end+1)=pt.set.tstart;
          cse=1;
          pt.set.tstart=pt.set.tstart+pt.settings.tmin;
          break
        end
      end
    end
    % ---update tmax---------------------------------------------------
    if length(pt.set.R)>= 9
      [pt]=tmax(pt);
    end
    % -----------------------------------------------------------------
  end
end

%% ---Update_set-----------------------------------------------------------
function [set]=update_set(PEAK,set,CSE)
% -------------------------------------------------------------------------
switch CSE
  case 'SPKI1'
    SPKI=set.SPKI;
    NPKI=set.NPKI;
    SPKI=0.125*PEAK+0.875*SPKI;
  case 'SPKI2'
    SPKI=set.SPKI;
    NPKI=set.NPKI;
    SPKI=0.25*PEAK+0.75*SPKI;
  case 'NPKI'
    SPKI=set.SPKI;
    NPKI=set.NPKI;
    NPKI=0.25*PEAK+0.75*NPKI;
  case 'SPKF1'
    SPKF=set.SPKF;
    NPKF=set.NPKF;
    SPKF=0.125*PEAK+0.875*SPKF;
  case 'SPKF2'
    SPKF=set.SPKF;
    NPKF=set.NPKF;
    SPKF=0.25*PEAK+0.75*SPKF;
  case 'NPKF'
    SPKF=set.SPKF;
    NPKF=set.NPKF;
    NPKF=0.25*PEAK+0.75*NPKF;
end

% ---Thresholds------------------------------------------------------------
switch CSE
  case {'SPKI1','SPKI2','NPKI'}
    set.SPKI=SPKI;
    set.NPKI=NPKI;
    set.THRI= NPKI + 0.25 * (SPKI-NPKI);
  case {'SPKF1','SPKF2','NPKF'}
    set.SPKF=SPKF;
    set.NPKF=NPKF;
    set.THRF= NPKF + 0.25 * (SPKF-NPKF);
end

% -------------------------------------------------------------------------
%% ---tmax-----------------------------------------------------------------
function [pt]=tmax(pt)
% ---Setup and load--------------------------------------------------------

if length(pt.set.R)==9
  av2=mean(diff(pt.set.R));
else
  av2=pt.set.tmax/1.66;
end

% ---Get average 2---------------------------------------------------------

Rcur=diff(pt.set.R);

for j=1:length(Rcur)

  if  Rcur(j) < 0.92 * av2 || Rcur(j) > 1.16 * av2
    Rcur(j)=0;
  end
end

if length(Rcur(Rcur~=0)) > 8
  Rcor=Rcur(Rcur ~=0);
  av2=mean(Rcor((length(Rcor)-7):length(Rcor)));
end


% ---prepare output--------------------------------------------------------

pt.set.tmax=round(av2*1.66);

if pt.set.tmax < 2* pt.settings.tmin        % tmax must not be smaller than tmin
  pt.set.tmax= 2 * pt.settings.tmin;      % tmax should be tmin * 2
end

% -------------------------------------------------------------------------
%% --twave_check-----------------------------------------------------------
function [twave]=twave_check(pt,j)
% -------------------------------------------------------------------------

q=diff(pt.set.R);

if ~isempty(q) && q(end) < pt.settings.filt.sr * pt.settings.twthresh
  if pt.set.grad(j) < 0.5 * pt.set.grad(pt.set.R(end-1))
    twave='positive';
  else
    twave='negative';
  end
else
  twave='negative';
end
% -------------------------------------------------------------------------
