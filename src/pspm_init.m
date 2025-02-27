function pspm_init
% ● Description
%   pspm_init initializes PsPM by determining the path and loading settings
%   into the main workspace.
%   1 license & user output
%   2 check
%     2.1 check pspm version
%     2.2 check pspm path
%     2.3 check matlab version
%     2.4 check signal processing toolbox
%     2.5 check SPM
%     2.6 check matlabbatch
%     2.7 check pspm_cfg
%     2.8 check VBA
%   3 channel type (channeltype) definitions
%     3.1 SCR
% ● Arguments
%   ┌──defaults
%   ├─.channeltypes: List of all allowed PsPM channel types (e.g., SCR, ECG, Pupil).
%   ├─.import: Settings and definitions for importing various data file formats.
%   └─.lateral: Defines how PsPM denotes left, right, or combined channels.
%   //  ... (not complete)
%   ┌──defaults.import
%   └─.channeltypes : Subset of channel types that are allowed for direct data import.
%   //  ... (not complete)
% ● History
%   Introduced in PsPM 3.1
%   Written in 2009-2015 by Dominik R Bach (WTCN, UZH)
%   Maintained in 2022 by Teddy
%   Updated in 2024 by Dominik R Bach (Uni Bonn)

%% 0 Cleaning terminal outputs and initialise
clc;
global settings;
settings = struct();
defaults = struct();

%% 1 license & user output
fid = fopen('pspm_msg.txt');
msg = textscan(fid, '%s', 'Delimiter', '$');
fclose(fid);
clear fid
for n = 1:numel(msg{1})
  fprintf('%s\n', msg{1}{n});
end
fprintf('PsPM: loading defaults ... \n');
% initialise the help and output texts which are already used in pspm_init
defaults.help = pspm_help_init;

%% 2 Check versions & paths
added_paths = {};
removed_paths = {};
p = path;
initial_paths = strsplit(p, pathsep);
required_folders = {{'pspm_cfg'}, ...
  {'ext','SPM'}, ...
  {'ext','VBA'}, ...
  {'ext','matlabbatch'}, ...
  {'ext','VBA','subfunctions'}, ...
  {'ext','VBA','stats&plots'}, ...
  {'ext','matlabbatch','cfg_basicio'}};
pspm_root = fileparts(which('pspm_init'));

% 2.1 Check matlab version --
% PsPM provides support for MATLAB with up to five years. For version 7.0, 
% the earlist version of MATLAB is 2019.
release_date_current = datetime(version('-date'));
release_date_supported = datetime('01-Jan-2019');
if release_date_current < release_date_supported
  warning(append('You are using an unsupported Matlab version. ',...
    'In case you encounter any problems, please consider upgrading MATLAB to use PsPM.'));
end

% 2.2 Check matlab toolbox: signal processing --
tboxes = ver;
signal = any(strcmp({tboxes.Name}, 'Signal Processing Toolbox'));
if ~signal
  warning('Signal processing toolbox not installed. Some filters might not be implemented.');
end

% 2.3 Check PsPM version --
pspm_vers = pspm_version('check');

% 2.4 Add required paths ---
for k = 1:numel(required_folders)
    required_path{k} = pspm_path(required_folders{k}{:});
    if ~any(strcmp(initial_paths, required_path{k}))
        added_paths{end+1} = required_path{k};
    end
end

% 2.5 Check if subfolders are already in path --
filelist = dir(fullfile(pspm_root, ['**',filesep,'*.*']));
subfolders_full = unique({filelist.folder});
subfolders = erase(subfolders_full,pspm_root);
subfolders = subfolders(~strcmp(subfolders,pspm_root));
subfolders = subfolders(contains(subfolders,filesep));
subfolders = append(pspm_root,subfolders);
subfolders = setdiff(subfolders, required_path);
contained_subfolder_index = ismember(subfolders,initial_paths);
flag_contain_subfolder = any(contained_subfolder_index);
if flag_contain_subfolder
  if strcmp(questdlg(sprintf(pspm_help_text('warntext_subfolder')),...
      'Subfolder detected',...
      'Yes', 'No', 'Yes'), 'Yes')
    removed_paths = [removed_paths, subfolders(contained_subfolder_index)];
  else
    error(pspm_help_text('errortext_subfolder'));
  end
end

