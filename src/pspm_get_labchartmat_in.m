function [sts, import, sourceinfo] = pspm_get_labchartmat_in(datafile, import)
% ● Description
%   pspm_get_labchartmat_in imports exported ADInstruments LabChart files
%   from version 7.1 or lower. These must be exported to matlab using 
%   the built-in export feature. For the LabChart extension for version 7.2 
%   and higher, see pspm_labchartmat_ext.
%   This function is partly based on sample files rather than 
%   manufacturer's documentation. Always check your imported data before 
%   using it. 
% ● Format
%   [sts, import, sourceinfo] = pspm_get_labchartmat_in(datafile, import);
% ● Arguments
%   *   datafile : datafile.
%   *     import : import.
% ● Outputs
%   *        sts : status.
%   *     import : the import structure.
%   * sourceinfo : the source information structure.
% ● Developer
%   * NOTE
%     This info is inherited from the old labchart export code but I
%     assume it's still valid
%   * Tue Jun 08, 2010 12:25 am from
%     http://www.adinstruments.com/forum/viewtopic.php?f=7&t=35&p=79#p79
%     Export MATLAB writes the comment timestamps using the overall `tick rate`.
%     The tick rate corresponds to the highest sample rate. If all channels are
%     at the same sample rate then that's the tick rate. However if you had
%     three channels recorded at 1kHz, 2kHz and 500Hz, then the tick rate would
%     be 2kHz and the comment positions would be at 2kHz ticks.
%     John Enlow, Windows Development Manager, ADInstruments, New Zealand
%   * NOTE
%     apparently (according to sample files provided by Jessica Golle, U Bern,
%     when multiple blocks are recorded, markers are counted wrt intra-block
%     time (26.06.2013)
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
sourceinfo = [];

% load & check data
% -------------------------------------------------------------------------
labchart = load(datafile);
blkno = numel(labchart.blocktimes);

% extract invidual channels
% -------------------------------------------------------------------------
% prepare import jobs ---
oldimport = import;
clear import

% loop through data blocks ---
for blk = 1:blkno
  import{blk} = oldimport;
  % loop through import jobs ---
  for k = 1:numel(import{blk})

    if strcmpi(import{blk}{k}.type, 'marker')
      import{blk}{k}.sr = 1./labchart.tickrate(blk);
      import{blk}{k}.marker = 'timestamps';
      markerindex = labchart.com(:, 2) == blk;
      markertype = cellstr(labchart.comtext);
      import{blk}{k}.data = labchart.com(markerindex, 3);
      import{blk}{k}.markerinfo.name = markertype(labchart.com(markerindex, 5));
      import{blk}{k}.markerinfo.value = labchart.com(markerindex, 5);
      sourceinfo{blk}.channel{k, 1} = sprintf('Channel %02.0f: %s', k, 'Events');
    else
      % define channel number ---
      if import{blk}{k}.channel > 0
        channel = import{blk}{k}.channel;
      else
        channel = pspm_find_channel(cellstr(labchart.titles), import{blk}{k}.type);
        if channel < 1, return; end;
      end;

      if channel > numel(cellstr(labchart.titles)), warning('ID:channel_not_contained_in_file', 'Channel %02.0f not contained in file %s.\n', channel, datafile); return; end;

      sourceinfo{blk}.channel{k, 1} = sprintf('Channel %02.0f: %s', channel, labchart.titles(channel, :));

      % get data (a simple vector)
      import{blk}{k}.data = [zeros(1, labchart.firstsampleoffset(channel, blk)), ...
        labchart.data(labchart.datastart(channel, blk):labchart.dataend(channel, blk))];
      % get sample rate
      import{blk}{k}.sr = labchart.samplerate(channel, blk);
    end;
  end;
end;

sts = 1;
return
