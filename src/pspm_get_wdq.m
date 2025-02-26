function [sts, import, sourceinfo] = pspm_get_wdq(datafile, import)
% ● Description
%   pspm_get_wdq imports Dataq/Windaq files (e.g. used by Coulbourn
%   psychophysiology systems). This function uses the conversion routine 
%   ReadDataq.m provided by Dataq developers and contained in the PsPM 
%   distribution. ActiveX control elements provided in the file activex.exe 
%   provided by Dataq must be installed, too. The ActiveX plugin only runs 
%   under 32 bit Matlab on Windows.
% ● Format
%   [sts, import, sourceinfo] = pspm_get_wdq(datafile, import);
% ● Arguments
%   *   datafile : The data file to be imported.
%   *     import : The importing settings.
% ● Outputs
%   *     import : Struct that includes data obtained from wdq files.
%   * sourceinfo : Struct that includes source information
% ● History
%   Introduced in PsPM 3.0
%   Written    in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];
addpath(pspm_path('Import','wdq'));

% get external file, using Dataq functions
% -------------------------------------------------------------------------
inputdata = ReadDataq(datafile);

% extract individual channels
% -------------------------------------------------------------------------
% loop through import jobs
for k = 1:numel(import)
  channel = import{k}.channel;
  if channel > size(inputdata.Data, 2)
    warning('Channel %1.0f does not exist in data file', channel); return;
  end
  import{k}.sr = inputdata.SR;            % sample rate per channel
  import{k}.data = inputdata.Data(:, channel);     % data per channel
  import{k}.units = inputdata.Units{channel};
  sourceinfo.channel{k, 1} = sprintf('Channel %02.0f', channel);
  if strcmpi(settings.channeltypes(import{k}.typeno).data, 'events')
    import{k}.marker = 'continuous';
  end
end

% clear path and return
% -------------------------------------------------------------------------
rmpath(pspm_path('Import','wdq'));
sts = 1;
return