% 2.6 Check for SPM and Matlabbatch conflicts--
% Check if SPM software is on the current Path.
% Dialog Window open to ask whether to remove program from the path or quit pspm_init.
% Default is to quit pspm_init.
spm_folders = {'spm', 'cfg_ui'}; %, 
for k = 1:numel(spm_folders)
    spm_path{k} = fileparts(which(spm_folders{k}));
end
spm_path = setdiff(spm_path, required_path);
spm_path_idx = cellfun(@(x) ~isempty(x), spm_path);
if any(spm_path_idx)
  if strcmp(questdlg(sprintf(pspm_help_text('warntext_spm_remove')),...
      'Interference with SPM software',...
      'Yes', 'No', 'No'), 'Yes')
    removed_paths = [removed_paths, spm_path(spm_path_idx)];
  else
    % quit pspm_init
    error(pspm_help_text('errortext_spm_quit'));
  end
end


% 2.7 Execute path handling
removed_paths = unique(removed_paths);
for k = 1:numel(removed_paths)
    rmpath(removed_paths{k});
end
added_paths = unique(added_paths);
for k = 1:numel(added_paths)
    addpath(added_paths{k});
end

%% 3 Channel types
%
% 3.1 allowed channel types
%
% DEVELOPERS NOTES
% in order to implement new channel types
% to defaults.import.channeltypes. If direct import is allowed, create the
% associated pspm_get_xxx import function. See first channel type (SCR) for
% explanations.
% These are the allowed channeltypes in a data file (checked by pspm_load_data)
% channeltypes are not ordered.
%
s_t = 'type'; % data type
s_de = 'description';
s_i = 'import';
s_da = 'data'; % wave is continuous, events are discrete
%                                  Variable type            Description                                       Import function           Data type
% 3.1 SCR
defaults.channeltypes(1) =     struct(s_t, 'scr',              s_de, 'SCR',                                      s_i, @pspm_get_scr,       s_da, 'wave');
% 3.2 ECG
defaults.channeltypes(end+1) = struct(s_t, 'ecg',              s_de, 'ECG',                                      s_i, @pspm_get_ecg,       s_da, 'wave');
% 3.3 Heart rate
defaults.channeltypes(end+1) = struct(s_t, 'hr',               s_de, 'Heart rate',                               s_i, @pspm_get_hr,        s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'hp',               s_de, 'Heart period',                             s_i, @pspm_get_hp,        s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'hb',               s_de, 'Heart beat',                               s_i, @pspm_get_hb,        s_da, 'events');
defaults.channeltypes(end+1) = struct(s_t, 'resp',             s_de, 'Respiration',                              s_i, @pspm_get_resp,      s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'rr',               s_de, 'Respiration rate',                         s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'rp',               s_de, 'Respiration period',                       s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'ra',               s_de, 'Respiration amplitude',                    s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'rfr',              s_de, 'Respiratory flow rate',                    s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'rs',               s_de, 'Respiration time stamp',                   s_i, @none,               s_da, 'events');
defaults.channeltypes(end+1) = struct(s_t, 'emg',              s_de, 'EMG',                                      s_i, @pspm_get_emg,       s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'emg_pp',           s_de, 'EMG preprocessed',                         s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'marker',           s_de, 'Marker',                                   s_i, @pspm_get_marker,    s_da, 'events');
defaults.channeltypes(end+1) = struct(s_t, 'snd',              s_de, 'Sound channel',                            s_i, @pspm_get_sound,     s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'ppg',              s_de, 'Photoplethysmography',                     s_i, @pspm_get_ppg,       s_da, 'wave');
% Gaze X
defaults.channeltypes(end+1) = struct(s_t, 'gaze_x',           s_de, 'Gaze x',                                   s_i, @pspm_get_gaze_x,    s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'gaze_x_l',         s_de, 'Gaze x left',                              s_i, @pspm_get_gaze_x_l,  s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'gaze_x_r',         s_de, 'Gaze x right',                             s_i, @pspm_get_gaze_x_r,  s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'gaze_x_c',         s_de, 'Gaze x combined',                          s_i, @pspm_get_gaze_x_c,  s_da, 'wave');
% Gaze Y
defaults.channeltypes(end+1) = struct(s_t, 'gaze_y',           s_de, 'Gaze y',                                   s_i, @pspm_get_gaze_y,    s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'gaze_y_l',         s_de, 'Gaze y left',                              s_i, @pspm_get_gaze_y_l,  s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'gaze_y_r',         s_de, 'Gaze y right',                             s_i, @pspm_get_gaze_y_r,  s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'gaze_y_c',         s_de, 'Gaze y combined',                          s_i, @pspm_get_gaze_y_c,  s_da, 'wave');
% Pupil
defaults.channeltypes(end+1) = struct(s_t, 'pupil',            s_de, 'Pupil',                                    s_i, @pspm_get_pupil,     s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'pupil_l',          s_de, 'Pupil left',                               s_i, @pspm_get_pupil_l,   s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'pupil_r',          s_de, 'Pupil right',                              s_i, @pspm_get_pupil_r,   s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'pupil_c',          s_de, 'Pupil combined',                           s_i, @pspm_get_pupil_c,   s_da, 'wave');
% Pupil missing
defaults.channeltypes(end+1) = struct(s_t, 'pupil_missing',    s_de, 'Pupil data missing',                       s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'pupil_missing_l',  s_de, 'Pupil data missingleft',                   s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'pupil_missing_r',  s_de, 'Pupil data missing right',                 s_i, @none,               s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'pupil_missing_c',  s_de, 'Pupil data missing combined',              s_i, @none,               s_da, 'wave');
% Blink
defaults.channeltypes(end+1) = struct(s_t, 'blink_l',          s_de, 'Blink left',                               s_i, @pspm_get_blink_l,   s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'blink_r',          s_de, 'Blink right',                              s_i, @pspm_get_blink_r,   s_da, 'wave');
% Saccade
defaults.channeltypes(end+1) = struct(s_t, 'saccade_l',        s_de, 'Saccade left',                             s_i, @pspm_get_saccade_l, s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'saccade_r',        s_de, 'Saccade right',                            s_i, @pspm_get_saccade_r, s_da, 'wave');
% Scanpath
defaults.channeltypes(end+1) = struct(s_t, 'sps',              s_de, 'Scanpath speed',                           s_i, @pspm_get_sps,       s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'sps_l',            s_de, 'Scanpath speed left',                      s_i, @pspm_get_sps_l,     s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'sps_r',            s_de, 'Scanpath speed right',                     s_i, @pspm_get_sps_r,     s_da, 'wave');
defaults.channeltypes(end+1) = struct(s_t, 'sps_c',            s_de, 'Scanpath speed combined',                  s_i, @pspm_get_sps_c,     s_da, 'wave');
% Custom
defaults.channeltypes(end+1) = struct(s_t, 'custom',           s_de, 'Custom',                                   s_i, @pspm_get_custom,    s_da, 'wave');

