function sts = pspm_import_bids(dataset_path, save_path)
% function sts = pspm_import_bids(dataset_path, save_path)
% PSPM_IMPORT_BIDS
%   reads a BIDS formatted pupil and physio datasets(experimental readings for a set of participants) from a given data path
%   stores data in pspm formatted structures

% dataset_path = './input/data';
% save_path = './output/';

addpath(fullfile('lib'));

% Load combined data
combined_dataset = load_bids_dataset(dataset_path);

% Save the combined dataset into a single MAT file
save_combined_dataset(combined_dataset, save_path);

sts = 1;
end