function options = pspm_options(options, FunName)
% ● Definition
%   pspm_options automatically determine the fields of options for the
%   corresponding function.
% ● Arguments
%   options:  a struct to be filled by the function
%   FunName:  a string, the name of the function where option is used
% ● History
%   Introduced in PsPM 6.1
%   Written in 2022 by Teddy
%   Updated in 2024 by Dominik R Bach (Uni Bonn)
%   Updated in 2024 by Bernhard Agoué von Raußendorf

%% 0 Initialise
global settings
if isempty(settings)
  pspm_init;
end
if ~isstruct(options)
  warning('ID:invalid_input', 'Options must be a struct.');
  options = struct();
  options.invalid = 1;
  return
else
  if isempty(options) && ~isempty(fieldnames(options))
    warning('ID:invalid_input', 'options has fields with unspecified values.');
    options = struct();
    options.invalid = 1;
    return
  end
end
options.invalid = 0;
%% 1 Text
text_optional_channel_invalid = ...
  'options.channel must contain valid channel types or positive integers.';
text_optional_channel_invalid_char = ...
  'options.channel is not a valid channel type.';
%% 2 Main Processing

% deal with global settings
if (isfield(options, 'marker_chan_num') && ...
        numel(options.marker_chan_num) == 1 && ...
        options.marker_chan_num == 0)
    options.marker_chan_num = 'marker';
end

