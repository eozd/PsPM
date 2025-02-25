function [sts, import, sourceinfo] = pspm_get_physlog(datafile, import)
% ● Description
%   pspm_get_physlog imports Philips Scanphyslog data, generated from the 
%   monitoring equipment of Philips MRI scanners. The physlog ascii file 
%   contains 6 channels with physiological measurements (Channel id 1-6): 
%   ECG1, ECG2, ECG3, ECG4, Pulse oxymeter, Respiration. Depending on the 
%   scanner settings, there are 10 marker channels of which channel 6 marks 
%   time t of the last slice recording. In order to align the data to start
%   and end of EPI sequences, a time window from t minus (#volumes )*
%   (repetition time) seconds until t should be used for trimming. 
%   Available marker channels are (Channel id 1-10): ECG marker, PPG marker, 
%   respiration marker, Measurement (?slice onset?), Start of scan sequence, 
%   End of scan sequence, Trigger external, Calibration, Manual start, 
%   Reference ECG Trigger.
% ● Developer
%   Special about this function is that channel numbers for event/marker
%   channels correspond to the different event types scanphyslog files.
%   * Possible event types are:
%  Channel-Nr:   Type:
%     --------   -----
%           1    Trigger ECG
%           2    Trigger PPG
%           3    Trigger Respiration
%           4    Measurement ('slice onset')
%           5    start of scan sequence
%           6    end of scan sequence
%           7    Trigger external
%           8    Calibration
%           9    Manual start
%          10    Reference ECG Trigger
%   * Channel types are:
%      Channel number:   Type:
%             --------   -----
%                  1-4   ECG channel
%                    5   PPG channel
%                    6   Resp channel
% ● Format
%   [sts, import, sourceinfo] = pspm_get_physlog(datafile, import);
% ● Arguments
%   *   datafile : datafile to be imported.
%   *     import : import settings.
% ● Outputs
%   *        sts : status.
%   *     import : the updated import structure.
%   * sourceinfo : the source information structure.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2008-2015 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
% add specific import path for specific import function
addpath(pspm_path('Import','physlog'));

% load data with specific function
% -------------------------------------------------------------------------
[bsts, out] = import_physlog(datafile);
if bsts ~= 1
  warning('ID:invalid_input', 'Physlog import was not successfull');
  return;
end

% iterate through data and fill up channel list as specified in import
% -------------------------------------------------------------------------
for k = 1:numel(import)
  if strcmpi(import{k}.type, 'marker')
    channel = import{k}.channel;
    if channel > size(out.trigger.t, 2), warning('ID:channel_not_contained_in_file', 'Column %02.0f not contained in file %s.\n', channel, datafile); return; end
    import{k}.marker = 'continuous';
    import{k}.sr     = out.trigger.sr;
    import{k}.data   = out.trigger.t{:,channel};
  else
    channel = import{k}.channel;
    if channel > size(out.data, 1), warning('ID:channel_not_contained_in_file', 'Column %02.0f not contained in file %s.\n', channel, datafile); return; end
    import{k}.sr = out.data{channel,1}.header.sr;
    import{k}.data = out.data{channel,1}.data;
    import{k}.units = out.data{channel,1}.header.units;
    sourceinfo.channel{k, 1} = sprintf('Column %02.0f', channel);
  end
end

% extract record time and date
sourceinfo.date = out.record_date;
sourceinfo.time = out.record_time;

% remove specific import path
rmpath(pspm_path('Import','physlog'));

sts = 1;
return
