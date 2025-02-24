    function pspm_peakscore(datafile, regfile, modelfile, timeunits, normalize, chan, options)

% pspm_peakscore calculates event-related responses by scoring the peak
% response against a pre-stimulus baseline. The input is similar to
% pspm_glm, and the output is written into a DUMMY glm structure to make it
% readable for pspm_con1
%
% FORMAT:
% SCR_PEAKSCORE (DATAFILE, REGFILE, MODELFILE, TIMEUNITS, NORMALISE, CHAN, OPTIONS)
%
% datafile, regfile: either one datafile and one regfile, or a cell array of
% datefiles to be concatenated (e.g. several sessions of an fMRI
% experiment) and a cell array of regfiles (onsets with respect to session
% start), or one regfile for the whole model (the duration of each
% datafile will be needed to construct the regfile, and can be assessed via
% the variable infos.duration)
%
% timeunits: 'seconds', 'markers', 'samples'
%
% normalize (default = 1) determines whether the data are normalized. This
% can help to reduce variance due to peripheral factors (e. g. skin 
% properties)
%
% chan: by default, SCRalyze looks for the only waveform channel, or for
% the first scr channel. Provide an argument to pick a specific waveform
% channel (and a second one for events, if timeunits = 'markers')
%
% options.overwrite = 1: overwrite existing files
% options.method:   'simple' - computes a max/baseline difference
%                   'min' - same but computes a min/baseline difference
%                   'abs' - signed peak of largest modulus
%                   'spr' - method preferred by the Society for
%                   Psychophysiological Research (SPR). Detect peak in peak
%                   window, then find onset in onset window, score 0 if no
%                   peak occurs
% options.summary: for options.spr - 'amplitude' (based only on values >
%                   .01 mcS)m 'magnitude' (based on all values)
% options.window: for method 'simple', baseline post stimulus peak window 
%                 (default: [-1 0; 1 4], was formerly termed 'baseline' and 
%                 'peakwindow')
%                 for method 'spr', post stimulus onset and post onset peak 
%                 window (default: [1 4; 0.5 5]);
% options.diagnostics: makes a plot after every detected peak (for
%               development purposes, default = 0)
%__________________________________________________________________________
% PsPM 3.1
% (c) 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% $Id$
% $Rev$

global settings;
if isempty(settings), pspm_init; end;

% check input arguments
if nargin<1
    errmsg=sprintf('No data file specified'); warning(errmsg); return;
elseif nargin<2
    errmsg=sprintf('No condition file specified'); warning(errmsg); return;
elseif nargin<3
    errmsg=sprintf('No modelfile specified'); warning(errmsg); return;
elseif nargin<4
    errmsg=sprintf('No timeunits specified'); warning(errmsg); return;
elseif ~ismember(timeunits, {'seconds', 'markers', 'samples'})
    errmsg=sprintf('Timeunits (%s) not recognised; only ''seconds'', ''markers'' and ''samples'' are supported', timeunits); warning(errmsg); return;
elseif nargin<5
    normalize=1;
end
if nargin<6 || isempty(chan)
    chan = 0;
end

% set options
try options.overwrite; catch, options.overwrite = 0; end;
try options.method; catch, options.method = 'simple'; end;
try options.diagnostics; catch, options.diagnostics = 0; end;

if strcmpi(options.method, 'spr')
    try options.summary;
    catch
        options.summary = 'amplitude';
    end
end

try options.window;
catch
    switch options.method
        case {'simple', 'min', 'abs'}
            options.window = [-1 0; 1 4];
        case 'spr'
            options.window = [1 4; 0.5 5];
        otherwise
            warning('Method unknown'); return;
    end
end
            

% check modelfile
if options.overwrite ~= 1 && exist(modelfile)==2 
    overwrite=menu(sprintf('Model file (%s) already exists. Overwrite?', modelfile), 'yes', 'no');
    close gcf;
    if overwrite==2, return; end;
end

% check datafile(s)
if ~iscell(datafile)
    datafile={datafile};
end
for d=1:numel(datafile)
    sts = pspm_load_data(datafile{d}, 'none');
    if sts == -1
        return;
    end
end

% check regressor files
if ~iscell(regfile)
    regfile={regfile};
end

[sts multi] = check_regfile(regfile, timeunits);
if sts < 0, return; end;

% set filter
model.filter = settings.glm(1).filter;

%-------------------------------------------------------------------------
% user output
%-------------------------------------------------------------------------

fprintf('Peak scoring: %s ...', modelfile);

