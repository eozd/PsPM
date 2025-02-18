function [sts, markerinfo] = pspm_get_markerinfo(fn, options)
% ● Description
%   pspm_get_markerinfo extracts markerinfo from PsPM files that contain
%   such information (e.g. BrainVision or NeuroScan), and returns this or 
%   writes it into a matlab file with a struct variable 'markerinfo', with
%   one element per unique marker name/value.
% ● Format
%   [sts, markerinfo] = pspm_get_markerinfo(filename, options)
% ● Arguments
%   *   filename : [char]
%                  name of PsPM file
%                  if empty, you will be prompted for one
%   ┌────options
%   ├.marker_chan_num:  [int] marker channel number.
%   │                   if undefined or 0, first marker channel is used.
%   ├──.filename : [char]
%   │              name of a file to write the markerinfo to;
%   │              default value: empty, meaning no file will be written
%   └──overwrite : [logical] (0 or 1)
%                  Define whether to overwrite existing output files or not.
%                  Default value: determined by pspm_overwrite.
% ● Outputs
%   *        sts : [double]
%                  default value: -1 if unsuccessful
%   ┌─markerinfo : [struct]
%   ├──────.name : [char]
%   ├─────.value : ...
%   └───.element : ...
% ● History
%   Introduced in PsPM 6.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
markerinfo = [];
%% get info
if nargin <= 1
  options = struct();
end
options = pspm_options(options, 'get_markerinfo');
% check input arguments
if nargin < 1 || isempty(fn)
  fn = spm_select(1, 'mat', 'Extract markers from which file?');
end
% get file
[bsts, data] = pspm_load_channel(fn, options.marker_chan_num, 'marker');
if bsts == -1, return, end
% check markers
if ~isfield(data, 'markerinfo')
  sts = -1;
  warning('File (%s) contains no event marker infos', fn);
  return;
end
%% extract markers: find unique type/value combinations ...
markertype = data.markerinfo.name;
markervalue = data.markerinfo.value;
markerall = strcat(markertype', regexp(num2str(markervalue'), '\s+', 'split'));
markerunique = unique(markerall);
% ... and write them into a struct
for k = 1:numel(markerunique)
  % find all elements
  indx = find(strcmpi(markerall, markerunique{k}));
  % and use first one to extract type and value information
  markerinfo(k).name = markertype{indx(1)};
  markerinfo(k).value = markervalue(indx(1));
  markerinfo(k).elements = indx';
end
% if necessary, write into a file
outfn = options.filename;
if ~isempty(outfn)
  ow = pspm_overwrite(outfn, options);
  if ow
    save(outfn, 'markerinfo');
  end
end
sts = 1;
return