% deal with function-specific settings
switch FunName
  case 'blink_saccade_filt'
    % 2.1 pspm_blink_saccade_filt --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                0,          '*Int*Char*Cell'  );
  case 'con1'
    % 2.4 pspm_con1 --
    options = autofill(options, 'zscored',                0,          1                 );
  case 'con2'
    % 2.5 pspm_con2 --
    options = autofill_channel_action(options);
  case 'convert_area2diameter'
    % 2.6 pspm_convert_area2diameter --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'both',      '*Int*Char'       );
  case 'convert_au2unit'
    % 2.7 pspm_convert_au2unit --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'both',      '*Int*Char'       );
  case 'convert_ecg2hb'
    % 2.8 pspm_convert_ecg2hb --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'ecg',      '*Int*Char'       );
    options = autofill(options, 'debugmode',              0,          1                 );
    % can be merged into development mode?
    options = autofill(options, 'maxHR',                  200,        '>', 20           );
    % field: maxHR (bpm)
    options = autofill(options, 'minHR',                  20,         '<', 200          );
    % field: minHR (bpm)
    options = autofill(options, 'outfact',                2,          '*Num'            );
    options = autofill(options, 'semi',                   0,          1                 );
    % semi==1 will pop a dialog
    options = autofill(options, 'twthresh',               0.36,       '*Num'            );
    options = check_range(options, 'minHR', 'maxHR');
  case 'convert_ecg2hb_amri'
    % 2.9 pspm_convert_ecg2hb_amri --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'ecg',      '*Int*Char'       );
    options = autofill(options, 'ecg_bandpass',           [0.5,40],   '>', 0            );
    options = autofill(options, 'hrrange',                [20,200],   '>', 0            );
    options = autofill(options, 'min_cross_corr',         0.5,        '*Num'            );
    options = autofill(options, 'min_relative_amplitude', 0.4,        '*Num'            );
    options = autofill(options, 'signal_to_use',          'auto',     {'ecg', 'teo'}    );
    options = autofill(options, 'teo_bandpass',           [8,40],     '>', 0            );
    options = autofill(options, 'teo_order',              1,          '>', 0            );
  case 'convert_gaze'
    % 2.10 pspm_convert_gaze --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'gaze',      '*Int*Char*Cell'  ); % this function operates on pairs of channels; hence cell is exceptionally allowed here
  case 'convert_hb2hp'
    % 2.11 pspm_convert_hb2hp --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'hb',      '*Int*Char'       );
    options = autofill(options, 'limit_lower',            0.2,        '>', 0            );
    options = autofill(options, 'limit_upper',            2,          '>', 0            );
    options = check_range(options, 'limit_lower', 'limit_upper');
  case 'convert_ppg2hb'
    % 2.13 pspm_convert_ppg2hb --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'ppg',     '*Int*Char'        );
    options = autofill(options, 'diagnostics',            0,          1                 );
    options = autofill(options, 'lsm',                    0,          [0,100-10^-10]    );
    options = autofill(options, 'method',                 'classic',  {'classic', 'heartpy'});
    options = autofill(options, 'python_path',            '',         '*Char'           );
    options = autofill(options, 'missing',                {},         '*Char*Num'       );
  case 'data_editor'
    % 2.15 pspm_data_editor --
    % output_file does not have a default value
    % epoch_file does not have a default value
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'dcm'
    % 2.16 pspm_dcm --
    options = autofill(options, 'aSCR_sigma_offset',      0.1,        '>=', 0           );
    % minimum dispersion (standard deviation) for flexible responses (second)
    options = autofill(options, 'crfupdate',              0,          '*Num'            );
    % update CRF priors to observed SCRF, or use pre-estimated priors
    options = autofill(options, 'crfupdate',              0,          1                 );
    options = autofill(options, 'depth',                  2,          '*Num'            );
    % no of trials to invert at the same time
    options = autofill(options, 'dispsmallwin',           0,          '*Num'            );
    options = autofill(options, 'dispwin',                1,          0                 );
    options = autofill(options, 'eventnames',            {},         '*Cell'           );
    % Cell array of names for individual events
    options = autofill(options, 'getrf',                  0,          1                 );
    % only estimate RF, do not do trial-wise DCM
    options = autofill(options, 'indrf',                  0,          1                 );
    % Estimate the response function from the data
    options = autofill(options, 'method',                 'dcm'                         );
    options = autofill(options, 'nosave',                 0,          1                 );
    % Don't save dcm structure (e.g. used by pspm_get_rf)
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'rf',                     0,          1                 );
    % Call an external file to provide response function (for use when this is previously
    % estimated by pspm_get_rf)
    options = autofill(options, 'sclpost',                5,          '>=', 0           );
    % scl-change-free window after last event (second)
    options = autofill(options, 'sclpre',                 2,          '>=', 0           );
    % scl-change-free window before first event (second)
    options = autofill(options, 'sffreq',                 0.5,        '>=', 0           );
    % maximum frequency of SF in ITIs (Hz)
    options = autofill(options, 'sfpost',                 5,          '>=', 0           );
    % sf-free window after last event (second)
    options = autofill(options, 'sfpre',                  2,          '>=', 0           );
    % sf-free window before first event (second)
    options = autofill(options, 'trlnames',               {},         '*Cell*Char'      );
    % Cell array of names for individual trials, is used for contrast manager only (e.g.
    % condition descriptions)
  case 'dcm_inv'
    % 2.17 pspm_dcm_inv --
    options = autofill(options, 'aSCR_sigma_offset',      0.1,        '*Num'            );
    % minimum dispersion (standard deviation) for flexible responses (second)
    options = autofill(options, 'crfupdate',              0,          '*Num'            );
    % update CRF priors to observed SCRF, or use pre-estimated priors, default to use pre-estimated priors
    options = autofill(options, 'crfupdate',              0,          1                 );
    options = autofill(options, 'depth',                  2,          '*Int'            );
    % no of trials to invert at the same time
    options = autofill(options, 'dispsmallwin',           0,          '*Num'            );
    options = autofill(options, 'dispwin',                1,          0                 );
    options = autofill(options, 'getrf',                  0,          1                 );
    % only estimate RF, do not do trial-wise DCM
    options = autofill(options, 'meanSCR',                0,          '*Num'            );
    % data to adjust the response amplitude priors to
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'sclpost',                2,          '>=', 0           );
    % scl-change-free window after last event (second)
    options = autofill(options, 'sclpre',                 2.5,        '>=', 0           );
    % scl-change-free window before first event, avoid overlap of last SCL change
    % with next trial (second)
    options = autofill(options, 'sffreq',                 0.5,        '>=', 0           );
    % maximum frequency of SF in ITIs (Hz)
    options = autofill(options, 'sfpost',                 5,          '>=', 0           );
    % sf-free window after last event (second)
    options = autofill(options, 'sfpre',                  2,          '>=', 0           );
    % sf-free window before first event (second)
    options = autofill(options, 'rf',                     0,          1                 );
    % use pre-specified RF, provided in file, or as 4-element vector in log parameter space
  case 'down'
    % 2.18 pspm_down --
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'ecg_editor'
    % 2.19 pspm_down
    options = autofill(options, 'factor',                 1,          '>', 0            );
    options = autofill(options, 'semi',                   0,          1                 );
    options = autofill(options, 'channel',                1,          '*Int*Char*Cell'  );
    options = autofill(options, 'artefact',               [],         '*Char'           );
  case 'emg_pp'
    % 2.20 pspm_emg_pp --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'emg',      '*Int*Char'       );
    options = autofill(options, 'mains_freq',             50,         '>', 0            );
  case 'exp'
    % 2.21 pspm_exp --
    options = autofill(options, 'delim',                  '\t',       '*Char'           );
    options = autofill(options, 'exclude_missing',        0,          1                 );
    options = autofill(options, 'statstype',              'param',    {'cond', 'recon'} );
    options = autofill(options, 'target',                 'screen',   '*Char'           );
  case 'extract_segments'
    % 2.22 pspm_extract_segments --
    options = autofill(options, 'length',                 10,         '>', 0            );
    options = autofill(options, 'norm',                   0,          1                 );
    options = autofill(options, 'outputfile',             '',         '*Char'           );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'plot',                   0,          1                 );
    options = autofill(options, 'timeunits',              'seconds',  {'seconds', ...
                                                                      'samples',...
                                                                      'markers'}        );
    options = autofill(options, 'marker_chan_num',        'marker',   '*Num*Char'       );
    options = fill_extract_segments(options);
  case 'find_sounds'
    % 2.23 pspm_find_sounds --
    options = autofill_channel_action(options,            'add',     {'replace'} );
    options = autofill(options, 'channel_output',         'all',      'corrected'       );
    options = autofill(options, 'diagnostics',            0,          1                 );
    options = autofill(options, 'expectedSoundCount',     0,          '*Int'            );
    options = autofill(options, 'maxdelay',               3,          '>=',  0          );
    options = autofill(options, 'mindelay',               0,          '>=',  0          );
    options = autofill(options, 'plot',                   0,          1                 );
    options = autofill(options, 'resample',               1,          '*Int'            );
    options = autofill(options, 'snd_in_snd',             0,          1                 );
    options = autofill(options, 'channel',                'snd',      '*Int*Char'       );
    options = autofill(options, 'threshold',              0.1,        '>=',  0          );
    options = autofill(options, 'marker_chan_num',        'marker',   '*Int*Char'       );
    options = fill_find_sounds(options);
  case 'find_valid_fixations'
    % 2.24 pspm_find_valid_fixations --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'pupil',    '*Int*Char'       );
    options = autofill(options, 'add_invalid',            0,          1                 );
    options = autofill(options, 'plot_gaze_coords',       0,          1                 );
    options = fill_find_valid_fixations(options);
  case 'gaze_pp'
    % 2.25 pspm_gaze_pp --
    options = autofill(options, 'channel',                'gaze',      '*Int*Char'      );
    options = autofill_channel_action(options,            'add',      {'replace',...
                                                                      'none'}           );
  case 'get_markerinfo'
    % 2.26 pspm_get_markerinfo --
    options = autofill(options, 'filename',               '',         '*Char'           );
    options = autofill(options, 'marker_chan_num',        0,         '*Int'             );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'get_rf'
    % 2.27 pspm_get_rf --
    options = autofill(options, 'crfupdate',              0,          1                 );
    options = autofill(options, 'getrf',                  1                             );
    options = autofill(options, 'nosave',                 1,          0                 );
    options = autofill(options, 'indrf',                  0,          1                 );
    options = autofill(options, 'rf',                     0,          1                 );
    options = autofill(options, 'trlnames',               {},         '*Cell*Char'      );
  case 'glm'
    % 2.28 pspm_glm --
    options = autofill(options, 'norm',                   0,          1                 );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'marker_chan_num',        'marker',   '*Num*Char'       );
    if ~isfield(options, 'exclude_missing')
      options.exclude_missing = struct('segment_length',-1,'cutoff',0);
    else
      if ~isfield(options.exclude_missing, 'segment_length') || ...
          ~isfield(options.exclude_missing, 'cutoff')
        options.invalid = 1;
      end
    end
    options = fill_glm(options);
  case 'import'
    %% 2.29 pspm_import
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'interpolate'
    % 2.30 pspm_interpolate --
    options = autofill_channel_action(options);
    options = autofill(options, 'extrapolate',            0,          1                 );
    options = autofill(options, 'method',                 'linear',   {'cubic', ...
                                                                      'pchip',...
                                                                      'nearest', ...
                                                                      'spline', ...
                                                                      'previous', ...
                                                                      'next'}           );

    options = autofill(options, 'newfile',                0,          1                 );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'load1'
    % 2.31 pspm_load1 --
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'zscored',                0,          1                 );
  case 'merge'
    %% 2.32 pspm_merge
    options = autofill(options, 'marker_chan_num',        [0, 0],      '*Num*Char'      ); % NOTE: the default values will be converted to 'marker' by a subsequent call to pspm_trim
    if isnumeric(options.marker_chan_num)
        if ~all(size(options.marker_chan_num(:))==[2,1])
            options.invalid = 1;
            return
        end
    end
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'tam'
    % 2.33 pspm_tam --
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'pp'
    % 2.34 pspm_pp --
    options = autofill_channel_action(options);
  case 'prepdata'
    options = autofill(options, 'fillnan',                1,          0                 );
  case 'process_illuminance'
    % 2.35 pspm_process_illuminance --
    options = autofill(options, 'bf',                     struct(),   '*Struct'         );
    options = autofill(options, 'fn',                     '',         '*Char'           );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'transfer',               [49.79,...
                                                           -1.05,...
                                                           -0.50],    '*Num'            );
    options.bf = autofill(options.bf,   'constriction',   struct(),   '*Struct'         );
    options.bf = autofill(options.bf,   'dilation',       struct(),   '*Struct'         );
    options.bf = autofill(options.bf,   'duration',       20,         '>=',  0          );
    options.bf = autofill(options.bf,   'offset',         0.2,        '>=',  0          );
    options.bf.constriction = autofill(options.bf.constriction, 'fhandle', @pspm_bf_lcrf_gm);
    options.bf.dilation     = autofill(options.bf.dilation,     'fhandle', @pspm_bf_ldrf_gm);
  case 'pupil_correct_eyelink'
    % 2.36 pspm_pupil_correct_eyelink --
    options = autofill_channel_action(options);
    options = autofill(options, 'C_x',                    0,          '*Num'            );
    options = autofill(options, 'C_y',                    0,          '*Num'            );
    options = autofill(options, 'C_z',                    0,          '*Num'            );
    options = autofill(options, 'channel',                'pupil',    '*Int*Char'       );
    options = autofill(options, 'mode',                   'auto',     'manual'          );
    options = autofill(options, 'S_x',                    0,          '*Num'            );
    options = autofill(options, 'S_y',                    0,          '*Num'            );
    options = autofill(options, 'S_z',                    0,          '*Num'            );
    options = autofill(options, 'screen_size_mm',         [43.5,...
                                                           29.9],     '*Num'            );
    options = autofill(options, 'screen_size_px',         [1920,...
                                                           1080],     '*Num'            );
  case 'pupil_pp'
    % 2.37 pspm_pupil_pp --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'pupil',    '*Int*Char'       );
    options = autofill(options, 'channel_combine',        'none',     '*Int*Char'       );
    options = autofill(options, 'plot_data',              0,          1                 );
    options = autofill(options, 'segments',               {},         '*Cell'           );
    options = autofill(options, 'chan_valid_cutoff',      0.2,        '*Num'            );
  case 'python'
    options = autofill(options, 'python_path',            '',         '*Char'           );
  case 'remove_epochs'
    % 2.38 pspm_remove_epochs --
    options = autofill_channel_action(options);
    case 'rename'
    % pspm_ren
    options = autofill(options, 'overwrite',              2,          [0,1]             );
  case 'resp_pp'
    % 2.39 pspm_resp_pp --
    options = autofill_channel_action(options);
    options = autofill(options, 'channel',                'resp',    '*Int*Char'       );
    options = autofill(options, 'datatype',               {'rp', ...
                                                           'ra', ...
                                                           'rfr', ...
                                                           'rs', ...
                                                           'all'},    '*Subset'         );
    options = autofill(options, 'diagnostics',            0,          1                 );
    options = autofill(options, 'plot',                   0,          1                 );
    options = autofill(options, 'systemtype',             'bellows',  'cushion'         );
  case 'scr_pp'
    % 2.40 pspm_scr_pp --
    options = autofill_channel_action(options,            'add',      {'replace'}       );
    options = autofill(options, 'channel',                'scr',      '*Int*Char'       );
    options = autofill(options, 'baseline_jump',          1.5,        '>', 0            );
    options = autofill(options, 'clipping_window_size',   10000,      '*Int'            );
    options = autofill(options, 'clipping_step_size',     2,          '*Int'            );
    options = autofill(options, 'clipping_threshold',     0.1,        '*Num'            );
    options = autofill(options, 'data_island_threshold',  0,          '>=', 0           );
    options = autofill(options, 'deflection_threshold',   0.1,        '*Num'            );
    options = autofill(options, 'expand_epochs',          0.5,        '>=', 0           );
    options = autofill(options, 'include_baseline',       0,          1                 );
    options = autofill(options, 'max',                    60,         '>', 0            );
    options = autofill(options, 'min',                    0.05,       '>', 0            );
    options = autofill(options, 'missing_epochs_filename','',         '*Char'           );
    options = autofill(options, 'slope',                  10,         '*Num'            );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
