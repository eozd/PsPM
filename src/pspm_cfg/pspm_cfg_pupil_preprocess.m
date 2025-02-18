function [PupilPP] = pspm_cfg_pupil_preprocess(~)
% ● Description
%   Matlabbatch function for pspm_pupil_pp
% ● History
%   Written in 2019 by Eshref Yozdemir (University of Zurich)
%   Updated in 17-03-2024 by Teddy

%% Standard items
datafile         = pspm_cfg_selector_datafile;
Chan             = pspm_cfg_selector_channel('pupil');
ChanComb         = pspm_cfg_selector_channel('pupil_none');
channel_action   = pspm_cfg_selector_channel_action;

%% Specific items
Chan.name      = 'Primary channel to preprocess';
ChanComb.tag       = 'chan_comb';
ChanComb.name      = 'Secondary channel to preprocess';
ChanComb.help      = {ChanComb.help{1}, ' This can be left empty.'};

% valid channel cut-off
ChanCutoff        = cfg_entry;
ChanCutoff.name   = 'Cut-off';
ChanCutoff.tag    = 'chan_valid_cutoff';
ChanCutoff.num    = [1 1];
ChanCutoff.val    = {10};
ChanCutoff.help   = pspm_cfg_help_format('pspm_pupil_pp', 'options.chan_valid_cutoff');

%% Parameters
% Pupil diameter minimum
PupilDiameterMin      = cfg_entry;
PupilDiameterMin.name = 'Minimum allowed pupil diameter';
PupilDiameterMin.tag  = 'PupilDiameter_Min';
PupilDiameterMin.num  = [1 1];
PupilDiameterMin.val  = {1.5};
PupilDiameterMin.help = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.PupilDiameter_Min');

% Pupil diameter maximum
PupilDiameterMax      = cfg_entry;
PupilDiameterMax.name = 'Maximum allowed pupil diameter';
PupilDiameterMax.tag  = 'PupilDiameter_Max';
PupilDiameterMax.num  = [1 1];
PupilDiameterMax.val  = {9.0};
PupilDiameterMax.help = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.PupilDiameter_Max');

% Island filter separation
IslandFiltSeparation      = cfg_entry;
IslandFiltSeparation.name = 'Island separation min distance (ms)';
IslandFiltSeparation.tag  = 'islandFilter_islandSeparation_ms';
IslandFiltSeparation.num  = [1 1];
IslandFiltSeparation.val  = {40};
IslandFiltSeparation.help = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.islandFilter_islandSeperation_ms');

% Minimum valid island width in millisecond
IslandFiltMinWidth        = cfg_entry;
IslandFiltMinWidth.name   = 'Min valid island width (ms)';
IslandFiltMinWidth.tag    = 'islandFilter_minIslandwidth_ms';
IslandFiltMinWidth.num    = [1 1];
IslandFiltMinWidth.val    = {50};
IslandFiltMinWidth.help   = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.islandFilter_minIslandWidth_ms');

% Dilation speed filter median multiplier
DilationSpdFiltMedMp      = cfg_entry;
DilationSpdFiltMedMp.name = 'Number of medians in speed filter';
DilationSpdFiltMedMp.tag  = 'dilationSpeedFilter_MadMultiplier';
DilationSpdFiltMedMp.num  = [1 1];
DilationSpdFiltMedMp.val  = {16};
DilationSpdFiltMedMp.help = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.dilationSpeedFilter_MadMultiplier');

% Dilation speed filter maximum gap in millisecond
DilationSpdFiltMaxGap       = cfg_entry;
DilationSpdFiltMaxGap.name  = 'Max gap to compute speed (ms)';
DilationSpdFiltMaxGap.tag   = 'dilationSpeedFilter_maxGap_ms';
DilationSpdFiltMaxGap.num   = [1 1];
DilationSpdFiltMaxGap.val   = {200};
DilationSpdFiltMaxGap.help  = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.dilationSpeedFilter_maxGap_ms');

% Gap detect minimum width in millisecond
GapDetectMinWidth       = cfg_entry;
GapDetectMinWidth.name  = 'Min missing data width (ms)';
GapDetectMinWidth.tag   = 'gapDetect_minWidth';
GapDetectMinWidth.num   = [1 1];
GapDetectMinWidth.val   = {75};
GapDetectMinWidth.help  = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.gapDetect_minWidth');