%-------------------------------------------------------------------------
% prepare data & concatenate regressors
%-------------------------------------------------------------------------

Y=[];
for d=1:numel(datafile)
    
    clear scr infos filt down pspm_hp pspm_lp pspm_down
    
    if chan == 0
        % load waveform channels
        [sts, infos, data] = pspm_load_data(datafile{d}, 'wave');
        if sts == -1; return; end;
        % if there is none, or more than one waveform channel
        if isempty(data) || numel(data) > 1
            % load scr channel(s)
            [sts, infos, data] = pspm_load_data(datafile{d}, 'scr');
            if sts == -1 || isempty(data); return; end;
        end
        % use data from single waveform, or first scr channel
        scr = data{1};
        % if required, load events
        if any(strcmp(timeunits, {'trigger', 'markers'}))
            [sts, infos, data] = pspm_load_data(datafile{d}, 'events');
            if sts == -1 || isempty(data); 
                warning('No event data'); return;
            else
                events = data{1}.data;
            end
        else
            events = [];
        end
    else
        [sts, infos, data] = pspm_load_data(datafile{d}, chan);
        if sts == -1 || isempty(data), warning('Could not load file %s', datafile{d}); return; end;
        if strcmp(data{1}.header.units, 'events'); warning('No waveform data'); return; end;
        scr = data{1};
         if any(strcmp(timeunits, {'trigger', 'markers'}))
            [sts, infos, data] = pspm_load_data(datafile{d}, 'events');
            if sts == -1 || isempty(data); 
                warning('No event data'); return;
            else
                events = data{1}.data;
            end
        else
            events = [];
        end
    end

    % prepare (filter & downsample) data (no high pass filtering)
    model.filter.hpfreq = 'none';
    model.filter.sr      = scr.header.sr;
    [sts, pspm_down, sr] = pspm_prepdata(scr.data, model.filter);

    % concatenate if necessary
    Y=[Y; pspm_down];
    
    % get duration of single sessions
    snduration(d)=numel(pspm_down);
    
    % concatenate regressors & convert to samples
    if d <= numel(multi)
        for n = 1:numel(multi(1).n)
            % convert onsets to samples
            switch timeunits
                case 'samples'
                    dummy = round(multi(d).o{n} * sr/scr.header.sr);
                    foo   = round(multi(d).d{n} * sr/scr.header.sr);
                case 'seconds'
                    dummy = round(multi(d).o{n} * sr);
                    foo   = round(multi(d).d{n} * sr);
                case 'markers'
                    try
                        dummy = round(events(multi(d).o{n}) * sr); % markers are timestamps in seconds
                    catch
                        warning('\nSome events in condition %01.0f were not found in the data file %s', n, datafile{d}); return;
                    end
                    if any(multi(d).d{n} ~= 0)
                        warning('markers is a convenience timeunits option that does not allow to specify events of non-zero duration.'); return;
                    else
                        foo = multi(d).d{n};
                    end
            end
            % get the first regressor file
            if d == 1
                names{n} = multi(1).n{n};
                onsets{n} = dummy(:);
            else
                dummy = dummy + sum(snduration(1:(d - 1)));
                onsets{n} = [onsets{n}; dummy(:)];
            end
        end
    end
end

% z-transform if desired
if normalize
    Y=(Y-mean(Y))/std(Y);
end

Y = Y(:);

% smooth if SPR method
if strcmpi(options.method, 'spr')
    Y = medfilt1(Y, 3);
end

%-------------------------------------------------------------------------
% initialise design matrix
%-------------------------------------------------------------------------
clear glm tmp
glm.sourcefile=datafile;
glm.Y=Y; clear Y;
glm.sr.init=scr.header.sr;
glm.sr.fin=sr;
glm.duration=numel(glm.Y)/glm.sr.fin;
glm.durationinfo='duration in seconds';
tmp.duration=numel(glm.Y);
glm.norm=normalize;
glm.name = names;
glm.modeltype = 'glm';
glm.modality = settings.modalities.glm;

%-------------------------------------------------------------------------
% peak scoring
%-------------------------------------------------------------------------

