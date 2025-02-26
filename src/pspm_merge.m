function [sts, outfile] = pspm_merge(infile1, infile2, reference, options)
% ● Description
%   pspm_merge merges two PsPM datafiles recorded in an overlapping time 
%   interval by "stacking" the channels from the two files. It then writes
%   the result into a new file with the same name as the first file, 
%   prepended with 'm'. The channels are aligned to file start, or to first 
%   marker. If the recordings are not matching exactly, channel data will
%   be expanded by NaNs. 
% ● Format
%   [sts, outfile] = pspm_merge(infile1, infile2, reference, options)
% ● Arguments
%   *         infile1 : data file name(s) (char)
%   *         infile2 : data file name(s) (char)
%   *       reference : Determines how the two files are aligned. 
%                       1. 'marker': Align files with respect to first marker
%                       in either file. 
%                       2. 'file': Align files with respect to file start.
%   ┌─────────options
%   ├──────.overwrite : overwrite existing file by default
%   │                   [logical] (0 or 1)
%   │                   Default value: determined by pspm_overwrite.
%   └.marker_chan_num : 2-element vector of marker channel numbers to be used
%                       as a reference. Ignored if reference is specified 
%                       as 'file'. If undefined or 0, the first marker 
%                       channel of either file is used
% ● Outputs
%   *             sts : status flag (-1 or 1)
%   *         outfile : path of the merged file (char).
%                       Empty if not successfully merged.
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (UZH, WTCN)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
    pspm_init;
end
sts = -1;
outfile = [];


%% Check input
% check missing input --
if nargin < 3
    warning('Not enough input'); return;
end

% check faulty input --
if ~ischar(reference) || ~ismember(reference, {'marker', 'file'})
    warning('Reference must be ''marker'' or ''file''.'); return;
end

% check options --
options = pspm_options(options, 'merge');
if options.invalid
    return
end

%% loop through data files
% read input files --
infile = {infile1, infile2};
infos = cell(2,1);
data = cell(2,1);
for iNum = 1:2
    [sts_load_data, infos, data] = pspm_load_data(infile{iNum});
    if sts_load_data ~= 1
        return;
    end
end
% for marker alignment, trim data before first marker --
if strcmpi(reference, 'marker')
    for iNum = 1:2
        trimdata.data = data{iNum}; trimdata.infos = infos;
        trimoptions.marker_chan_num = options.marker_chan_num(iNum);
        trimdata = pspm_trim(trimdata, 0, 'none', 'marker', trimoptions);
        data{iNum} = trimdata.data; infos{iNum} = trimdata.infos;
    end
end
% put together and cut away data from the end --
[sts_align_channels, data, duration] = pspm_align_channels([data{1}; data{2}]);
if sts_align_channels ~= 1
    return;
end
% collect infos --
oldinfos = infos; infos = struct([]);
infos(1).duration = duration;
try infos.sourcefile = {oldinfos{1}.importfile; oldinfos{2}.importfile}; end
try infos.importfile = {oldinfos{1}.importfile; oldinfos{2}.importfile}; end
try infos.importdate = {oldinfos{1}.importdate; oldinfos{2}.importdate}; end
try infos.recdate = {oldinfos{1}.recdate; oldinfos{2}.recdate}; end
try infos.rectime = {oldinfos{1}.rectime; oldinfos{2}.rectime}; end
infos.mergedate = date;
infos.mergedref = reference;
% create output file name and save data --
[pth, fn, ext] = fileparts(infile{1}{iFile});
outfile = fullfile(pth, ['m', fn, ext]);
infos.mergedfile = outfile;
outdata.data = data;
outdata.infos = infos;
options.overwrite = pspm_overwrite(outfile, options);
outdata.options = options;
sts_load_data = pspm_load_data(outfile, outdata);
if sts_load_data ~= 1, return; end

sts = 1;