for k = 1:numel(defaults.channeltypes)
  if strcmpi(func2str(defaults.channeltypes(k).import), 'none')
    indx(k) = 0;
  else
    indx(k) = 1;
  end
end

defaults.importchanneltypes = defaults.channeltypes(indx==1);

%% 4 General import settings
%
% DEVELOPERS NOTES
% in order to implement new datatype import, add a field
% to defaults.import.datatypes and create the associated pspm_get_xxx
% function. See first datatype (CED smr) for explanations.

% TEMPLATE
% defaults.import.datatypes(i) =
% struct('short',           'XXX',...                                   % short name for internal purposes
%       'long',             'XXX',...                                   % long name for GUI
%       'ext',              'XXX',...                                   % data file extension
%       'funct',            @pspm_get_XXX,...                           % import function
%       'channeltypes',     {{defaults.importchanneltypes.type}},...    % allowed channel types
%       'chandescription',  'XXX',...                                   % description of channels for GUI
%       'multioption',      X,...                                       % allow import of multiple channels for GUI
%       'searchoption',     X,...                                       % allow channel name search for GUI
%       'automarker',       X,...                                       % marker not stored in separate channel
%       'autosr',           X,...                                       % sample rate automatically assigned
%       'help',             '');                                        % helptext from structure gui

