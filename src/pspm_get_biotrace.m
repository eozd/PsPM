function [sts, import, sourceinfo] = pspm_get_biotrace(datafile, import)
% ● Description
%   pspm_get_biotrace imports text-exported Mindemedia BioTrace files.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_biotrace(datafile, import);
% ● Arguments
%   *   datafile : The data file to be imported
%   ┌─────import
%   ├───.channel : The channel to be imported, check pspm_import
%   ├──────.type : The type of channel, check pspm_import
%   ├────────.sr : The sampling rate of the file.
%   ├──────.data : The data read from the file.
%   └────.marker : The type of marker, such as 'continuous'
% ● Outputs
%         import : The import struct that saves importing information
%     sourceinfo : The struct that saves information of original data source
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
sourceinfo = [];

% get data
% -------------------------------------------------------------------------
fid = fopen(datafile);
bio.header = textscan(fid, '%s', 'Delimiter', '|');
fclose(fid);
fid = fopen(datafile);
bio.data   = textscan(fid, '%n%s', 'Delimiter', '\t', 'HeaderLines', 14);
fclose(fid);

% extract individual channels
% -------------------------------------------------------------------------
% check sample rate ---
if isempty(strfind(bio.header{1}{1}, 'RAW'))
  warning('Unrecognised data format\n.'); return
else
  foo = regexp(bio.header{1}{7}, '\s', 'split');
  sr = str2num(foo{3});
end;

% retrieve recording channel, date and time ---
foo = regexp(bio.header{1}{9}, ':', 'split');
sourceinfo.channel{1} = foo{2};
foo = regexp(bio.header{1}{4}, '\s', 'split');
sourceinfo.date = foo{2};
foo = regexp(bio.header{1}{5}, '\s', 'split');
sourceinfo.time = foo{2};

% loop through import jobs ---
for k = 1:numel(import)
  if strcmpi(import{k}.type, 'marker')
    foo = char(bio.data{end});
    import{k}.data = find(foo(:, 1) ~= ' ');
    import{k}.sr = 1/sr;
    import{k}.marker = 'timestamp';
    import{k}.markerinfo.name = bio.data{end}{import{k}.data};
    import{k}.markerinfo.name = NaN(numel(import{k}.markerinfo.name), 1);
  else
    import{k}.data = bio.data{1};
    import{k}.sr = sr;
  end;
end;
%% Return values
sts = 1;
return
