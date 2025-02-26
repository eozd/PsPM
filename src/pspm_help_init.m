function out = pspm_help_init
% ● Description
%   pspm_help_init sets up the help texts for matlabbatch GUI. 
% ● Developer
%   This is work in progress.

%% get functions list
[pth, fname, ext] = fileparts(mfilename('fullpath'));

filelist = dir(fullfile(pth, '*.m'));

% loop through functions
for i = 1:numel(filelist)
    fn = fullfile(filelist(i).folder, filelist(i).name);
    [pth, fname, ext] = fileparts(fn);
    try 
        information = pspm_help(fn);
    catch
        information = [];
    end
    out.(fname) = information;
end