if ~isempty(options.missing_epochs_filename)
       [pth, ~, ~] = fileparts(options.missing_epochs_filename);
       if ~isempty(pth) && exist(pth,'dir')~=7
         warning('ID:invalid_input',...
           'Please specify a valid output directory if you want to save missing epochs.');
         options.invalid = 1;
         return
       end
     end
  case 'segment_mean'
    % 2.41 pspm_segment_mean --
    options = autofill(options, 'adjust_method',          'none',     {'downsample', ...
                                                                      'interpolate'}    );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'newfile',                '',         '*Char'           );
    options = autofill(options, 'plot',                   0,          1                 );
  case 'sf'
    % 2.42 pspm_sf --
    options = autofill(options,'dispsmallwin',            0,          1                 );
    options = autofill(options,'dispwin',                 1,          0                 );
    options = autofill(options,'fresp',                   0.5,        '>=', 0           );
    options = autofill(options,'marker_chan_num',         'marker',   '*Int*Char'       );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options,'threshold',               0.1,        '>', 0            );
    options = autofill(options,'missingthresh',           2,          '>', 0            );
    options = autofill(options,'theta',                   [0.923581, ...
                                                          3.921034, ...
                                                          2.159389, ...
                                                          1.5339, ...
                                                          1.6411756741, ...
                                                          ],          '*Num'            );
  case 'sf_dcm'
    % 2.43 pspm_sf_dcm --
    options = autofill(options,'dispwin',                 1,          0                 );
    options = autofill(options,'dispsmallwin',            0,          1                 );
    options = autofill(options,'fresp',                   0.5,        '>', 0            );
    options = autofill(options,'threshold',               0.1,        '>', 0            );
    options = autofill(options,'theta',                   [0.923581, ...
                                                          3.921034, ...
                                                          2.159389, ...
                                                          1.5339, ...
                                                          1.6411756741, ...
                                                          ],          '*Num'            );
  case 'sf_mp'
    % 2.44 pspm_sf_mp --
    options = autofill(options,'diagnostics',             0,          1                 );
    options = autofill(options,'dispwin',                 0,          1                 );
    options = autofill(options,'threshold',               0.1,        '>', 0            );
    options = autofill(options,'fresp',                   0.5,        '>', 0            );
    options = autofill(options,'theta',                   [0.923581, ...
                                                          3.921034, ...
                                                          2.159389, ...
                                                          1.5339, ...
                                                          1.6411756741, ...
                                                          ],          '*Num'            );
  case 'split_sessions'
    % 2.45 pspm_split_sessions --
    options = autofill(options,'marker_chan_num',         'marker',   '*Int*Char'       );
    options = autofill(options, 'max_sn',                 settings.split.max_sn,...
                                                                      '>', 0            );
    % maximum number of sessions (default 10)
    options = autofill(options, 'min_break_ratio',        settings.split.min_break_ratio,...
                                                                      '>', 0            );
    % minimum ratio of session break to normal inter marker interval (default 3)
    options = autofill(options, 'missing',               [],          '*Char'           );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'prefix',                 0,          '<=', 0           );
    options = autofill(options, 'randomITI',              0,          1                 );
    options = autofill(options, 'splitpoints',           [],          '*Num'            );
    options = autofill(options, 'suffix',                 0,          '>=', 0           );
    options = autofill(options, 'verbose',                1,          0                 );
  case 'trim'
    % 2.46 pspm_trim --
    options = autofill(options, 'drop_offset_markers',    0,          '*Int'            );
    options = autofill(options, 'marker_chan_num',        'marker',   '*Int*Char'       );
    options = autofill(options, 'overwrite',              2,          [0,1]             );
    options = autofill(options, 'missing',               [],          '*Char'           );
  case 'write_channel'
    % 2.47 pspm_write_channel --
    options = autofill(options, 'channel',                0,          '*Int*Char'  );
    options = autofill(options, 'delete',                 'last',     {'first','all'}   );
    options = autofill(options, 'prefix',                '',          '*Char'           );
    if ~isfield('options','msg')
      options.msg = '';
    else
      if ~ischar(options.msg) && ~isstruct(options.msg)
        warning('ID:invalid_input', 'options.msg must be a char or a struct.');
        options.invalid = 1;
        return
      end
    end
    if ~isfield(options, 'channel')
      options.channel = 0;
    else
      switch class(options.channel)
        case 'char'
          if ~any(strcmpi(options.channel,{settings.channeltypes.type}))
            warning('ID:invalid_input', text_optional_channel_invalid_char);
            options.invalid = 1;
            return
          end
        case 'double'
          if (any(mod(options.channel, 1)) || any(options.channel<0))
            warning('ID:invalid_input', text_optional_channel_invalid);
            options.invalid = 1;
            return
          end
        otherwise
          warning('ID:invalid_input', text_optional_channel_invalid);
          options.invalid = 1;
          return
      end
    end
    case 'combine_markerchannels'
        % 2.48 pspm_combine_markerchannels
        options = autofill(options, 'marker_chan_num',        'marker',   '*Int*Char'       );
        options = autofill_channel_action(options);
    case 'expand_epochs'
        % 2.49 pspm_expand_epochs
        options = autofill(options, 'overwrite',              2,          [0,1]             );
        options = autofill_channel_action(options);