%
% 4.1 Cambridge Electronic Design (CED) Spike file -- smr
defaults.import.datatypes(1) = struct(...
  'short',            'smr',...
  'long',             'CED Spike (.smr)',...
  'ext',              'smr',...
  'funct',            @pspm_get_smr,...
  'channeltypes',     {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.2 Cambridge Electronic Design (CED) Spike file -- smrx
defaults.import.datatypes(end+1) = struct(...
  'short',            'smrx',...
  'long',             'CED Spike (.smrx)',...
  'ext',              'smrx',...
  'funct',            @pspm_get_smrx,...
  'channeltypes',     {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.3 Matlab files
defaults.import.datatypes(end+1) = struct(...
  'short',            'mat',...
  'long',             'Matlab',...
  'ext',              'mat',...
  'funct',            @pspm_get_mat,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'cell/column',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       0,...
  'autosr',           0);
%
% 4.4 Text files
defaults.import.datatypes(end+1) = struct(...
  'short',            'txt',...
  'long',             'Text',...
  'ext',              'txt',...
  'funct',            @pspm_get_txt,...
  'channeltypes',        {{defaults.importchanneltypes(strcmpi('wave',{defaults.importchanneltypes.data}) | strcmpi('marker', {defaults.importchanneltypes.type})).type}},...  %all wave channels + marker
  'chandescription',  'column',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           0);

%
% 4.5 Biopac Acknowledge up to version 3.9.0
defaults.import.datatypes(end+1) = struct(...
  'short',            'acq',...
  'long',             'Biopac Acqknowledge (.acq, up to version 3.9.0)',...
  'ext',              'acq',...
  'funct',            @pspm_get_acq,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.6 Biopac Acknowledge any version
defaults.import.datatypes(end+1) = struct(...
  'short',            'acq_python',...
  'long',             'Biopac Acqknowledge using Python/bioread (.acq, any version)',...
  'ext',              'acq',...
  'funct',            @pspm_get_acq_python,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.7 exported Biopac Acqknowledge (tested on version 4.2.0)
defaults.import.datatypes(end+1) = struct(...
  'short',            'acqmat',...
  'long',             'matlab-exported Biopac Acqknowledge (.mat, version 4.0 or higher)',...
  'ext',              'mat',...
  'funct',            @pspm_get_acqmat,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.8 bioread converted Biopac Acqknowledge (any version)
defaults.import.datatypes(end+1) = struct(...
  'short',            'acq_bioread',...
  'long',             'bioread-converted Biopac Acqknowledge (.mat, any version)',...
  'ext',              'mat',...
  'funct',            @pspm_get_acq_bioread,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.9 ADInstruments Labchart  (any Version)
defaults.import.datatypes(end+1) = struct(...
  'short',            'labchartmat',...
  'long',             'ADInstruments LabChart (any Version, Windows only)',...
  'ext',              'adicht',...
  'funct',            @pspm_get_labchart,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...  %all except hb
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.10 exported ADInstruments Labchart up to 7.1
defaults.import.datatypes(end+1) = struct(...
  'short',            'labchartmat_ext',...
  'long',             'matlab-exported ADInstruments LabChart 7.1 or lower',...
  'ext',              'mat',...
  'funct',            @pspm_get_labchartmat_ext,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...  %all except hb
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.11 exported ADInstruments Labchart 7.2 or higher
defaults.import.datatypes(end+1) = struct(...
  'short',            'labchartmat_in',...
  'long',             'matlab-exported ADInstruments LabChart 7.2 or higher',...
  'ext',              'mat',...
  'funct',            @pspm_get_labchartmat_in,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.12 VarioPort
defaults.import.datatypes(end+1) = struct(...
  'short',            'vario',...
  'long',             'VarioPort (.vdp)',...
  'ext',              'vpd',...
  'funct',            @pspm_get_vario,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.13 exported Biograph Infiniti
defaults.import.datatypes(end+1) = struct(...
  'short',            'biograph',...
  'long',             'text-exported Biograph Infiniti',...
  'ext',              'txt',...
  'funct',            @pspm_get_biograph,...
  'channeltypes',        {{'scr', 'hb', 'resp'}},...
  'chandescription',  'channel',...
  'multioption',      0,...
  'searchoption',     0,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.14 exported MindMedia Biotrace
defaults.import.datatypes(end+1) = struct(...
  'short',            'biotrace',...
  'long',             'text-exported MindMedia Biotrace',...
  'ext',              'txt',...
  'funct',            @pspm_get_biotrace,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...
  'chandescription',  'channel',...
  'multioption',      0,...
  'searchoption',     0,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.15 Brain Vision
defaults.import.datatypes(end+1) = struct(...
  'short',            'brainvision',...
  'long',             'BrainVision (.eeg)',...
  'ext',              'eeg',...
  'funct',            @pspm_get_brainvis,...
  'channeltypes',        {{defaults.channeltypes(~strcmpi('hb',{defaults.channeltypes.type})).type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.16 Dataq Windaq (e. g. provided by Coulbourn Instruments)
defaults.import.datatypes(end+1) = struct(...
  'short',            'windaq',...
  'long',             'DATAQ Windaq (.wdq) (read with ActiveX-Lib)',...
  'ext',              'wdq',...
  'funct',            @pspm_get_wdq,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.17 Dataq Windaq (PsPM Version)
defaults.import.datatypes(end+1) = struct(...
  'short',            'windaq_n',...
  'long',             'DATAQ Windaq (.wdq)',...
  'ext',              'wdq',...
  'funct',            @pspm_get_wdq_n,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.18 Noldus Observer XT compatible .txt files
defaults.import.datatypes(end+1) = struct(...
  'short',            'observer',...
  'long',             'Noldus Observer XT compatible text file',...
  'ext',              'any',...
  'funct',            @pspm_get_obs,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.19 NeuroScan
defaults.import.datatypes(end+1) = struct(...
  'short',            'cnt',...
  'long',             'Neuroscan (.cnt)',...
  'ext',              'cnt',...
  'funct',            @pspm_get_cnt,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.20 BioSemi
defaults.import.datatypes(end+1) = struct(...
  'short',            'biosemi',...
  'long',             'BioSemi (.bdf)',...
  'ext',              'bdf',...
  'funct',            @pspm_get_biosemi,...
  'channeltypes',        {{defaults.importchanneltypes(~strcmpi('hb',{defaults.importchanneltypes.type})).type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.21 Eyelink 1000 files
defaults.import.datatypes(end+1) = struct(...
  'short',            'eyelink',...
  'long',             'Eyelink 1000 (.asc)',...
  'ext',              'asc',...
  'funct',            @pspm_get_eyelink,...
  'channeltypes',        {{'pupil_l','pupil_r', 'gaze_x_l', 'gaze_y_l',...
  'gaze_x_r', 'gaze_y_r', 'blink_l', 'blink_r',...
  'saccade_l', 'saccade_r', 'marker', 'custom'}},...
  'chandescription',  'data column',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.22 European Data Format (EDF)
defaults.import.datatypes(end+1) = struct(...
  'short',            'edf',...
  'long',             'European Data Format (.edf)',...
  'ext',              'edf',...
  'funct',            @pspm_get_edf,...
  'channeltypes',        {{defaults.importchanneltypes.type}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     1,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.23 Philips Scanphyslog (.log)
defaults.import.datatypes(end+1) = struct(...
  'short',            'physlog',...
  'long',             'Philips Scanphyslog (.log)',...
  'ext',              'log',...
  'funct',            @pspm_get_physlog,...
  'channeltypes',        {{'ecg', 'ppg', 'resp', 'custom', 'marker'}},...
  'chandescription',  'channel',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       0,...
  'autosr',           1);
%
% 4.24 ViewPoint EyeTracker files
defaults.import.datatypes(end+1) = struct(...
  'short',            'viewpoint',...
  'long',             'ViewPoint EyeTracker (.txt)',...
  'ext',              'txt',...
  'funct',            @pspm_get_viewpoint,...
  'channeltypes',        {{'pupil_l','pupil_r', 'gaze_x_l', 'gaze_y_l', 'gaze_x_r', 'gaze_y_r', 'blink_l', 'blink_r', 'saccade_l', 'saccade_r', 'marker', 'custom'}},...
  'chandescription',  'data column',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       1,...
  'autosr',           1);
%
% 4.25 SMI EyeTracker files
defaults.import.datatypes(end+1) = struct(...
  'short',            'smi',...
  'long',             'SensoMotoric Instruments iView X EyeTracker (.txt)',...
  'ext',              'txt',...
  'funct',            @pspm_get_smi,...
  'channeltypes', {{'pupil_l', 'pupil_r', 'gaze_x_l', 'gaze_y_l',...
  'gaze_x_r', 'gaze_y_r', 'blink_l', 'blink_r', 'saccade_l', 'saccade_r',...
  'marker', 'custom'}},...
  'chandescription',  'data column',...
  'multioption',      1,...
  'searchoption',     0,...
  'automarker',       1,...
  'autosr',           1);

% add help texts
for k = 1:numel(defaults.import.datatypes)
    defaults.import.datatypes(k).help = defaults.help.(func2str(defaults.import.datatypes(k).funct)).Description;
end

%% 5 Default channel name for channel type search
defaults.import.channames.scr       = {'scr', 'scl', 'gsr', 'eda'};
defaults.import.channames.hr        = {'rate', 'hr'};
defaults.import.channames.hb        = {'beat', 'hb'};
defaults.import.channames.ecg       = {'ecg', 'ekg'};
defaults.import.channames.hp        = {'hp'};
defaults.import.channames.resp      = {'resp', 'breath'};
defaults.import.channames.pupil     = {'pupil', 'eye', 'track'};
defaults.import.channames.ppg       = {'ppg'};
defaults.import.channames.marker    = {'trig', 'mark', 'event', 'scanner'};
defaults.import.channames.sound     = {'sound'};
defaults.import.channames.custom    = {'custom'};

% Various import settings
defaults.import.fileprefix = 'pspm_';

defaults.import.rsr = 1000;                % minimum resampling rate for pulse data import
defaults.import.sr = 100;                  % final sampling rate for pulse data import

defaults.import.mat.sr_threshold = 1; %maximum value of the field '.sr' to which data is recognized as timestamps

%% 6 Processing settings
defaults.split.max_sn = 10; % split sessions: assume maximum 10 sessions
defaults.split.min_break_ratio = 3; % split sessions: assume inter marker intervals 3 times longer for breaks

% Lateral setting
defaults.lateral.char.c = 'c';
defaults.lateral.char.l = 'l';
defaults.lateral.char.r = 'r';

defaults.lateral.cap.c = 'C';
defaults.lateral.cap.l = 'L';
defaults.lateral.cap.r = 'R';

defaults.lateral.full.c = 'combined';
defaults.lateral.full.l = 'left';
defaults.lateral.full.r = 'right';

% Observed eyes
defaults.eye.char.b = 'lr';
defaults.eye.char.l = 'l';
defaults.eye.char.r = 'r';

defaults.eye.cap.b = 'LR';
defaults.eye.cap.br = 'RL';
defaults.eye.cap.l = 'L';
defaults.eye.cap.r = 'R';

defaults.eyetracker_channels = {'pupil', 'sps', 'gaze_x', 'gaze_y', 'blink', ...
    'saccade', 'pupil_missing'};

% other settings
% resampling rate for automatic transfer function computation
defaults.get_transfer_sr = 100;

% default modalities
defaults.modalities = struct('glm', 'scr', 'sf', 'scr', 'dcm', 'scr', 'tam', 'pupil');

%% 7 modality-specific GLM settings
%
% DEVELOPERS NOTES
% In order to implement new modalities, add a field
% to defaults.glm. See first modality (SCR) for explanations.
%
% defaults.glm(1) = ...                                              % GLM for SCR
% struct('modality', 'scr',...                                  % modality name
% 'modelspec', 'scr',...                                        % model specification
% 'cbf', struct('fhandle', @pspm_bf_scrf, 'args', 1),...  % default basis function/set
% 'filter', struct('lpfreq', 5, 'lporder', 1,  ...        % default filter settings
% 'hpfreq', 0.05, 'hporder', 1, 'down', 10,...
% 'direction', 'uni'),...
% 'default', 1);
%
% GLM for SCR
defaults.glm(1) = struct(...
  'modality',     'scr',...
  'modelspec',    'scr',...
  'cbf',          struct('fhandle', @pspm_bf_scrf, 'args', 1),...
  'filter',       struct('lpfreq', 5,   'lporder', 1, 'hpfreq', 0.05,   'hporder', 1,   'down', 10,   'direction',  'uni'),...
  'default',      1);
% GLM for HP (evoked)
defaults.glm(end+1) = struct(...
  'modality',     'hp',...
  'modelspec',    'hp_e',...
  'cbf',          struct('fhandle', @pspm_bf_hprf_e, 'args', 1),...
  'filter',       struct('lpfreq', 2,   'lporder', 2, 'hpfreq', 0.01,   'hporder', 2,   'down', 10,   'direction',  'uni'),...
  'default',      0);
% GLM for HP (fear-conditioning)
defaults.glm(end+1) = struct(...
  'modality',     'hp',...
  'modelspec',    'hp_fc',...
  'cbf',          struct('fhandle', @pspm_bf_hprf_fc, 'args', 1),...
  'filter',       struct('lpfreq', 0.5, 'lporder', 4, 'hpfreq', 0.015,  'hporder', 4,   'down', 10,   'direction',  'bi'),...
  'default',      0);
% GLM for HP (reward-conditioning)
defaults.glm(end + 1) = struct(...
    'modality',    'hp', ...
    'modelspec',   'hp_rew', ...
    'cbf',          struct('fhandle', @bf_hprf_rew, 'args', []), ...
    'filter',       struct('lpfreq', 0.5, 'lporder', 4,  'hpfreq', 0.015, 'hporder', 4, 'down', 10,   'direction', 'bi'), ...
    'default', 0);
% GLM for PS (fear-conditioning)
defaults.glm(end+1) = struct(...
  'modality',     'pupil',...
  'modelspec',    'ps_fc',...
  'cbf',          struct('fhandle', @pspm_bf_psrf_fc, 'args', []),...
  'filter',       struct('lpfreq', 50,  'lporder', 1, 'hpfreq', NaN,    'hporder', NaN, 'down', 100,  'direction',  'bi'),...
  'default',      0);
% GLM for RA (evoked)
defaults.glm(end+1) = struct(...
  'modality',     'ra',...
  'modelspec',    'ra_e',...
  'cbf',          struct('fhandle', @pspm_bf_rarf_e, 'args', 1),...
  'filter',       struct('lpfreq', 1,   'lporder', 1, 'hpfreq', 0.001,  'hporder', 1,   'down', 10,   'direction',  'uni'),...
  'default',      0);
% GLM for RA (fear-conditioning)
defaults.glm(end+1) = struct(...
  'modality',     'ra',...
  'modelspec',    'ra_fc',...
  'cbf',          struct('fhandle', @pspm_bf_rarf_fc, 'args', 1),...
  'filter',       struct('lpfreq', 2,   'lporder', 6, 'hpfreq', 0.01,   'hporder', 6,   'down', 10,   'direction',  'bi'),...
  'default',      0);
% GLM for RP (evoked)
defaults.glm(end+1) = struct(...
  'modality',     'rp',...
  'modelspec',    'rp_e',...
  'cbf',          struct('fhandle', @pspm_bf_rprf_e, 'args', 0),...
  'filter',       struct('lpfreq', 1,   'lporder', 1, 'hpfreq', 0.01,   'hporder', 1,   'down', 10,   'direction',  'uni'),...
  'default',      0);
% GLM for RFR (evoked)
defaults.glm(end+1) = struct(...
  'modality',     'rfr',...
  'modelspec',    'rfr_e',...
  'cbf',          struct('fhandle', @pspm_bf_rfrrf_e, 'args', 1),...
  'filter',       struct('lpfreq', 1,   'lporder', 1, 'hpfreq', 0.001,  'hporder', 1,   'down', 10,   'direction',  'uni'),...
  'default',      0);
% GLM for SEBR (fear-conditioning)
defaults.glm(end+1) = struct(...
  'modality',     'emg_pp',...
  'modelspec',    'sebr',...
  'cbf',          struct('fhandle', @pspm_bf_sebrf, 'args', 0),...
  'filter',       struct('lpfreq', NaN, 'lporder', NaN,  'hpfreq', NaN, 'hporder', NaN, 'down', 1000, 'direction',  'uni'),...
  'default',      1);
% GLM for Scanpath-speed
defaults.glm(end+1) = struct(...
  'modality',     'sps',...
  'modelspec',    'sps',...
  'cbf',          struct('fhandle', @pspm_bf_spsrf_box, 'args', 1),...
  'filter',       struct('lpfreq', NaN, 'lporder', NaN,  'hpfreq', NaN, 'hporder', NaN, 'down', 1000, 'direction',  'uni'),...
  'default',      1);

%% 7 DCM settings
%
% DEVELOPERS NOTES
% Currently this is being used for DCM for SCR and SF
% analysis. Further modalities and models can be implemented.
%
% DCM for SCR filter settings
defaults.dcm{1} = struct('filter', struct('lpfreq', 5,  'lporder',  1,  'hpfreq', 0.0159, 'hporder',  1,  'down', 10, 'direction', 'bi'), 'sigma_offset', 0.3);
% DCM for SF filter settings
defaults.dcm{2} = struct('filter', struct('lpfreq', 5,  'lporder',  1,  'hpfreq', 0.0159, 'hporder',  1,  'down', 10, 'direction', 'uni'));
%% 8 TAM settings
%
% DEVELOPERS NOTES
% Currently this is being used for TAM for pupil data.
% Further modalities and models can be implemented.
%
defaults.tam(1) = struct( ...
  'modality', 'pupil', ...
  'modelspec', 'dilation',...                                                       % modality name
  'cbf', struct('fhandle', @pspm_bf_ldrf_gm, 'args', [0.2, 2.40 , 0.29 , 0.77]),...  % basis function & default parameters
  'cif', struct('fhandle', @pspm_bf_ldrf_gm, 'args', [0, 2.76 , 0.09 , 0.31],...     % input function & default parameters
  'lb', [0,0,0,0], 'ub', [0,Inf,Inf,Inf]),...                          % & the lower/upper bounds
  'filter', struct('lpfreq', 'none', 'lporder', 0,  ...                               % default filter
  'hpfreq', 'none', 'hporder', 0, 'down', 0, 'direction', 'bi'));
defaults.tam(2) = struct(...
  'modality',  'pupil', ...
  'modelspec', 'constriction',...
  'cbf', struct('fhandle', @pspm_bf_lcrf_gm, 'args', [0.2, 3.24 , 0.18 , 0.43]),...
  'cif', struct('fhandle', @pspm_bf_lcrf_gm, 'args', [0, 2.76 , 0.09 , 0.31], 'lb', [0,0,0,0], 'ub', [0,Inf,Inf,Inf]),...
  'filter', struct('lpfreq', 'none', 'lporder', 0, 'hpfreq', 'none', 'hporder', 0, 'down', 0, 'direction', 'bi'));
%% 9 FIRST LEVEL settings
% 9.1 allowed first level model types
defaults.first = {'glm', 'sf', 'dcm', 'tam'};
%% 10 UI settings
% 10.1 Parameters for UI optimisation
if ispc
  defaults.ui = struct(...
    'DisplayHeight',    250/5,...
    'DisplayUnit',      'points',...
    'DisplayWeight',    250,...
    'FontNameEmph',     'Segoe UI Bold',...
    'FontNameText',     'Segoe UI',...
    'FontSizeAttr',     9,...
    'FontSizeCaption',  9,...
    'FontSizeText',     10,...
    'FontSizeTitle',    11,...
    'MainHeight',       500*0.8,...
    'MainWeight',       500,...
    'OperatingSystem',  'Windows',...
    'SwitchResize',     'off');
elseif ismac
  defaults.ui = struct('OperatingSystem','Mac',...
    'DisplayHeight',    60,...
    'DisplayUnit',      'points',...
    'DisplayWeight',    190,...
    'FontNameEmph',     'Gill Sans',...
    'FontNameText',     'Helvetica Neue',...
    'FontSizeAttr',     13,...
    'FontSizeCaption',  12,...
    'FontSizeText',     14,...
    'FontSizeTitle',    16,...
    'MainHeight',       750*0.8,...
    'MainWeight',       750,...
    'SwitchResize',     'off');
else
  defaults.ui = struct('OperatingSystem','Linux',...
    'DisplayHeight',    60,...
    'DisplayUnit',      'points',...
    'DisplayWeight',    190,...
    'FontNameEmph',     'Verdana Bold',...
    'FontNameText',     'Verdana',...
    'FontSizeAttr',     10,...
    'FontSizeCaption',  9,...
    'FontSizeText',     10,...
    'FontSizeTitle',    11,...
    'MainHeight',       650*0.8,...
    'MainWeight',       650,...
    'SwitchResize',     'on');
end
%% 11 Finalisation
% 11.1 Look for settings, otherwise set defaults --
if exist([pspm_root, 'pspm_settings.mat'], 'file')
  load([pspm_root, 'pspm_settings.mat']);
else
  settings = defaults;
end

% 11.2 Save variables --
settings.added_paths      = added_paths;
settings.removed_paths    = removed_paths;

settings.developmode      = 0;
settings.handle           = 'on'; % the options are 'on', 'off' and 'callback'
settings.initial_paths    = initial_paths;
settings.path             = pspm_root;
settings.pspm_version     = pspm_vers;
settings.signal           = signal;





