function [sts, import, sourceinfo]  = pspm_get_wdq_n(datafile, import)
% ● Description
%   pspm_get_wdq_n imports Dataq/Windaq files (e.g. used by Coulbourn
%   psychophysiology systems). This function does not use the ActiveX 
%   control elements provided by Dataq developers. Instead it reads the 
%   binary file according to the documentation published by dataq
%   (http://www.dataq.com/resources/techinfo/ff.htm). Up to now this 
%   function has been tested with files of the following type: Unpacked, 
%   no Hi-Res data, no Multiplexer files. A warning will be produced if the 
%   imported data type fits one of the yet untested cases. If this is the 
%   case we suggest you try using the import provided by the manufacturer 
%   (pspm_get_wdq, requiring Windows and Matlab 32-bit). 
% ● Format
%   [sts, import, sourceinfo] = pspm_get_wdq_n(datafile, import);
% ● Arguments
%   *   datafile : The data file to be imported.
%   *     import : The importing settings.
% ● Outputs
%   *     import : Struct that includes data obtained from wdq files.
%   * sourceinfo : Struct that includes source information
% ● Developer
%   This function does not use the ActiveX control elements provided by
%   Dataq developers. Instead it reads the binary file according to the
%   documentation published by dataq
%   (http://www.dataq.com/resources/techinfo/ff.htm).
%   The current called routine nReadDataq.m may not provide as many data
%   (check the commented header of the routine nReadDataq for more
%   information) as the ActiveX control elements do, but the function is
%   independent of cpu architecture. Which means it does not require a 32-bit
%   Matlab-Version.
% ● History
%   Introduced in PsPM 3.0
%   Written    in 2012-2015 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy

%% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
addpath(pspm_path('Import','nwdq'));

% get external file, using Dataq functions
% -------------------------------------------------------------------------
[inputinfo, inputdata] = nReadDataq(datafile);

% extract individual channels
% -------------------------------------------------------------------------
% loop through import jobs
for k = 1:numel(import)
  channel = import{k}.channel;
  if channel > size(inputdata, 2)
    warning('ID:channel_not_contained_in_file', 'Channel %1.0f does not exist in data file', channel); return;
  end
  import{k}.sr = inputinfo.sampleRatePerChannel; % sample rate per channel
  import{k}.data = inputdata{channel};     % data per channel
  import{k}.units = inputinfo.engineeringUnitsTag(channel, :);
  sourceinfo.channel{k, 1} = sprintf('Channel %02.0f', channel);
  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'events')
    import{k}.marker = 'continuous';
  end
end

% clear path and return
% -------------------------------------------------------------------------
rmpath(pspm_path('Import','nwdq'));
sts = 1;
return
