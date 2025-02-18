function [sts, data] = pspm_get_marker(import)
% ● Description
%   pspm_get_marker gets the marker channel for different data types
% ● Format
%   [sts, data] = pspm_get_marker(import)
% ● Arguments
%   ┌─────import
%   ├──────.data: mandatory
%   ├────.marker: mandatory, string
%   │             accepted values: 'timestamps' or 'continuous'
%   ├────────.sr: mandatory, double
%   │             timestamps: timeunits in seconds
%   │             continuous: sample rate in 1/seconds)
%   ├────.flank : [optional, string] Only used for importing continuous
%   │             event channels. This specifies which flank of the event 
%   │             marker to use. 'both' (default, specifies the event at 
%   │             the middle between the ascending and descending flank), 
%   │             'ascending', 'descending',  'all' (imports ascending and 
%   │             descending flank as separate events).
%   └.markerinfo: optional, struct, returns marker timestamps in seconds.
%                 It has two fields, name and value.
% ● History
%   Introduced in PsPM version.
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% initialise
global settings;
if isempty(settings)
  pspm_init;
end
sts = -1;

%% get data
[bsts, import] = pspm_get_events(import);
if bsts ~= 1
  warning('ID:invalid_input', 'Call of pspm_get_events failed');
  return
end
data.data = import.data;

% add marker info
if isfield(import, 'markerinfo')
  data.markerinfo = import.markerinfo;
end

%% add header
data.header.chantype = 'marker';
data.header.units = 'events';
data.header.sr = 1;
sts = 1;
return
