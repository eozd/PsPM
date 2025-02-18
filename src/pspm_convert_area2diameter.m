function [sts, outchannel] = pspm_convert_area2diameter(varargin)
% ● Description
%   pspm_convert_area2diameter converts area values into diameter values.
%   All pupil size models in PsPM are defined for diameter values and
%   require this conversion if the original data were recorded as area. In
%   user mode, the function works on one or two channels in a PsPM file. In 
%   internal mode, it can also act on numerical vectors and returns a 
%   vector of converted values. 
% ● Format
%   [sts, channel_index]  = pspm_convert_area2diameter(fn, options)
%   [sts, converted_data] = pspm_convert_area2diameter(area)
% ● Arguments
%   *            fn : a numeric vector of milimeter values
%   *          area : a numeric vector of area values (the unit is not important)
%   ┌───────options :
%   ├──────.channel : [optional][numeric/string] [Default: 'both']
%   │                 Channel ID to be preprocessed.
%   │                 To process both eyes, use 'both', which will work on 'pupil_r' and
%   │                 'pupil_l'.
%   │                 To process a specific eye, use 'pupil_l' or 'pupil_r'.
%   │                 To process the combined left and right eye, use 'pupil_c'.
%   │                 The identifier 'pupil' will use the first existing option out of the
%   │                 following:
%   │                   (1) L-R-combined pupil;
%   │                   (2) non-lateralised pupil;
%   │                   (3) best eye pupil;
%   │                   (4) any pupil channel. ;
%   │                 If there are multiple  channels of the specified type, only last
%   │                 one will be processed. You can also specify the number of a channel.
%   └.channel_action : ['add'/'replace', default as 'add']
%                     Defines whether the new channel should be added or the previous
%                     outputs of this function should be replaced.
% ● Outputs
%   * channel_index : index of channel containing the processed data
% ● History
%   Introduced in PsPM 3.1
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Updated in 2024 by Dominik R Bach (Uni Bonn)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = NaN;

narginchk(1, 3);
if numel(varargin) == 1 && ~ischar(varargin{1})
  area = varargin{1};
  if ~isnumeric(area)
    warning('ID:invalid_input', 'area is not numeric'); return;
  end
  mode = 'vector';
else
  fn = varargin{1};
  if nargin == 2
     options = varargin{2};
  else
      options = struct();
  end
  options = pspm_options(options, 'convert_area2diameter');
  if options.invalid
    return
  end
  if strcmpi(options.channel, 'both')
      channel = {'pupil_r', 'pupil_l'};
  else
      channel = {options.channel};
  end
  mode = 'file';
end
if strcmpi(mode, 'vector')
    outchannel = 2.*sqrt(area./pi);
    sts = 1;
elseif strcmpi(mode, 'file')
    % load the data once to avoid multiple i/o operations in case 'both' is
    % specified
    [sts, alldata.infos, alldata.data] = pspm_load_data(fn);
    if sts < 1, return; end
    diam = cell(numel(channel), 1);
    for i = 1:numel(channel)
        [sts, channeldata, infos, pos_of_channel(i)] = pspm_load_channel(alldata, channel{i}, 'pupil');
        if sts < 1, return; end
        % recursive call to avoid the formula being stated twice in the same function
        [sts, diam{i}.data] = pspm_convert_area2diameter(channeldata.data);
        if sts < 1, return; end
        diam{i}.header = channeldata.header;
        % replace metric values
        diam{i}.header.units = ...
            regexprep(channeldata.header.units, ...
            '(square)?(centi|milli|deci|c|m|d)?(m(et(er|re))?)(s?\^?2?)', ...
            '$2$3');
        % if not metric, replace area with diameter
        if strcmpi(diam{i}.header.units, 'area units')
            diam{i}.header.units = 'diameter units';
        end
    end
    [sts, infos] = pspm_write_channel(fn, diam, options.channel_action, struct('channel', pos_of_channel));
    outchannel = infos.channel;
end