end
return

%% 3 Autofill
function options = autofill(varargin)
switch nargin
  case 3
    options = varargin{1};
    field_name = varargin{2};
    default_value = varargin{3};
    if ~isfield(options, field_name)
      options.(field_name) = default_value;
    else
      if ~strcmp(class(default_value),class(options.(field_name)))
        flag_is_allowed_value = 0;
      else
        switch class(default_value)
          case 'double'
            if isempty(default_value)
              flag_is_allowed_value = isempty(options.(field_name));
            else
              flag_is_allowed_value = any(options.(field_name) == default_value);
            end
          case 'char'
            flag_is_allowed_value = strcmp(options.(field_name), default_value);
          case 'cell'
            flag_is_allowed_value = isequal(options.(field_name), default_value);
          case 'function_handle'
            flag_is_allowed_value = isequal(options.(field_name), default_value);
        end
      end
      if ~flag_is_allowed_value
        allowed_values_message = generate_allowed_values_message(default_value);
        warning('ID:invalid_input', ['options.', field_name, ' is invalid. ',...
          allowed_values_message]);
        options.invalid = 1;
        return
      end
    end
  case 4
    options = varargin{1};
    field_name = varargin{2};
    default_value = varargin{3};
    optional_value = varargin{4};
    flag_is_allowed_value = 0;
    if ~isfield(options, field_name)
      options.(field_name) = default_value;
    else
