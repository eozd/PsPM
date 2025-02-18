function [out_data, out_range] = pspm_convert_pixel2unit_core(data, data_range, screen_length)
% ● Description
%   pspm_convert_pixel2unit_core converts gaze data from pixel to units.
% ● Format
%   [out_data, out_range] = pspm_convert_pixel2unit_core(data, data_range, screen_length)
% ● Arguments
%   *          data: Original data in pixels. No checks are performed.
%   *    data_range: Original range in pixels.
%   * screen_length: Screen width for gaze_x data, or screen height for gaze_y data, in mm
% ● History
%   Introduced in PsPM 4.0
%   Written in 2016 by Tobias Moser (University of Zurich)
%   Refactored in 2024 by Dominik Bach (Uni Bonn)

% length per pixel along width or height
length_per_pixel = screen_length ./ (diff(data_range) + 1);
% baseline data in pixels wrt. the range (i.e. pixels of interest)
pixel_index = data-data_range(1);
% convert indices into coordinates in the units of interests
out_data = pixel_index * length_per_pixel ;
% same procedure for the range (baseline + conversion)
out_range = (data_range-data_range(1)) * length_per_pixel ;

