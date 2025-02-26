function [sts, outfile] = pspm_rename(filename, newfilename, options)
% ● Description
%   pspm_ren renames a PsPM datafile and updates the internal structure
%   (the field 'infos') with the new file name. 
% ● Format
%   [sts, newfilename] = pspm_ren(filename, newfilename, options)
% ● Arguments
%   *    filename :  name of an existing PsPM file
%   * newfilename :  new name of the PsPM file
%   ┌─────options
%   └──.overwrite :  [Optional, logical] overwrite existing file by default
%                    The default value is determined by pspm_overwrite.
% ● Outputs
%   *             sts : status flag (-1 or 1)
%   *         outfile : path of the renamed file (char).
%                       Empty if not successfully merged.
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
outfile = [];

if nargin < 2 || ~ischar(newfilename)
  warning('ID:invalid_input', 'No new filename given.');
  return;
elseif nargin < 3
    options = struct();
end

options = pspm_options(options, 'rename');
if options.invalid
  return
end

%-------------------------------------------------------------------------
% work on file
%-------------------------------------------------------------------------
[pth, nfn, ext] = fileparts(newfilename);
if isempty(ext)
    ext = '.mat';
end
if isempty(pth)
    [pth, ~, ~] = fileparts(filename);
end
fnfn = fullfile(pth, [nfn, ext]);
[sts_load_data, infos, data] = pspm_load_data(filename);
if ~sts_load_data
    return;
end
infos.rendate = date;
infos.newname = [nfn ext];
sts = pspm_load_data(fnfn, struct('data', {data}, 'infos', infos, 'options', options));
if sts < 1
    return
end
delete(filename);
outfile = fnfn;
