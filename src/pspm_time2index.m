function index = pspm_time2index(time, sr, varargin)
% ● Description
%   pspm_time2index converts time stamps and durations in seconds or markers
%   to a sample index.
% ● Format
%   index = pspm_time2index(time, sr [, data_length, is_duration, events])
% ● Developer
%   Optional arguments in []; all arguments up the last specified one need to be specified.
% ● Arguments
%   *        time : [vector or matrix] time stamps in second.
%              sr : [numeric] sampling rate or frequency
%   * data_length : [integer] the length of data, which the index should not exceed.
%   * is_duration : [0/1] whether an index or a duration is required, default as 0.
%   *      events : vector of timestamps from a marker channel, will be considered if
%                   given as input.
% ● Outputs
%           index : [integer] index or data point.
% ● History
%   Introduced in PsPM 5.1.2
%   Written in 2021 by Teddy
%   Refactored in 2024 by Dominik Bach (Uni Bonn)

if nargin < 3
    data_length = inf;
else
    data_length = varargin{1};
end

if nargin < 4
    is_duration = 0;
else
    is_duration = varargin{2};
end

if nargin > 4
    events = varargin{3};
    time = events(time);
end

% 'round' can sometimes result in non-integer values
index = double(int64(round(time * sr)));

% The first sample of the file corresponds to index 1 and time 0, i.e. we
% assume the first sample was recorded in the interval [0, dt[
if is_duration < 1
    index = index + 1;
end

flag = index > ones(size(index)) * data_length;
if any(flag(:) > 0)
    index(flag==1) = data_length;
end