% Gap detect maximum width in millisecond
GapDetectMaxWidth       = cfg_entry;
GapDetectMaxWidth.name  = 'Max missing data width (ms)';
GapDetectMaxWidth.tag   = 'gapDetect_maxWidth';
GapDetectMaxWidth.num   = [1 1];
GapDetectMaxWidth.val   = {2000};
GapDetectMaxWidth.help  = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.gapDetect_maxWidth');

% Gap padding backword
GapPaddingBwd           = cfg_entry;
GapPaddingBwd.name      = 'Reject before missing data (ms)';
GapPaddingBwd.tag       = 'gapPadding_backward';
GapPaddingBwd.num       = [1 1];
GapPaddingBwd.val       = {50};
GapPaddingBwd.help      = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.gapPadding_backward');

% Gap padding forward
GapPaddingFwd           = cfg_entry;
GapPaddingFwd.name      = 'Reject after missing data (ms)';
GapPaddingFwd.tag       = 'gapPadding_forward';
GapPaddingFwd.num       = [1 1];
GapPaddingFwd.val       = {50};
GapPaddingFwd.help      = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.gapPadding_forward');

% Residual filter passes
ResdFiltPass            = cfg_entry;
ResdFiltPass.name       = 'Deviation filter passes';
ResdFiltPass.tag        = 'residualsFilter_passes';
ResdFiltPass.num        = [1 1];
ResdFiltPass.val        = {4};
ResdFiltPass.help       = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.residualsFilter_passes');

% Residual filter median multiplier
ResdFiltMedMp           = cfg_entry;
ResdFiltMedMp.name      = 'Number of medians in deviation filter';
ResdFiltMedMp.tag       = 'residualsFilter_MadMultiplier';
ResdFiltMedMp.num       = [1 1];
ResdFiltMedMp.val       = {16};
ResdFiltMedMp.help      = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.residualsFilter_MadMultiplier');

% Residual filter interpolation sampling frequency
ResdFiltInterpFs        = cfg_entry;
ResdFiltInterpFs.name   = 'Butterworth sampling frequency (Hz)';
ResdFiltInterpFs.tag    = 'residualsFilter_interpFs';
ResdFiltInterpFs.num    = [1 1];
ResdFiltInterpFs.val    = {100};
ResdFiltInterpFs.help   = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.residualsFilter_interpFs');

% Residual filter for lowpass cut-off
ResdFiltLPCF            = cfg_entry;
ResdFiltLPCF.name       = 'Butterworth cutoff frequency (Hz)';
ResdFiltLPCF.tag        = 'residualsFilter_lowpassCF';
ResdFiltLPCF.num        = [1 1];
ResdFiltLPCF.val        = {16};% 
ResdFiltLPCF.help       = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.residualsFilter_lowpassCF');

% Keep filter data
KeepFiltData            = cfg_menu;
KeepFiltData.name       = 'Store intermediate steps';
KeepFiltData.tag        = 'keepFilterData';
KeepFiltData.values     = {true, false};
KeepFiltData.labels     = {'True', 'False'};
KeepFiltData.val        = {false};
KeepFiltData.help       = pspm_cfg_help_format('pspm_pupil_pp_options', 'raw.keepFilterData');

% Raw custom setting
RawCustomSet            = cfg_branch;
RawCustomSet.name       = 'Settings for raw data preprocessing';
RawCustomSet.tag        = 'raw';
RawCustomSet.val        = {PupilDiameterMin,...
                           PupilDiameterMax,...
                           IslandFiltSeparation,...
                           IslandFiltMinWidth,...
                           DilationSpdFiltMedMp,...
                           DilationSpdFiltMaxGap,...
                           GapDetectMinWidth,...
                           GapDetectMaxWidth,...
                           GapPaddingBwd,...
                           GapPaddingFwd,...
                           ResdFiltPass,...
                           ResdFiltMedMp,...
                           ResdFiltInterpFs,...
                           ResdFiltLPCF,...
                           KeepFiltData...
                          };
% Interpolation upsampling frequency
InterpUpSampFreq        = cfg_entry;
InterpUpSampFreq.name   = 'Interpolation upsampling frequency (Hz)';
InterpUpSampFreq.tag    = 'interp_upsamplingFreq';
InterpUpSampFreq.num    = [1 1];
InterpUpSampFreq.val    = {1000};
InterpUpSampFreq.help   = pspm_cfg_help_format('pspm_pupil_pp_options', 'valid.interp_maxGap');