%       if ~strcmp(class(default_value),class(options.(field_name)))
%         if (isnumeric(default_value) && islogical(options.(field_name))) || ...
%             (islogical(default_value) && isnumeric(options.(field_name)))
%           flag_is_allowed_value = 1;
%         else
%           flag_is_allowed_value = 0;
%         end
%       else
        switch class(optional_value)
          case 'double'
            if length(default_value) ~= length(options.(field_name))
              flag_is_allowed_value = 0;
            else
              allowed_value = [optional_value, default_value];
              truetable = options.(field_name) == allowed_value;
              flag_is_allowed_value = any(sum(truetable,2));
            end
          case 'char'
            if strcmp(optional_value, '*')
              flag_is_allowed_value = 1;
            elseif contains(optional_value, '*')
              if contains(optional_value, '*Char')
                flag_is_allowed_value = flag_is_allowed_value || ischar(options.(field_name));
              end
              if contains(optional_value, '*Num')
                flag_is_allowed_value = flag_is_allowed_value || isnumeric(options.(field_name));
              end
              if contains(optional_value, '*Cell')
                flag_is_allowed_value = flag_is_allowed_value || iscell(options.(field_name));
              end
              if contains(optional_value, '*Int')
                flag_is_allowed_value = flag_is_allowed_value || ...
                  all([isnumeric(options.(field_name)), ...
                  all(options.(field_name)>=0), ...
                  all(mod(options.(field_name), 1)==0)]);
              end
              if contains(optional_value, '*Struct')
                flag_is_allowed_value = flag_is_allowed_value || isstruct(options.(field_name));
              end
              if contains(optional_value, '*Subset')
                flag_is_allowed_value = ...
                  flag_is_allowed_value || prod(ismember(options.datatype,default_value),'all');
              end
            else
              allowed_value = {optional_value, default_value};
              flag_is_allowed_value = strcmp(options.(field_name), allowed_value);
            end
          case 'cell'
            allowed_value = optional_value;
            allowed_value{end+1} = default_value;
            switch class(optional_value{1})
              case 'char'
                flag_is_allowed_value = any(strcmp(options.(field_name), allowed_value));
              case 'function_handle'
                allowed_value_char = cellfun(@(x) {func2str(x)}, allowed_value);
                candidate_value_char = func2str(options.(field_name));
                flag_is_allowed_value = any(strcmp(candidate_value_char, allowed_value_char));
            end
        end
      if ~flag_is_allowed_value
        allowed_values_message = generate_allowed_values_message(default_value, optional_value);
        warning('ID:invalid_input', ['options.', field_name, ' has an invalid value. ',...
          allowed_values_message]);
        options.invalid = 1;
        return
      end
    end
  case 5
    options = varargin{1};
    field_name = varargin{2};
    default_value = varargin{3};
    range_marker = varargin{4};
    optional_value_boundary = varargin{5};
    if ~isfield(options, field_name)
      options.(field_name) = default_value;
    else
      if ~strcmp(class(default_value),class(options.(field_name)))
        flag_is_allowed_value = 0;
      else
        switch class(optional_value_boundary)
          case 'double'
            if length(default_value) ~= length(options.(field_name))
              flag_is_allowed_value = 0;
            else
              switch range_marker
                case '>' % larger than some value
                  flag_is_allowed_value = options.(field_name) > optional_value_boundary;
                case 'integer>' % integer larger than some value
                  flag_is_allowed_value = ...
                    (options.(field_name) > optional_value_boundary) &&...
                    (floor(options.(field_name))==options.(field_name));
                case '>='
                  flag_is_allowed_value = ...
                    options.(field_name) >= optional_value_boundary;
                case 'integer>='
                  flag_is_allowed_value = ...
                    (options.(field_name) >= optional_value_boundary) && ...
                    (floor(options.(field_name))==options.(field_name));
                case '<'
                  flag_is_allowed_value = options.(field_name) < optional_value_boundary;
                case 'integer<'
                  flag_is_allowed_value = ...
                    (options.(field_name) < optional_value_boundary) && ...
                    (floor(options.(field_name))==options.(field_name));
                case '<='
                  flag_is_allowed_value = ...
                    options.(field_name) <= optional_value_boundary;
                case 'integer<='
                  flag_is_allowed_value = ...
                    (options.(field_name) <= optional_value_boundary) && ...
                    (floor(options.(field_name))==options.(field_name));
                otherwise
                  warning('ID:invalid_input', 'range_marker must be <, >, <=, or >=.');
                  options.invalid = 1;
                  return
              end
            end
          otherwise
            warning('ID:invalid_input', ...
              'optional_value_boundary must be a double value for using ranges.');
            options.invalid = 1;
            return
        end
      end
      if ~flag_is_allowed_value
        allowed_values_message = generate_allowed_values_message(...
          default_value, optional_value_boundary, range_marker);
        warning('ID:invalid_input', ['options.', field_name, ' has an invalid value. ',...
          allowed_values_message]);
        options.invalid = 1;
        return
      end
    end
  otherwise
    warning('ID:invalid_input', 'autofill needs at least 3 arguments');
    options.invalid = 1;
    return
