function [sts, pupil_corrected] = pspm_pupil_correct(pupil, gaze_x_mm, gaze_y_mm, geometry_setup)
% ● Description
%   pspm_pupil_correct performs pupil foreshortening error (PFE) correction for arbitrary
%   eye tracker measurements according to equations (3) and (4) in [1].
% ● Format
%   [sts, pupil_corrected] = pspm_pupil_correct(pupil, gaze_x_mm, gaze_y_mm, geometry_setup)
% ● Arguments
%   *        pupil: Numeric array containing pupil diameter. (Unit: any unit)
%   *    gaze_x_mm: Numeric array containing gaze x positions. (Unit: mm)
%   *    gaze_y_mm: Numeric array containing gaze y positions. (Unit: mm)
%   ┌─geometry_setup
%   ├─────────.C_x: Horizontal displacement of the center of camera lens,
%   │               i.e. how much to the left or to the right the camera
%   │               looks for a sitting person whose pupil is at O. (Unit: mm)
%   ├─────────.C_y: Vertical displacement of the center of camera lens,
%   │               i.e. how much to the top or to the bottom the camera
%   │               looks for a sitting person whose pupil is at O. (Unit: mm)
%   ├─────────.C_z: The distance between pupil center and camera center if
%   │               they have same x and y coordinates. (Unit: mm)
%   ├─────────.S_x: Horizontal displacement of the top left corner of screen
%   │               i.e. how much to the left or to the right the top left
%   │               corner of screen looks for a sitting person whose
%   │               pupil is at O. (Unit: mm)
%   ├─────────.S_y: Vertical displacement of the top left corner of screen
%   │               i.e. how much to the top or to the bottom the top left
%   │               corner of screen looks for a sitting person whose pupil
%   │               is at O. (Unit: mm)
%   └─────────.S_z: The distance between pupil center and top left corner of
%                   screen if they have same x and y coordinates. (Unit: mm)
% ● Outputs
%   * pupil_corrected: PFE corrected pupil data. (Unit: unit of the input pupil data)
% ● Developer
%   geometry_setup is a struct with the geometry setup fields. When defining these
%   coordinate system parameters, we assume that the origin O of the 3D coordinate system
%   is the center of the pupil.
%   In particular,
%   1. Target points (T_x, T_y, T_z) are calculated using gaze x and y
%      positions at each timestep
%   2. Cosine of the oblique angle is computed using the dot products of
%      unitary vectors corresponding to camera C and target T.
%   3. Diameter values are scaled using 1/sqrt(cos). Hence, the corrected pupil
%      values are at least as big as the input pupil values.
% ● References
%   [1] Hayes, Taylor R., and Alexander A. Petrov. "Mapping and correcting the
%       influence of gaze position on pupil size measurements." Behavior
%       Research Methods 48.2 (2016): 510-527.
% ● History
%   Introduced in PsPM version?.
%   Written in 2019 by Eshref Yozdemir (University of Zurich)
%   Maintained in 2022 by Teddy

% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

% input checks
% -------------------------------------------------------------------------
if ~isnumeric(pupil) || ~isnumeric(gaze_x_mm) || ~isnumeric(gaze_y_mm)
  warning('ID:invalid_input', 'All of pupil, gaze_x_mm, gaze_y_mm must be numeric');
  return;
end
same_sizes = all(size(pupil) == size(gaze_x_mm)) && all(size(gaze_x_mm) == size(gaze_y_mm));
if ~same_sizes
  warning('ID:invalid_input', 'All input arrays must have the same sizes');
  return;
end
if ~any(ismember(size(pupil), 1)) || ~any(ismember(size(gaze_x_mm), 1)) || ~any(ismember(size(gaze_y_mm), 1))
  warning('ID:invalid_input', 'All input arrays must be 1D');
  return;
end
all_fieldnames = {'C_x', 'C_y', 'C_z', 'S_x', 'S_y', 'S_z'};
names_concat = sprintf('%s, ', all_fieldnames{:});
if ~all(isfield(geometry_setup, all_fieldnames))
  warning('ID:invalid_input', sprintf('geometry_setup must contain all of %s', names_concat));
  return;
else
  all_input_params = cellfun(@(key) geometry_setup.(key), all_fieldnames, 'UniformOutput', false);
  if ~all(cellfun(@isnumeric, all_input_params))
    warning('ID:invalid_input', sprintf('All of %s in geometry_setup must be numeric', names_concat));
    return;
  end
end

% correction
% -------------------------------------------------------------------------
is_rowvec = size(pupil, 1) == 1;
if is_rowvec
  pupil = transpose(pupil);
  gaze_x_mm = transpose(gaze_x_mm);
  gaze_y_mm = transpose(gaze_y_mm);
end

T = [geometry_setup.S_x + gaze_x_mm, ...
  geometry_setup.S_y - gaze_y_mm, ...
  repmat(geometry_setup.S_z, size(gaze_x_mm, 1), 1)];
c = [geometry_setup.C_x; geometry_setup.C_y; geometry_setup.C_z];

c = c ./ norm(c, 2);
T = bsxfun(@rdivide, T, vecnorm(T, 2, 2));

cosine = T*c;
pupil_corrected = pupil ./ sqrt(cosine);

if is_rowvec
  pupil_corrected = transpose(pupil_corrected);
end

sts = 1;
return