for k = 1:numel(onsets)
    clear peakscore
    for n = 1:numel(onsets{k})
        firstwin = onsets{k}(n) + (round(options.window(1, 1) * glm.sr.fin):round(options.window(1, 2) * glm.sr.fin));
        secondwin = onsets{k}(n) + (round(options.window(2, 1) * glm.sr.fin):round(options.window(2, 2) * glm.sr.fin));
        initialfirstwin = firstwin; % for diagnostics
        initialsecondwin = secondwin; % for diagnostics
        % if final peak window is cut off, don't analyse
        if all(secondwin < numel(glm.Y))
            if strcmpi(options.method, 'simple')
                baseline = mean(glm.Y(firstwin));
                peak = max(glm.Y(secondwin));
                peakscore(n) = peak - baseline;
            elseif strcmpi(options.method, 'min')
                baseline = mean(glm.Y(firstwin));
                peak = min(glm.Y(secondwin));
                peakscore(n) = peak - baseline;
            elseif strcmpi(options.method, 'abs')
                baseline = mean(glm.Y(firstwin));
                [peak, peakindx] = max(abs(glm.Y(secondwin)- baseline));
                peakscore(n) = peak * sign(glm.Y(secondwin(peakindx))- baseline);
            elseif strcmpi(options.method, 'spr')
                % create running average
                b = [1/3 1/3 1/3]; a = 1;
                scr = filter(b, a, glm.Y);
                scr1 = filter(b, a, diff(scr));
                scr2 = filter(b, a, diff(scr1));
                foundpeak = 0;
                % first, look for maximum curvature in SCR, i. e.
                % maximum of second derivative (according to Boucsein
                % method)
                [pks, lcs] = findpeaks(scr2(firstwin));
                onsetindx = 1;
                while (~foundpeak) && (onsetindx <= numel(lcs));
                    onset = firstwin(lcs(onsetindx));
                    % look for first peak after onset
                    secondwin = onset + (round(options.window(2, 1) * glm.sr.fin):round(options.window(2, 2) * glm.sr.fin));
                    peak = find(diff(sign(scr1(secondwin))) == -2, 1);  % look for local maximum as change from pos to neg
                    % found peak? Otherwise, look for next onset
                    if ~isempty(peak)
                        peak = secondwin(1) + peak;
                        foundpeak = 1;
                    else
                        onsetindx = onsetindx + 1;
                    end
                end
                % do check on first derivative (old peak score method used
                % until Staib, Castegnetti & Bach 2015) if diagnostics
                % required
                foundfirstpeak = 0;
                while (options.diagnostics) && (~foundfirstpeak) && (numel(firstwin) > 1);
                    % look for minimum as change in first derivative from
                    % neg to pos 
                    firstonset = find(diff(sign(scr1(firstwin))) == 2, 1);
                    if isempty(firstonset)
                       firstwin = [];
                    else
                        firstonset = firstonset + firstwin(1);
                        % look for first peak after onset
                        secondwin = firstonset + (round(options.window(2, 1) * glm.sr.fin):round(options.window(2, 2) * glm.sr.fin));
                        firstpeak = find(diff(sign(scr1(secondwin))) == -2, 1);  % look for local maximum as change from pos to neg
                        % found peak? Otherwise, look for next onset
                        if ~isempty(firstpeak)
                            firstpeak = secondwin(1) + firstpeak;
                            foundfirstpeak = 1;
                        else
                            firstwin(1:find(firstwin == firstonset)) = [];
                        end
                    end
                end
                if foundpeak
                    peakscore(n) = scr(peak) - scr(onset);
                    % if an onset is followed by first peak before the peak
                    % window and by a second one within, then this can be
                    % negative
                    peakscore(n) = max(0, peakscore(n));
                else
                    peakscore(n) = 0;
                end
                if options.diagnostics
                    figure; axes; hold on
                    win = initialfirstwin(1):secondwin(end);
                    plot(win, scr(win) - scr(win(1)), 'k');
                    plot(win, scr1(win), 'r');
                    plot(win, scr2(win), 'b');
                    if foundpeak
                        stem(onset, scr(onset));
                        stem(peak, scr(peak));
                    end
                    if foundfirstpeak
                        stem(firstonset,scr(firstonset));
                        stem(firstpeak, scr(firstpeak));
                    end
                	s = input('Press RETURN to continue.', 's');
                    close(gcf);
                end
            end
        end
    end
    if strcmpi(options.method, 'spr') && strcmpi(options.summary, 'amplitude')
        glm.stats(k, 1) = mean(peakscore(peakscore > .01));
    else
        glm.stats(k, 1) = mean(peakscore);
    end
    clear peakscore
    glm.names = {};
end

save(modelfile, 'glm');


%-------------------------------------------------------------------------
% user output
%-------------------------------------------------------------------------

fprintf(' done. \n');

% cleanup
clear glm scr
return

