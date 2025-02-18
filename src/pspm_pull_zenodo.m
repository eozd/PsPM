function sts = pspm_pull_zenodo(ID, datapath)
% ● Description
%   pspm_pull_zenodo pulls data from zenodo.org

fprintf('Pulling data set %i from zenodo.org\n', ID);
mkdir(datapath);

zipfiles = {'Data', 'Data_pp'};
for iFiles = 1:2
    url = ['https://zenodo.org/record/',num2str(ID), '/files/', zipfiles{iFiles}, '.zip'];
    zipfn = fullfile(datapath, [zipfiles{iFiles}, '.zip']);
    try
        websave(zipfn, url);
    catch
        tempfile = [zipfn, '.html'];
        if exist(tempfile)
            delete(tempfile)
        end
        fprintf('File ''%s'' does not exist on the remote storage.\n', zipfiles{iFiles})
    end
    if exist(zipfn, 'file')
        matfileno(1) = numel(dir(fullfile(datapath, '*.mat')));
        zipflag = 0;
        try
            unzip(zipfn, datapath);
        catch
            zipflag = 1;
        end
        matfileno(2) = numel(dir(fullfile(datapath, '*.mat')));
        newdir = dir(datapath);
        newpathindx = (arrayfun(@(x) x.isdir & ~ismember(x.name, {'.', '..'}), newdir));
        if zipflag || (diff(matfileno)==0 && sum(newpathindx) == 0)
            warning('Error unzipping data set. This is a known Matlab problem which can happen for large files (> 2 GB). Please unzip manually.');
        elseif  sum(newpathindx) > 1
            warning('Unknown error extracting data set.');
            return
        else
            delete(zipfn);
        end

        if any(newpathindx)
            newpath = fullfile(datapath, newdir(newpathindx).name);
            filelist = dir(fullfile(newpath, '*.mat'));
            oldfile = fullfile(newpath, {filelist.name});
            newfile = fullfile(datapath, {filelist.name});
            for i_fn = 1:numel(oldfile)
                movefile(oldfile{i_fn}, newfile{i_fn});
            end
            rmdir(newpath);
        end
    end
end


sts = 1;