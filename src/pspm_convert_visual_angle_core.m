function [lon, lat, lon_range, lat_range] = pspm_convert_visual_angle_core(x_data, y_data, width, height, distance)
% ● Description
%   pspm_convert_visual_angle_core computes from gaze data the corresponding
%   visual angle (for each data point). The convention used here is that the
%   origin of coordinate system for gaze data is at the bottom left corner of
%   the screen.
% ● Format
%   [lon, lat, lon_range, lat_range] = pspm_convert_visual_angle_core(x_data, y_data, width, height, distance)
% ● Arguments
%   *    x_data: X axis data
%   *    y_data: y axis data
%   *     width: screen width in same units as data
%   *    height: screen height in same units as data
%   *  distance: screen distance in same units as data
% ● Outputs
%   *       lat: the latitude in degrees (x-direction)
%   *       lon: the longitude in degrees (y-direction)
%   * lat_range: the latitude range
%   * lon_range: the longitude range
% ● History
%   Introduced in PsPM 4.0
%      Updated by Dominik R. Bach (Uni Bonn) in 2024

%% 1 Initialise
lat = 0; lon = 0; lat_range = 0; lon_range = 0;
% The convention is that the origin of the screen is in the bottom
% left corner, so the following line is not needed a priori, but I
% leave it anyway just in case :
% y_data = data{gy}.header.range(2)-y_data;
N = numel(x_data);
if N ~= numel(y_data)
  warning('ID:invalid_input', 'length of data in gaze_x and gaze_y is not the same');
  return;
end
%% 2 move (0,0) into center of the screen
x_data = x_data - width/2;
y_data = y_data - height/2;
%% 3 compute visual angle for gaze_x and gaze_y data:
% 1) x axis in cartesian coordinates
s_x = x_data;
% 2) y axis in cartesian coordinates, actually the distance from participant to the screen
s_y = distance * ones(numel(x_data),1);
% 3) z axis in spherical coordinates, actually the y axis of the screen
s_z = y_data;
% 4) convert cartesian to spherical coordinates in radians,
%    where azimuth = longitude, elevation = latitude
%    the center of spherical coordinates are the eyes of the subject
[azimuth, elevation, ~]= cart2sph(s_x,s_y,s_z);
% 5) convert radians into degrees
lat = rad2deg(elevation);
lon = rad2deg(azimuth);
%% 4 compute visual angle for the range (same procedure)
r_x = transpose([-width/2,width/2,0,0]);
r_y = distance * ones(numel(r_x),1);
r_z = [0,0,-height/2,height/2]';
[x_range_sp, y_range_sp,~]= cart2sph(r_x,r_y,r_z);
x_range_sp = rad2deg(x_range_sp);
y_range_sp = rad2deg(y_range_sp);
lon_range = [x_range_sp(1),x_range_sp(2)];
lat_range = [y_range_sp(3),y_range_sp(4)];
sts = 1;
return
