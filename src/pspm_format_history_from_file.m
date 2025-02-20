function [sts, hist_str] = pspm_format_history_from_file(fn)
% ● Description
%   pspm_format_history_from_file returns the infos.history field of the PsPM file
%   given in fn in a table-like formatted string. For further details, refer
%   to <a href="matlab:help pspm_format_history">pspm_format_history</a>.
% ● Format
%   [sts, hist_str] = pspm_format_history_from_file(fn)
% ● Arguments
%   * fn: [string] Path to a PsPM file
% ● Outputs
%   * hist_str: Formatted table string
% ● History
%   Written in 2019 by Eshref Yozdemir (UZH)

%% Initialise
sts = -1;
[sts_load_data, infos, ~, ~] = pspm_load_data(fn);
if ~sts_load_data
  return
end
[sts_format_history, hist_str] = pspm_format_history(infos.history);
if ~sts_format_history
  return
end
%% Return status
sts = 1;
return
