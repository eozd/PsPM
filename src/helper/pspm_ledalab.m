function [sts, outfile] = pspm_ledalab(datafile, outfile, options)
% pspm_ledalab is a wrapper that allows ledalab analysis from within
% SCRalyze, on SCRalyze data files.
% pspm_ledalab exports the first SCR and first event channel of a low pass 
% filtered and downsampled datafile to ledalab using pspm_scr2ledalab,
% performs analysis, and transforms ledalab results file to a "dummy" DCM
% file which can then be assessed with pspm_con1
% Because ledalab in batch mode works on directories rather than files, a
% new folder is created on the current path, where analysis is performed
% (named "SCR_ledalab"). After analysis (to enable using another method),
% files are renamed and moved to the current path. If required, they are
% deleted after being read out
% FORMAT: [sts, outfile] = pspm_ledalab(datafile, outfile, options)
%       options.overwrite: overwrite all existing files (default 0)
%       options.cleanup: clean up intermediate ledalab files (default 1)
%       options.method: 'nonnegative' ('DDA'), 'continuous' ('CDA'), 'both' (default)
%       options.norm: normalise SCR data (default: 0)
%__________________________________________________________________________
% PsPM 3.0
% (c) 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% $Id$
% $Rev$

% v003 drb 16.06.2014 adapted for new SCRalyze structure
% v002 drb 02.11.2013
% v001 drb 27.09.2012

% initialise
% -------------------------------------------------------------------------
sts = -1;
global settings
if isempty(settings), pspm_init; end;
fs = filesep;
ledapath = which('ledalab');
if isempty(ledapath), warning('Ledalab needs to be on the matlab path.'); return; end

% check input arguments
% -------------------------------------------------------------------------
if nargin<1
    errmsg=sprintf('No data file specified'); warning(errmsg); return;
elseif nargin<2
    errmsg=sprintf('No result file specified'); warning(errmsg); return;
end

try options.overwrite; catch, options.overwrite = 0; end;
try options.cleanup; catch, options.cleanup = 1; end;
try options.method; catch, options.method = 'both'; end;
if ~ischar(options.method)
    warning('Method needs to be a string argument.'); return;
elseif sum(strcmpi(options.method, {'nonnegative', 'DDA'})) > 0
    options.method = {'DDA'};
elseif sum(strcmpi(options.method, {'continuous', 'CDA'})) > 0
    options.method = {'CDA'};
elseif strcmpi(options.method, 'both');
    options.method = {'DDA', 'CDA'};
else
    warning('Unknown Ledalab analysis method'); return; 
end
options.filter = 1;
try options.norm; catch, options.norm = 0; end;

% does result file exist?
if exist(outfile, 'file')
    if ~options.overwrite
        overwrite = menu(sprintf('Result file (%s) already exists. Overwrite?', outfile), 'yes', 'no');
        close gcf;
        if overwrite == 2, return; end;
        clear overwrite
    end
    delete(outfile);
end

% does working directory exist?
workpath = [pwd, fs, 'SCR_ledalab'];
if exist(workpath, 'dir')
    if ~options.overwrite
        overwrite = menu(sprintf('Working path ''SCR_ledalab'' already exists. Delete everything?'), 'yes', 'no');                
        close gcf;
        if overwrite == 2, return; end;
        clear overwrite
    end
end

% note current path (because ledalab changes the directory)
cpth = pwd;

% get & export SCRalyze file
% -------------------------------------------------------------------------
[pth, datafn, ext] = fileparts(datafile);
ledafn{1} = ['ledalab_', datafn, ext];
sts = pspm_scr2ledalab(datafile, fullfile(cpth, ledafn{1}), options);
if sts ~= 1, warning('Data export to ledalab unsuccessful.'); return; end;

% perform ledalab analysis
% -------------------------------------------------------------------------
filecount = 2;
for k = 1:numel(options.method)
    % create fresh leda path with ledafile
    if exist(workpath, 'dir'), rmdir(workpath, 's'); end;
    mkdir(workpath);
    copyfile(fullfile(cpth, ledafn{1}), fullfile(workpath, ledafn{1}));
    % do the analysis
    Ledalab(workpath, 'open', 'leda', 'analyze', options.method{k}, 'optimize', 2, ...
        'export_era', [1 4 0.01 1]); 
    % rename files and copy to current path
    ledafiles = dir(workpath);
    for f = 3:numel(ledafiles)
        [pth, fn, ext] = fileparts(ledafiles(f).name);
        ledafn{filecount} = fullfile(cpth, [fn, '_', options.method{k}, ext]);
        movefile(ledafiles(f).name, ledafn{filecount});
        filecount = filecount + 1;
    end
    cd(cpth);
end
% remove working directory
rmdir(workpath, 's');

% extract ledalab results
% -------------------------------------------------------------------------
cnt = 1;
results = [];
description = {};
for k = 1:numel(options.method)
    % load result file
    [pth fn ext] = fileparts(ledafn{1});
    resfn = fullfile(cpth, [fn, '_era_', options.method{k}, ext]);
    inres = load(resfn);
    % acquire data
    res = inres.results.(options.method{k});
    % select measures
    if strcmpi(options.method{k}, 'CDA')
        results(cnt    , :) = res.AmpSum;
        results(cnt + 1, :) = res.SCR;
        results(cnt + 2, :) = res.ISCR;
        cnt = cnt + 3;
        description = [description, 'CDA/AmpSum', 'CDA/SCR', 'CDA/ISCR'];
    elseif strcmpi(options.method{k}, 'DDA')
        results(cnt    , :) = res.AmpSum;
        results(cnt + 1, :) = res.AreaSum;
        cnt = cnt + 2;
        description = [description, 'DDA/AmpSum', 'DDA/AreaSum'];
    end
end

% build 'dummy' DCM results structure
% -------------------------------------------------------------------------
for k = 1:size(results, 2)
    dcm.sn{1}.a(k).a = []; dcm.sn{1}.a(k).m = []; dcm.sn{1}.a(k).s = []; 
    dcm.sn{1}.e(k).a = results(:, k);
end
dcm.sn{1}.description = description;

dcm.stats = transpose([dcm.sn{1}.e.a]);
dcm.names = description;

dcm.modeltype = 'dcm';
dcm.modality = settings.modalities.glm;

% save & clean up
% -------------------------------------------------------------------------
save(outfile, 'dcm');
if options.cleanup
    for f = 1:numel(ledafn)
        delete(ledafn{f});
    end
end

return;