% Low pass filter cutoff frequency in Hz
LPFiltCutoffFreq        = cfg_entry;
LPFiltCutoffFreq.name   = 'Lowpass filter cutoff frequency (Hz)';
LPFiltCutoffFreq.tag    = 'LpFilt_cutoffFreq';
LPFiltCutoffFreq.num    = [1 1];
LPFiltCutoffFreq.val    = {4};
LPFiltCutoffFreq.help   = pspm_cfg_help_format('pspm_pupil_pp_options', 'valid.interp_maxGap');

% Low pass filter order
LPFiltOrder             = cfg_entry;
LPFiltOrder.name        = 'Lowpass filter order';
LPFiltOrder.tag         = 'LpFilt_order';
LPFiltOrder.num         = [1 1];
LPFiltOrder.val         = {4};
LPFiltOrder.help        = pspm_cfg_help_format('pspm_pupil_pp_options', 'valid.interp_maxGap');


% Interpolation maximum gap in millisecond
InterpMaxGap            = cfg_entry;
InterpMaxGap.name       = 'Interpolation max gap (ms)';
InterpMaxGap.tag        = 'interp_maxGap';
InterpMaxGap.num        = [1 1];
InterpMaxGap.val        = {250};
InterpMaxGap.help       = pspm_cfg_help_format('pspm_pupil_pp_options', 'valid.interp_maxGap');

%% Settings
% Settings for valid data preprocessing
ValidCustomSet          = cfg_branch;
ValidCustomSet.name     = 'Settings for valid data preprocessing';
ValidCustomSet.tag      = 'valid';
ValidCustomSet.val      = {InterpUpSampFreq, ...
                           LPFiltCutoffFreq, ...
                           LPFiltOrder, ...
                           InterpMaxGap...
                          };
% Custom settings
CustomSet               = cfg_branch;
CustomSet.name          = 'Custom settings';
CustomSet.tag           = 'custom_settings';
CustomSet.val           = {RawCustomSet, ValidCustomSet};
% Default settings
DefaultSet              = cfg_const;
DefaultSet.name         = 'Default settings';
DefaultSet.tag          = 'default_settings';
DefaultSet.val          = {struct()};
% Settings
Set                     = cfg_choice;
Set.name                = 'Settings';
Set.tag                 = 'settings';
Set.values              = {DefaultSet, CustomSet};
Set.val                 = {DefaultSet};
Set.help                = {};
%% Segments
% Segement start in second
SegStart                = cfg_entry;
SegStart.name           = 'Segment start (seconds)';
SegStart.tag            = 'start';
SegStart.num            = [1 1];
SegStart.help           = {};
% Segment end in second
SegEnd                  = cfg_entry;
SegEnd.name             = 'Segment end (seconds)';
SegEnd.tag              = 'end';
SegEnd.num              = [1 1];
SegEnd.help             = {};
% Segment name
SegName                 = cfg_entry;
SegName.name            = 'Segment name';
SegName.strtype         = 's';
SegName.tag             = 'name';
SegName.help            = {};
% Segment
Seg                     = cfg_branch;
Seg.name                = 'Segment';
Seg.tag                 = 'segments';
Seg.val                 = {SegStart, SegEnd, SegName};
% Segment repeat
SegRep                  = cfg_repeat;
SegRep.name             = 'Segments';
SegRep.tag              = 'segments_rep';
SegRep.values           = {Seg};
SegRep.num              = [0 Inf];
SegRep.help             = pspm_cfg_help_format('pspm_pupil_pp', 'options.segments');

%% Plot data
PlotData                = cfg_menu;
PlotData.name           = 'Plot data';
PlotData.tag            = 'plot_data';
PlotData.values         = {true, false};
PlotData.labels         = {'True', 'False'};
PlotData.val            = {false};
PlotData.help           = pspm_cfg_help_format('pspm_pupil_pp', 'options.plot_data');
%% Executable branch
PupilPP                 = cfg_exbranch;
PupilPP.name            = 'Pupil preprocessing';
PupilPP.tag             = 'pupil_preprocess';
PupilPP.val             = {datafile, ...
                           Chan, ...
                           ChanComb, ...
                           ChanCutoff, ...
                           channel_action, ...
                           Set, ...
                           SegRep, ...
                           PlotData ...
                          };
PupilPP.prog            = @pspm_cfg_run_pupil_preprocess;
PupilPP.vout            = @pspm_cfg_vout_outchannel;
PupilPP.help            = pspm_cfg_help_format('pspm_pupil_pp');

