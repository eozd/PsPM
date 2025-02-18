function [sts, outdata] = pspm_interpolate(indata, varargin)
% ● Description
%   pspm_interpolate interpolates NaN values. It either acts on one 
%   selected channel of a PsPM file and writes the result to the same file, 
%   or on all channels in the file and writes a new file with the same name
%   as the old file, prepended with 'i'. For internal purposes, the function
%   can also act on data vectors and then gives an interpolated data vector
%   as output.
% ● Format
%   [sts, channel_index] = pspm_interpolate(filename, channel, options)
%   [sts, newfile] = pspm_interpolate(filename, channel, options)
%   [sts, outdata] = pspm_interpolate(numeric_array, options)
% ● Arguments
%   *      indata : [char/numeric] contains the data to be interpolated
%   *     channel : a single channel identifier accepted by pspm_load_channel
%                   (numeric or char), or 'all', which will work on all
%                   channels. If indata is a file name and channel is 'all'
%                   then the result is written to a new file called 'i'+<old filename>.
%   ┌─────options
%   ├─────.method : Defines the interpolation method, see interp1() for
%   │               possible interpolation methods. Default is 'linear'.
%   ├.extrapolate : [not recommended; 0 or 1] Determine extrapolation for 
%   │               query points out of the data range. Default is no extrapolation.
%   ├──.overwrite : Defines if existing datafiles should be overwritten. [logical] (0 or 1)
%   │               Define whether to overwrite existing output files or not.
%   │               Default value: do not overwrite. Only used if 'channel' is 'all'
%   └.channel_action :
%                   Defines whether the interpolated data should be added
%                   or the corresponding channel should be replaced.
%                   [optional; accept: 'add', 'replace'; default: 'add']
%                   Only used if 'channel' is not 'all'.
% ● Outputs
%   *     outdata : interpolated numeric array.
%   * channel_index : index of new channel if no new file is created
%   *     newfile : name of new file if channel == 'all'
% ● History
%   Introduced in PsPM 3.0
%   Written in 2015 by Tobias Moser (University of Zurich)
%   Maintained in 2022 by Teddy
%   Refactored in 2024 by Dominik Bach (Uni Bonn)

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
outdata = [];
sts = -1;

% 1.1 check input arguments
if nargin<1
  warning('ID:missing_data', 'Don''t know what to do.\n');
  return;
elseif isempty(indata)
  warning('ID:missing_data', 'Input data is empty, nothing to do.');
  return;
end

if isnumeric(indata)
    if nargin >= 2
        options = varargin{1};
    else
        options = struct();
    end
elseif nargin < 2
    warning('ID:invalid_input', 'Channel undefined - don''t know what to do.');
    return;
else
    channel = varargin{1};
    if nargin >= 3
        options = varargin{2};
    else
        options = struct();
    end
end

% 1.2 initialise options
options = pspm_options(options, 'interpolate');
if options.invalid
  return
end

% 1.3 determine the method
if isnumeric(indata)
    method = 1;
elseif ischar(indata) && strcmpi(channel, 'all')
    method = 2;
elseif ischar(indata)
    method = 3;
else
    warning('ID:invalid_input', 'Wrong input data format.');
    return
end

% 1.4 User output
if ischar(indata)
    fprintf('\nInterpolating %s, ', indata); % user output
else
    fprintf('\nInterpolating ... '); % user output
end

%% 2 work on data
% 2.1 load data
if method == 1
    data{1}.data = indata;
    method = 1;
elseif method == 2
    [lsts, infos, alldata] = pspm_load_data(indata);
    if lsts < 1, return; end
    [lsts, data, pos_of_channel] = pspm_select_channels(alldata, 'wave');
    if lsts < 1, return; end
    method = 2;
elseif method == 3
    [lsts, data, infos, pos_of_channel] = pspm_load_channel(indata, channel, 'wave');
    if lsts < 1, return; end
    data = {data};
end

% 2.2 work on all channels
for i_channel = 1:numel(data)
    v = data{i_channel}.data;
    if numel(find(~isnan(v))) < 2
      warning('ID:invalid_input',...
        'Need at least two sample points to run interpolation (Channel %i). Skipping.', i_channel);
    else
      x = 1:length(v);
      xq = find(isnan(v));
      if numel(xq) > 0
          % throw away data matching 'xq'
          x(xq) = [];
          v(xq) = [];
          % check for overlaps
          if numel(xq) < 1
            e_overlap = 0;
            s_overlap = 0;
          else
            e_overlap = max(xq) > max(x);
            s_overlap = min(xq) < min(x);
          end
          if s_overlap || e_overlap
            if ~options.extrapolate
              warning('ID:option_disabled', ...
                'NaN data at beginning or end of file will not be extrapolated.');
              xq(xq>max(x)) = [];
              xq(xq<min(x)) = [];
              vq = interp1(x, v, xq, options.method, 'extrap');
            elseif s_overlap && strcmpi(options.method, 'previous')
              warning('ID:out_of_range', ['Cannot extrapolate with ', ...
                'method ''previous'' and overlap at the beginning.']);
              return;
            elseif e_overlap && strcmpi(options.method, 'next')
              warning('ID:out_of_range', ['Cannot extrapolate with ', ...
                'method ''next'' and overlap at the end.']);
              return;
            else
              % extrapolate because of overlaps
              vq = interp1(x, v, xq, options.method, 'extrap');
            end
          else
              % no overlap
              vq = interp1(x, v, xq, options.method);
          end
          % update data depending on method
          if method == 2
              alldata{pos_of_channel(i_channel)}.data(xq) = vq;
          else
              data{i_channel}.data(xq) = vq;
          end
      end
    end
end

% 2.3 update history
if method > 1
    if method == 2
        channelstr = 'All channels';
    else
        channelstr = sprintf('Channel %i', pos_of_channel);
    end
    msg = [channelstr, ' on ', datestr(now, 'dd-mmm-yyyy HH:MM:SS')];
end

% 2.4 write and/or return data
if method == 1 % numeric indata
    outdata =  data{1}.data;
    sts = 1;
elseif method == 2 % write new file
    % save as a new file preprended with 'i'
    [pth, fn, ext] = fileparts(indata);
    newdatafile    = fullfile(pth, ['i', fn, ext]);
    if isfield(infos, 'history')
      nhist = numel(infos.history);
    else
      nhist = 0;
    end
    infos.history{nhist + 1} = msg;
    infos.interpolatefile = newdatafile;
    sts = pspm_load_data(newdatafile, ...
        struct('data', {alldata}, ...
               'infos', infos, ...
               'options', ...
                  struct('overwrite', pspm_overwrite(newdatafile, options))));
    if sts == 1
        outdata = newdatafile;
    end
elseif method == 3
    [sts, infos] = pspm_write_channel(indata, data, options.channel_action, ...
        struct('channel', pos_of_channel, ...
               'msg', msg));
    if sts == 1
        outdata = infos.channel;
    end
end

