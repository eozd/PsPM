function output = pspm_cfg_selector_outputfile(outtype, varargin)
% output = pspm_cfg_selector_modelfile(outtype)
%  modelfile = pspm_cfg_selector('run', job)
% outtype: char, used in the help text


if nargin < 1
    outtype = 'Output';
elseif strcmpi(outtype, 'run')
    job = varargin{1};
    [pth, fn, ext] = fileparts(job.output.file);
    if nargin >= 3
        ext = varargin{2};
    else
        ext = 'mat';
    end
    output = fullfile(job.output.dir{1}, [fn, '.', ext]);
    return
end

% Output file
outfile         = cfg_entry;
outfile.name    = sprintf('%s file name', outtype);
outfile.tag     = 'file';
outfile.strtype = 's';
outfile.help    = {sprintf('Specify name for the resulting %s file.', lower(outtype))};

% Output directory
outdir         = cfg_files;
outdir.name    = sprintf('%s directory', outtype);
outdir.tag     = 'dir';
outdir.filter  = 'dir';
outdir.num     = [1 1];
outdir.help    = {sprintf('Specify directory where the resulting %s file will be written.', lower(outtype))};

% overwrite settings
overwrite = pspm_cfg_selector_overwrite;

% branch
output       = cfg_branch;
output.name  = sprintf('%s file', outtype);
output.tag   = 'output';
output.val   = {outfile, outdir, overwrite};
output.help  = {sprintf('Specify location for the resulting %s file.', lower(outtype))};

