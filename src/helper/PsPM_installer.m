% This is a convenience PsPM installer. As an alternative, download the
% lastest release from https://github.com/bachlab/PsPM, or clone the
% develop branch.
% Uzay Gökay & Dominik Bach, 2025

fprintf('Welcome to the PsPM installer.\n');
[indx,tf] = listdlg('ListString',{'Latest PsPM release', 'GLM tutorial dataset', 'DCM tutorial dataset'}, ...
    'PromptString', 'Select items to install.');

if tf == 0
    fprintf('PsPM installation aborted.\n');
    return;
end

fprintf('Please select the parent directory for your PsPM installation.\n');
destinationFolder = uigetdir('','Select parent directory for your PsPM installation');

% -------------------------------------------------------------------------

if ismember(1, indx)

    % GitHub release URL for PsPM and the desired version
    githubReleaseURL = 'https://github.com/bachlab/PsPM/releases/download'; 
    version = 'v7.0.0';
    packageName = 'PsPM_v7.0.0';

    % Create the destination folder if it does not exist
    if ~exist(destinationFolder, 'dir')
        mkdir(destinationFolder);
    end

    % Construct the full URL for the specified version and platform (assuming Windows)
    matlabPackageURL = sprintf('%s/%s/%s.zip', githubReleaseURL, version, packageName);

    % Download the PsPM package
    disp(['Downloading PsPM version ' version '...']);
    websave('temp_package.zip', matlabPackageURL);

    % Unzip the contents to the destination folder
    disp('Unzipping package...');
    unzip('temp_package.zip', destinationFolder);

    % Clean up: delete the temporary ZIP file
    delete('temp_package.zip');

    disp(['PsPM package ' version ' download and unzip completed.']);
    
    %%%%%%%%%%%%%%%%%% add path %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Add the unzipped PsPM files to the MATLAB search path
    addpath(fullfile(destinationFolder, packageName));

    disp('PsPM added to MATLAB search path.');
end


%%%%%%%%%%% GLM dataset %%%%%%%%%%%%%%
if ismember(2, indx)
    % URL for the PsPM GLM tutorial dataset
    glmTutorialDatasetURL = 'https://github.com/bachlab/PsPM-tutorial-datasets/releases/download/tutorial-datasets/Tutorial_dataset_GLM.zip';
    glmTutorialDatasetName = 'Tutorial_dataset_GLM';

    % Destination folder for the tutorial dataset
    tutorialDestinationFolder = fullfile(destinationFolder, glmTutorialDatasetName);

    % Create the destination folder if it does not exist
    if ~exist(tutorialDestinationFolder, 'dir')
        mkdir(tutorialDestinationFolder);
    end

    % Download the PsPM tutorial dataset
    disp('Downloading GLM tutorial dataset...');
    websave('temp_tutorial_dataset.zip', glmTutorialDatasetURL);

    % Unzip the tutorial dataset to the destination folder
    disp('Unzipping GLM tutorial dataset...');
    unzip('temp_tutorial_dataset.zip', tutorialDestinationFolder);

    % Clean up: delete the temporary ZIP file
    delete('temp_tutorial_dataset.zip');

    disp('GLM tutorial dataset download and unzip completed.');
end

%%%%%%%%%%%%%%% DCM Dataset %%%%%%%%%%%%%%%
if ismember(3, indx)
    % URL for the PsPM DCM tutorial dataset
    dcmTutorialDatasetURL = 'https://github.com/bachlab/PsPM-tutorial-datasets/releases/download/tutorial-datasets/Tutorial_dataset_DCM.zip';
    dcmTutorialDatasetName = 'Tutorial_dataset_DCM';

    % Destination folder for the DCM tutorial dataset
    dcmTutorialDestinationFolder = fullfile(destinationFolder, dcmTutorialDatasetName);

    % Create the destination folder if it does not exist
    if ~exist(dcmTutorialDestinationFolder, 'dir')
        mkdir(dcmTutorialDestinationFolder);
    end

    % Download the PsPM DCM tutorial dataset
    disp('Downloading DCM tutorial dataset...');
    websave('temp_dcm_tutorial_dataset.zip', dcmTutorialDatasetURL);

    % Unzip the DCM tutorial dataset to the destination folder
    disp('Unzipping DCM tutorial dataset...');
    unzip('temp_dcm_tutorial_dataset.zip', dcmTutorialDestinationFolder);

    % Clean up: delete the temporary ZIP file
    delete('temp_dcm_tutorial_dataset.zip');

    disp('DCM tutorial dataset download and unzip completed.');

end

