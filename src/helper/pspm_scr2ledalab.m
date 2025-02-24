function [sts, outfile] = pspm_scr2ledalab(datafile, outfile, options)
% pspm_scr2ledalab is a function for exporting SCRalyze files to ledalab
% format (for method comparison)
% exports (first) SCR and (first) evend channel of data file
% this version does not support export of event names/values (instead, a
% '1' is written to all ledalab event fields
%
% FORMAT: [sts, outfile] = pspm_scr2ledalab(datafile, outfile, options)
%                       options.overwrite - overwrite existing files
%                       options.filter - apply low pass filter and
%                       downsample as specified in settings
%                       options.norm: normalise data (default: no)
%
%__________________________________________________________________________
% PsPM
% (C) 2012 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% v003 drb 04.11.2013 allow normalisation & bugfixes
% v002 drb 26.09.2012 fixed event import
% v001 drb 27.08.2012

% $Id$
% $Rev$

% initialise
%--------------------------------------------------------------------------

global settings;
if isempty(settings), pspm_init; end;

sts = -1;

% check input arguments, set options
%--------------------------------------------------------------------------

if nargin < 1
    warning('No data file specified'); return;
elseif nargin < 2
    warning('No output file specified'); return;
elseif ~exist(datafile, 'file')
    warning('Input file does not exist'); return
end

try options.overwrite; catch, options.overwrite = 0; end;
try options.filter; catch, options.filter = 0; end;
try options.norm; catch, options.norm = 0; end;

% get and check SCR file
%--------------------------------------------------------------------------
[sts, infos, scr] = pspm_load_data(datafile, 'scr');
if sts == -1 || isempty(scr)
    warning('\nExport to ledalab unsuccesful'); return;
elseif numel(scr) > 1
    warning('n\SCRalyze file contains more than one SCR channel - first one will be exported');
end

if options.filter == 1
    filt.lpfreq = 5; filt.lporder = 1;
    filt.hpfreq = 'none'; filt.hporder = 1;
    filt.direction = 'uni';
    filt.sr = scr{1}.header.sr;
    filt.down = 10;
   [sts, newscr, newsr] = pspm_prepdata(scr{1}.data, filt);
   clear scr
   scr.data = newscr; scr.header.sr = newsr;
else
    scr = scr{1};
end
if options.norm == 1;
    scr.data = scr.data/std(scr.data);
end

[sts, infos, events] = pspm_load_data(datafile, 'events');
if sts == -1 || isempty(events)
    events.data = [];
    events.header = [];
elseif numel(events) > 1
    warning('n\SCRalyze file contains more than one event channel - first one will be exported');
end
if ~isempty(events)
    events = events{1};
end

% construct elements of ledalab file
%--------------------------------------------------------------------------
clear data
data.conductance = transpose(scr.data(:));
data.time        = (1/scr.header.sr):(1/scr.header.sr):(numel(scr.data)/scr.header.sr);
data.timeoff     = 0;
for k = 1:numel(events.data)
    data.event(k).time  = events.data(k);
    data.event(k).nid   = 1;
    data.event(k).name  = '1';
    data.event(k).userdata.duration  = .01;
end

clear fileinfo
fileinfo.version = 3.44;
fileinfo.date    = date;
fileinfo.log     = {'Created by SCRalyze for use with Ledalab 3.44.'};

% check output file & save data
%--------------------------------------------------------------------------
if exist(outfile, 'file') == 2 && options.overwrite ~= 1
    if feature('ShowFigureWindows')
        msg = ['Imported file already exists. Overwrite?', newline, 'Existing file: ',outfile];
        overwrite = questdlg(msg, 'File already exists', 'Yes', 'No', 'No'); % default not to overwrite by users 
    else
        overwrite = 'No'; % default not to overwrite on Jenkins
    end             
    close gcf;
else
    overwrite = 'Yes';
end
if strcmp(overwrite, 'No')
    warning('Data discarded ...');
    return;
else
    save(outfile, 'data', 'fileinfo');
end
sts = 1;
return;