end

%% 4 Autofill channel action
function options = autofill_channel_action(options, varargin)
% Description: subfunction of pspm_options for autofill channel actions
% Usage: (1) use only the variable options if the default channel option is
% 'add' (2) use two variables and the latter as the default channel option
% other than 'add' (3) use three variables where the second is the default
% channel action and the third variable is the list of optional/acceptable
% channel actions.
% Written by Teddy in 2022.
switch nargin
  case 1
    default_value = 'add';
    optional_value = 'replace';
  case 2
    default_value = varargin{1};
    if strcmp(default_value, 'replace')
      optional_value = 'add';
    else
      optional_value = {'add', 'replace'};
    end
  case 3
    default_value = varargin{1};
    optional_value = varargin{2};
end
if ~isfield(options, 'channel_action')
  options.channel_action = default_value;
else
  acceptable_values = {};
  acceptable_values{1} = default_value;
  switch class(optional_value)
    case 'char'
      acceptable_values{2} = optional_value;
    case 'cell'
      acceptable_values(2:(length(optional_value)+1)) = optional_value;
  end
  acceptable_values = unique(acceptable_values);
  if ~any(strcmpi(options.channel_action, acceptable_values))
    allowed_values_message = generate_allowed_values_message(default_value, optional_value);
    warning('ID:invalid_input', ...
      ['''options.channel_action'' must have an accepted value. '...
      allowed_values_message]);
    options.invalid = 1;
    return
  end
end

function allowed_values_message = generate_allowed_values_message(varargin)
switch nargin
  case 1
    default_value = varargin{1};
    if isnumeric(default_value)
      default_value_message = num2str(default_value);
    elseif iscell(default_value) && isempty(default_value)
      default_value_message = '{}';
    else
      default_value_message = default_value;
    end
    allowed_values_message = ['The only allowed value is ', ...
      char(34), default_value_message, char(34), '.'];
  case 2
    default_value = varargin{1};
    optional_value = varargin{2};
    switch class(default_value)
      case 'double'
        default_value_converted = num2str(default_value);
      case 'char'
        default_value_converted = default_value;
      case 'cell'
        if isempty(default_value)
          default_value_converted = 'empty';
        else
          default_value_converted = default_value{1};
        end
    end
    default_value_message = [char(34), default_value_converted, char(34)];
    switch class(optional_value)
      case 'double'
        switch length(optional_value)
          case 1
            optional_value_message = [' and ', char(34), num2str(optional_value), char(34)];
          case 2
            optional_value_message = [', ', char(34), num2str(optional_value(1)), char(34), ...
              ', and ', char(34), num2str(optional_value(2)), char(34)];
          case 3
            optional_value_message = [', ', char(34), num2str(optional_value(1)), char(34), ...
              ', ', char(34), num2str(optional_value(2)), char(34), ...
              ', and ', char(34), num2str(optional_value(3)), char(34)];
        end
      case 'char'
        optional_value_message = [' and ', char(34), optional_value, char(34)];
      case 'cell'
        switch length(optional_value)
          case 1
            optional_value_message = [' and ', char(34), optional_value{1}, char(34)];
          case 2
            optional_value_message = [', ', char(34), optional_value{1}, char(34), ...
              ', and ', char(34), optional_value{2}, char(34)];
          case 3
            optional_value_message = [', ', char(34), optional_value{1}, char(34), ...
              ', ', char(34), optional_value{2}, char(34), ...
              ', and ', char(34), optional_value{3}, char(34)];
          case 4
            optional_value_message = [', ', char(34), optional_value{1}, char(34), ...
              ', ', char(34), optional_value{2}, char(34), ...
              ', ', char(34), optional_value{3}, char(34), ...
              ', and ', char(34), optional_value{4}, char(34)];
          case 5
            optional_value_message = [', ', char(34), optional_value{1}, char(34), ...
              ', ', char(34), optional_value{2}, char(34), ...
              ', ', char(34), optional_value{3}, char(34), ...
              ', ', char(34), optional_value{4}, char(34), ...
              ', and ', char(34), optional_value{5}, char(34)];
          case 6
            optional_value_message = [', ', char(34), optional_value{1}, char(34), ...
              ', ', char(34), optional_value{2}, char(34), ...
              ', ', char(34), optional_value{3}, char(34), ...
              ', ', char(34), optional_value{4}, char(34), ...
              ', ', char(34), optional_value{5}, char(34), ...
              ', and ', char(34), optional_value{6}, char(34)];
        end
    end
    allowed_values_message = ['The allowed values are ', ...
      default_value_message, ...
      optional_value_message, '.'];
  case 3
    default_value = varargin{1};
    optional_value_boundary = varargin{2};
    range_marker = varargin{3};
    switch range_marker
      case '<'
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be smaller than ',...
          num2str(optional_value_boundary), '.'];
      case '<='
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be smaller than or equal to ',...
          num2str(optional_value_boundary), '.'];
      case '>'
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be larger than ',...
          num2str(optional_value_boundary), '.'];
      case '>='
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be larger than or equal to ',...
          num2str(optional_value_boundary), '.'];
      case 'integer<'
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be an integer, also smaller than ',...
          num2str(optional_value_boundary), '.'];
      case 'integer<='
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be an integer, also smaller than or equal to ',...
          num2str(optional_value_boundary), '.'];
      case 'integer>'
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be an integer, also larger than ',...
          num2str(optional_value_boundary), '.'];
      case 'integer>='
        allowed_values_message = ['The default value is ', ...
          num2str(default_value), ...
          ', and the allowed values must be an integer, also larger than or equal to ',...
          num2str(optional_value_boundary), '.'];
      otherwise
        warning('ID:invalid_input', 'optional_value_boundary must be double');
        return
    end
end

function options = fill_extract_segments(options)
% 2.21.1 set default ouput_nan
if ~isfield(options, 'nan_output')|| strcmpi(options.nan_output, 'none')
  options.nan_output = 'none';
elseif ~strcmpi( options.nan_output,'screen')
  [path, ~, ~ ]= fileparts(options.nan_output);
  if 7 ~= exist(path, 'dir')
    warning('ID:invalid_input', 'Path for nan_output does not exist');
    options.invalid = 1;
    return
  end
end

function options = fill_find_valid_fixations(options)
if strcmpi(options.mode,'fixation') && ~isfield(options, 'resolution')
  options.resolution = [1 1];
end
if strcmpi(options.mode,'fixation') && ~isfield(options, 'fixation_point')
  options.fixation_point = [0.5 0.5];
end
if strcmpi(options.mode,'fixation') && isfield(options, 'fixation_point') && ...
    (~isnumeric(options.fixation_point) || ...
    size(options.fixation_point,2) ~= 2)
  warning('ID:invalid_input', ['Options.fixation_point is not ', ...
    'numeric, or has the wrong size (should be nx2).']);
  options.invalid = 1;
  return;
elseif isfield(options, 'resolution') && (~isnumeric(options.resolution) || ...
    ~all(size(options.resolution) == [1 2]))
  warning('ID:invalid_input', ['Options.fixation_point is not ', ...
    'numeric, or has the wrong size (should be 1x2).']);
  options.invalid = 1;
  return;
elseif strcmpi(options.mode,'fixation') && isfield(options, 'fixation_point') &&  ...
    ~all(options.fixation_point < options.resolution)
  warning('ID:out_of_range', ['Some fixation points are larger than ', ...
    'the range given. Ensure fixation points are within the given ', ...
    'resolution.']);
  options.invalid = 1;
  return;
end

function options = fill_glm(options)
if isfield(options, 'marker_chan_num')
  if isnumeric(options.marker_chan_num)
    if numel(options.marker_chan_num) ~= 1
      warning('ID:invalid_input', ...
        'If set as a number, options.marker_chan_num needs can only be a singular number.');
      options.invalid = 1;
      return
    end
  else
    if ~ischar(options.marker_chan_num)
      warning('ID:invalid_input', ...
        'options.marker_chan_num can only be a number or a character.');
      options.invalid = 1;
      return
    end
  end
end
if isfield(options,'exclude_missing')
  if ~(isfield(options.exclude_missing, 'segment_length') && ...
      isfield(options.exclude_missing,'cutoff'))
    warning('ID:invalid_input', 'To extract the NaN-values,  segment-length and cutoff must be set');
    options.invalid = 1;
    return
  elseif ~(isnumeric(options.exclude_missing.segment_length) && isnumeric(options.exclude_missing.cutoff))
    warning('ID:invalid_input', 'To extract the NaN-values, segment-length and cutoff must be numeric values.');
    options.invalid = 1;
    return
  end
end

function options = fill_find_sounds(options)
% options = autofill(options, 'roi', []);
if options.maxdelay < options.mindelay
  warning('ID:invalid_input', ...
    ['''options.mindelay'' and ''options.maxdelay'' ', ...
    'must be numeric and ''options.mindelay'' must be ', ...
    'smaller than ''options.maxdelay''']);
  options.invalid = 1;
end
if options.plot; options.diagnostics = true; end
try options.roi; catch, options.roi = []; end
if ~isempty(options.roi) && ...
    (length(options.roi) ~= 2 || ~all(isnumeric(options.roi) & options.roi >= 0))
  warning('ID:invalid_input', 'Option roi must be a float vector of length 2 or 0');
  options.invalid = 1;
end

function options = check_range(options, range_start, range_end)
if options.(range_start) > options.(range_end)
  warning('ID:invalid_input', ...
  ['options.', range_start, ' and options.', range_end, ...
  ' must be positive numeric.', ...
  'options.', range_start, ' must be ', ...
  'smaller than options.', range_end, '.']);
  options.invalid = 1;
end

