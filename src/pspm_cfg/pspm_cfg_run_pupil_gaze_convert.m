function [out] = pspm_cfg_run_pupil_gaze_convert(job)

% $Id$
% $Rev$

channel_action = job.channel_action;
fn = job.datafile{1};

options = struct('channel_action', channel_action);
if (isfield(job.conversion, 'degree2sps'))
  % do degree to sps conversion
  [sts, out] = pspm_convert_visangle2sps(fn, options);

elseif (isfield(job.conversion, 'distance2sps'))
  args = job.conversion.distance2sps;
  [sts, out] = pspm_pupil_gaze_distance2sps(fn, args.from, args.height, args.width, args.screen_distance, options);

elseif (isfield(job.conversion, 'distance2degree'))
  args = job.conversion.distance2degree;
  [ sts, out ] = pspm_pupil_gaze_distance2degree(fn, args.from, args.height, args.width, args.screen_distance, options);
end


out = 1;