%-------------------------------------------------------------------------
% internal functions: check regressor file(s)
%-------------------------------------------------------------------------

function [sts multi] = check_regfile(fns, timeunits)

if ~iscell(fns)
    fns = {fns};
end

sts = 1;
multi = [];

for f = 1:numel(fns)
    fn = fns{f};
    merrmsg=sprintf('Regressor file (%s) is invalid ... ', fn);
    if exist(fn)~=2
        errmsg=sprintf('Regressor file (%s) doesn''t exist', fn);
        warning(errmsg);
        sts = -1;
        return;
    end
    
    load(fn);
    if (isempty(find(ismember(who, 'names'), 1)))||(isempty(find(ismember(who, 'onsets'), 1))),
        warning(merrmsg); sts = -1; return;
    end
    if isempty(find(ismember(who, 'durations'), 1)),
        durations=num2cell(zeros(numel(names), 1));
    end
    if isempty(find(ismember(who, 'parametric_confound'), 1))
        parametric_confound=zeros(numel(names), 1);
    end
    if ~iscell(names)||~iscell(onsets)
        errmsg = 'Names and onsets need to be cell arrays'; warning([merrmsg, errmsg]); sts=-1; return;
    end
    if numel(names)~=numel(onsets),  errmsg=sprintf('Number of event names (%d) does not match the number of onsets (%d).',...
            numel(names),numel(onsets)); warning([merrmsg, errmsg]); sts = -1; return;
    elseif numel(names)~=numel(durations),  errmsg=sprintf('Number of event names (%d) does not match the number of durations (%d).',...
            numel(onsets),numel(durations)); warning([merrmsg, errmsg]); sts = -1; return;
    elseif numel(names)~=numel(parametric_confound),  errmsg=sprintf('Number of event names (%d) does not match the number of parametric confound specifications (%d).',...
            numel(onsets),numel(parametric_confound)); warning([merrmsg, errmsg]); sts = -1; return;
    else
        for n=1:numel(names)
            if numel(durations{n})==1, durations{n}=repmat(durations{n}, numel(onsets{n}), 1);
            elseif (numel(onsets{n}) ~= numel(durations{n}))
                errmsg=sprintf('"%s": Number of event onsets (%d) does not match the number of durations (%d).',...
                    names{n}, numel(onsets{n}),numel(durations{n})); warning([merrmsg, errmsg]); sts = - 1; return;
            end
            switch timeunits
                case 'seconds'
                    if any(onsets{n})<0
                        errmsg=sprintf('Onset vector %d contains onsets smaller than 0 s', n); warning([merrmsg, errmsg]); sts = -1; return;
                    end
                case {'samples', 'markers'}
                    if any(fix(onsets{n})~=onsets{n})
                        errmsg=sprintf('Onset vector %d contains non-integers', n); warning([merrmsg, errmsg]); sts = -1; return;
                    end
            end
            if any(onsets{n} < 0)
                if numel(onsets{n}) == 1, onsets{n} = [];
                else
                    errmsg=sprintf('Negative event onsets in regressor %s', names{n}); warning([merrmsg, errmsg]); sts = -1; return;
                end
            end
        end
    end
    if ~isempty(find(ismember(who, 'pmod'), 1))
        if numel(pmod)>numel(names),  errmsg=sprintf('Number of parametric modulators (%d) does not match the number of onsets (%d).',...
                numel(pmod),numel(onsets)); warning([merrmsg, errmsg]); sts = -1; return;
        else
            for n=1:numel(pmod),
                for o=1:numel(pmod(n).param)
                    if numel(onsets{n}) ~= numel(pmod(n).param{o}),
                        errmsg= sprintf('"%s" & "%s": Number of event onsets (%d) does not equal the number of parameters (%d).',...
                            names{n}, pmod(n).name{o}, numel(onsets{n}),numel(pmod(n).param{o})); warning([merrmsg, errmsg]); sts = -1; return;
                    end
                end
            end
        end
    end
    
    if f > 1
        for n = 1:numel(names)
            if ~strcmpi(multi(1).n{n}, names{n})
                errmsg('Event names in sessions 1 and %.0f don''t match (%s and %s)', f, multi(1).n{n},names{n});
                warning(errmsg); sts = -1; return;
            end
        end
    end
    multi(f).n = names;
    multi(f).o = onsets;
    multi(f).d = durations;
    multi(f).p = parametric_confound;
    if exist('pmod')
        multi(f).pmod = pmod;
    end
    clear names onsets durations parametric_confound pmod
end